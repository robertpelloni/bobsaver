#version 420

// original https://www.shadertoy.com/view/3sBSWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
This shader was created live on stream!
You can watch the VOD here: https://www.twitch.tv/videos/402155037

I use the Bonzomatic tool by Gargaj/Conspiracy:
https://github.com/Gargaj/Bonzomatic

Wednesdays around 9pm UK time I stream at https://twitch.tv/lunasorcery
Come and watch a show!

~yx
*/

float tick(float t)
{
    float a=floor(t);
    t=fract(t);
    t=smoothstep(0.,1.,t);
    t=smoothstep(0.,1.,t);
    t=smoothstep(0.,1.,t);
    t=smoothstep(0.,1.,t);
    t=smoothstep(0.,1.,t);
    return a+t;
}

vec2 rotate(vec2 a, float b)
{
    float c=cos(b);
    float s=sin(b);
    return vec2(
        a.x*c-a.y*s,
        a.x*s+a.y*c
    );
}

float sdBall(vec3 p, float b)
{
    return length(p)-b;
}

float shape(vec3 p)
{    
    float planet = abs(length(p)-2.5)-.5;
    planet = max(planet, 2.7-length(p-vec3(0,1,-2)));
    
    return planet;
}

float ripple(vec3 p)
{
    float d = length(p)-1.5;
    
    float r = sin(p.y*.5+time*.5+sin(p.x*4.)*.1+sin(p.z*4.)*.1)*.2+.15;
    p.xz = rotate(p.xz, sin(time*.5));
    p.zy = rotate(p.zy, cos(time));
    p.xz = rotate(p.xz, p.y*sin(time)*.5);
    d = max(d, sdBall(mod(p,.6)-.3,r*2.));
    
    return d;
}

float mat=0.;

float scene(vec3 p)
{
    p.x += tick(time*.2)*8.;
    
    vec2 cellsize = vec2(8,16);
    
    vec2 cell = floor(p.xz/cellsize+.5);

    p.xz = mod(p.xz+cellsize*.5,cellsize)-cellsize*.5;
    
    float d = shape(p);
    float e = floor(d/.25);
    d = max(d, abs(mod(d,.25)-.125)-.02);
    d = max(d, abs(mod(p.y+tick(time*.5+cell.x*.5+cell.y*.25)*2.+.5,1.)-.5)-.25);
    
    float center = ripple(p);
    
    float best=min(d,center);
    
    if(d==best)
        mat=1.;
    else
        mat=.25;
    
    return best;
}

vec3 rainbow(float a)
{
    return sin(a+vec3(0,2,4))*.5+.5;
}

vec3 trace(vec3 cam, vec3 dir)
{
    vec3 accum=vec3(1);
    vec3 emit=vec3(0);
    float totaldist=0.;
    vec3 fogsky = rainbow(dir.y+time);
    for(int bounce=0;bounce<3;++bounce){
        float t = 0.;
        float k = 0.;
        for(int i=0;i<150;++i){
            k=scene(cam+dir*t)*.7;
            t+=k;
            if(abs(k)<.001)
                break;
        }
        totaldist+=t;
        
        vec3 sky = rainbow(dir.y+time);
        float fogstrength = clamp(1.-pow(.95,totaldist-25.),0.,1.);
        if (abs(k)>=.001) {
            return mix(accum*sky+emit,fogsky,fogstrength);
        }
        vec3 h=cam+dir*t;
        vec2 o = vec2(.001,0);
        vec3 n=normalize(vec3(
            scene(h+o.xyy)-scene(h-o.xyy),
            scene(h+o.yxy)-scene(h-o.yxy),
            scene(h+o.yyx)-scene(h-o.yyx)
        ));
        
        vec3 color = accum*(n.y*.5+.5)*rainbow(h.y*mat+time*4.);
        return mix(color,fogsky,fogstrength);
    }
    return fogsky*accum;
}

void main(void)
{
    vec4 out_color = glFragColor;

    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    vec3 cam = vec3(0,0,-20);
    vec3 dir = normalize(vec3(uv,2));
    
    cam.yz = rotate(cam.yz, .25);
    dir.yz = rotate(dir.yz, .25);
    
    cam.xz = rotate(cam.xz, .2);
    dir.xz = rotate(dir.xz, .2);
    
    out_color.rgb = trace(cam,dir);
    out_color.rgb = pow(out_color.rgb, vec3(.45));
    out_color.rgb += dot(uv,uv)*.3;

    glFragColor = out_color;
}
