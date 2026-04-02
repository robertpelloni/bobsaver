#version 420

// original https://www.shadertoy.com/view/NtyXz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "happy bouncing variation 2" by leon. https://shadertoy.com/view/NlGXR1
// 2021-12-22 01:53:45

// Fork of "happy bouncing variation 1" by leon. https://shadertoy.com/view/ftGXR1
// 2021-12-22 00:28:04

// Fork of "happy bouncing" by leon. https://shadertoy.com/view/flyXRh
// 2021-12-22 00:11:16

// "happy bouncing"
// shader about boucing animation, space transformation, easing functions,
// funny shape and colorful vibes.
// by leon denise (2021-12-21)
// licensed under hippie love conspiracy

// using Inigo Quilez works:
// arc sdf from https://www.shadertoy.com/view/wl23RK
// color palette https://iquilezles.org/www/articles/palettes/palettes.htm

// Inigo Quilez
// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdArc( in vec2 p, in float ta, in float tb, in float ra, float rb )
{
    vec2 sca = vec2(sin(ta),cos(ta));
    vec2 scb = vec2(sin(tb),cos(tb));
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p,scb) : length(p);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

// snippets
#define fill(sdf) (smoothstep(.001, 0., sdf))
#define repeat(p,r) (mod(p,r)-r/2.)
#define ss(a,b,t) (smoothstep(a,b,t))
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
float circle (vec2 p, float size)
{
    return length(p)-size;
}
float wrap (float v)
{
    return sin(v*6.283)*.5+.5;
}

// Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

// global variable
float bodySize = 0.3;

// shape eyes
vec2 size = vec2(.08, .09);
float divergence = 0.08;

// easing curves are below
float jump(float);
float walk(float);
float stretch(float);
float bounce(float);
float swing(float);

float ao(float);

// list of transformation (fun to tweak)
vec2 animation(vec2 p, float t)
{
    t = fract(t);
    
    p.y -= bodySize;
    p.y -= 0.1;
    
    float j = jump(t);
    p.y -= j*.1;
    p.x *= stretch(t)*.1+1.;
    p *= rot(sin(p.y+t*6.283)*.5);
    float b = bounce(t)*.2;
    p.y *= b+1.;
    p.y += b*bodySize;
    //p.x += walk(t)*0.2;
    //p *= 1.5-j*.9;
    
    return p;
}

vec4 sdEyes (vec2 p, float t, vec3 tint, float sens)
{
    vec3 col = vec3(0);
    float shape = 100.;
    
    // eyes positions
    p = animation(p, t);
    p *= rot(swing(t)*-.1);
    p -= vec2(.03, bodySize);
    p.x -= divergence*sens;

    // globe shape
    float eyes = circle(p, size.x);
    //col = mix(col, tint, fill(eyes));
    //shape = min(shape, eyes);

    // white eye shape
    eyes = circle(p, size.y);
    col = mix(col, vec3(1)*ss(-.2,0.2,p.y+.1), fill(eyes));
    shape = min(shape, eyes);

    // black dot shape
    eyes = circle(p, 0.02);
    col = mix(col, vec3(0), fill(eyes));
    shape = min(shape, eyes);
    
    return vec4(col, shape);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec4 color = vec4(0,0,0,1);
    
    // ground
    color.rgb += vec3(.25)*step(uv.y,0.1);
    
    // number of friends
    const float buddies = 5.;
    for (float i = 0.; i < buddies; ++i)
    {
        // usefull to dissociate instances
        float ii = i/(buddies);
        float iy = i/(buddies-1.);
        
        // translate
        float iii = 1.-ii;
        
        // translate instances
        vec2 pp = (gl_FragCoord.xy-vec2(0.5,0)*resolution.xy)/resolution.y;
        pp.x += (iy*2.-1.)*.5;
        pp *= 2.;
        
        // time
        float t = fract(time*.5 + ii);
        
        // there will be sdf shapes
        float shape = 1000.;
        vec2 p;
        
        // there will be layers
        vec3 col = vec3(0);
        
        // color palette
        // Inigo Quilez (https://iquilezles.org/www/articles/palettes/palettes.htm)
        vec3 tint = .5+.5*cos(vec3(0.,.3,.6)*6.28+i-length(animation(pp-vec2(0,.1),t))*3.);
        
        // body shape
        p = animation(pp, t);
        float body = circle(p, bodySize);
        col += tint*fill(body);
        shape = min(shape, body);
        
        vec4 eyes = sdEyes(pp, t-.01, tint, -1.);
        col = mix(col*ao(eyes.a), eyes.rgb, step(eyes.a,0.));
        shape = min(shape, eyes.a);
        eyes = sdEyes(pp, t+.01, tint, 1.);
        col = mix(col*ao(eyes.a), eyes.rgb, step(eyes.a,0.));
        shape = min(shape, eyes.a);
        
        
        // smile animation
        float anim = sin(t*6.28)*.5+.5;
        float thin = mix(0.01, 0.05, anim);
        float lips = mix(0.1, 0.1, anim);
        float smile = mix(.1, .6, anim);
        float radius = mix(0.5, 0.5, anim);
        
        // smile position
        p = animation(pp, t+0.01);
        p -= bodySize*vec2(.1, radius*2.+radius*anim+.5*anim);
        vec2 q = p;
        
        // arc
        float d = sdArc(p,-3.14/2., smile, radius, thin);
        
        float dm = d-lips;
        shape = min(shape, dm);
        col = mix(col*ao(dm), tint, fill(dm));
        
        // black line
        col = mix(col*ao(d), tint*.6, fill(d));
        
        // add buddy to frame
        color.rgb = mix(color.rgb * ao(shape), col, step(shape, 0.));
    }
	glFragColor=color;
}

float ao (float sd)
{
    return clamp(sd+.85,0.,1.);
}

// easing curves (not easy to tweak)
// affect timing of transformations;

float jump (float t)
{
    t = min(1., t*3.);
    t = abs(sin(t*3.1415));
    return pow(t, .8);
}

float walk (float t)
{
    t = mix(pow(t,2.), pow(t, 0.5), t);
    return (cos(t*3.1415*2.));
}

float swing (float t)
{
    //t = pow(t, .5);
    //t = t*2.;
    //t = pow(t, .5);
    t = sin(t*3.14*2.);
    return t;
}

float stretch (float t)
{
    float tt = sin(t*6.283*2.);
    return tt;
}

float bounce (float t)
{
    float tt = cos(t*6.283*2.);
    return tt;
}
