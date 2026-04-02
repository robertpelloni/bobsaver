#version 420

// original https://www.shadertoy.com/view/NtGSRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "happy bouncing v4"
// shader about boucing animation, space transformation, easing functions,
// funny shape and colorful vibes.
// by leon denise (2021-12-22)
// licensed under hippie love conspiracy

// using Inigo Quilez works:
// arc sdf from https://www.shadertoy.com/view/wl23RK
// color palette https://iquilezles.org/www/articles/palettes/palettes.htm

#define fill(sdf) (smoothstep(.001, 0., sdf))
#define repeat(p,r) (mod(p,r)-r/2.)
#define ss(a,b,t) (smoothstep(a,b,t))
#define clp(t) (clamp(t,0.,1.))

// add shape to layer
void add (in float sdf, in vec3 col, inout float sdfLayers, inout vec3 colLayers)
{
    colLayers = mix(colLayers, col, fill(sdf));
    sdfLayers = min(sdf, sdfLayers);
}

// add shape to frame
void add(in vec4 shape, inout vec4 frame)
{
    if (shape.a < 0.) frame.rgb = shape.rgb;
}

// soft drop shadow from shape 
float shadow (float sdf)
{
    return clamp(sdf+.9,0.,1.);
}

// Inigo Quilez
// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdArc( in vec2 p, in float ta, in float tb, in float ra, float rb )
{
    p.y -= ra; // offset y
    vec2 sca = vec2(sin(ta),cos(ta));
    vec2 scb = vec2(sin(tb),cos(tb));
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p,scb) : length(p);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
    
// snippets
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
float circle (vec2 p, float size)
{
    return length(p)-size;
}

float globalSpeed = 0.5;
const float pi = 3.1415;

vec2 animation(vec2 p, float t)
{
    float ta = fract(t)*6.283;
    float tt = t;
    
    p.y -= 0.15; // sidebar
    p *= rot(sin(ta)*.2*ss(.0,.5,p.y+.2)); // swing
    
    return p;
}

vec4 buddy (vec2 pp, vec3 tint, float t, float ii)
{
    // result
    float scene = 100.;
    vec3 col = vec3(0);
    
    // variables
    vec2 p, q;
    float shape, zhape;
    float ta = t*6.283;
    float bodySize = 0.25;
    float turn = sin(t*6.283*.5-.5)*2.;
    
    // body
    p = animation(pp, t);
    float body = circle(p, bodySize);

    p = animation(pp, t-.01)+vec2(0.,-1.)*bodySize;
    p.x = abs(p.x)-0.1;
    zhape = circle(p*vec2(.7,.4), 0.02);
    body = smin(body, zhape, .04);
    
    // mouth
    p = animation(pp, t + .02)+vec2(-.2*turn,.5)*bodySize;
    q = p;
    shape = smin(body, circle(p, 0.1), 0.2);
    add(shape, tint, scene, col);
    col *= clp(zhape*10.+.5)*-.2+1.;
    p *= 1.5;
    p.x = abs(p.x)-0.05;
    shape = sdArc(p+vec2(0,.1), pi/-3., 2., .05, .02);
    add(shape, tint*.6, scene, col);
    
    // nose
    shape = circle(q-vec2(0,.02), .04);
    add(shape, tint*.5, scene, col);
    col *= shadow(shape);

    // eyes
    shape = 100.;
    p = animation(pp, t+.02);
    p = p - vec2(.2*turn, .6)*bodySize;
    p.x = abs(p.x)-0.04;
    add(circle(p, 0.04), vec3(1)*ss(-.2,0.2,p.y+.1), shape, col);
    add(circle(p+vec2(.01), 0.02), vec3(0), shape, col);
    col *= shadow(shape);
    scene = min(scene, shape);
    
    return vec4(col, scene);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec4 color = vec4(.25)*step(uv.y,0.1); // sidebar
    
    vec4 shape;
    vec2 pos = (gl_FragCoord.xy-vec2(0.5,0)*resolution.xy)/resolution.y;
    vec2 p, pp;
    
    // rolling buddy
    p = pos;
    p.y -= 0.1;
    p.x -= fract(time*globalSpeed*.5+.61)*2.-1.;
    p *= rot(pos.x*20.);
    shape = vec4(vec3(0.976,0.976,0.424)*ss(.1,.0,length(p)), circle(p,.04));
    add(shape, color);
    p.y += 0.02;
    add(vec4(vec3(0), sdArc(p, pi/-2., 1., 0.02, .005)), color);
    p.x = abs(p.x)-0.01;
    p.y -= 0.03;
    add(vec4(vec3(0), circle(p, 0.006)), color);
    color.rgb *= shadow(shape.a);
    
    // bouncing buddies
    const float instances = 5.;
    for (float i = 0.; i < instances; ++i)
    {
        float ii = i/(instances);
        float iy = i/(instances-1.);
        float t = (time*globalSpeed + iy);
        
        // distribute instances
        p = pos;
        p.x += (iy*2.-1.)*.6;
        p.y -= .15;
        
        // scale
        p *= 2.;
        
        // jump animation
        float ta = fract(t)*6.283;
        float tt = sin(clp(fract(t*.5)*3.)*3.14);
        p += vec2(0.,-abs(sin(ta))*2.)*tt*.3; // looping
        p.y *= 1.+.1*sin(ta*4.)*tt; // stretch
        
        float dist = length(animation(p,t));
        
        // color palette by Inigo Quilez
        vec3 tint = .5+.5*cos(vec3(0.,.3,.6)*6.28 + i*5. + dist*-2.);
        
        // glow
        color.rgb += tint * clp(-dist+.4)*2.;
        
        // add shape to frame
        add(buddy(p, tint, t, ii), color);
    }
	glFragColor=color;
}
