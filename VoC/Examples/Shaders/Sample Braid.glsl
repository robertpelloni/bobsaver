#version 420

// original https://www.shadertoy.com/view/Wds3zf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi acos(-1.)
#define tau (2.*pi)

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x*c - a.y*s,
        a.x*s + a.y*c
    );
}

float sdbox2d(vec2 p, float r)
{
    p=abs(p);
    return max(p.x,p.y)-r;
}

vec2 boffset(vec2 p, float t)
{
    t*=pi*2.;
    return rotate(p+vec2(
        cos(t)*2.,
        -sin(t*3.)
    )*.15, sin(t)*(pi*2./3.));
}

float tick(float t)
{
    t = smoothstep(0.,1.,t);
    t = smoothstep(0.,1.,t);
    t = smoothstep(0.,1.,t);
    t = smoothstep(0.,1.,t);
    return t;
}

float pattern(float t)
{
    t=fract(t);
    return clamp(abs(t-.5)*-16.+7.5,-1.,1.)+1.;
    return tick(abs(t-.5)*2.);
}

float scene2(vec2 p, float angle)
{
    float time = ((angle/tau)/5.)*4.+time*.25;

    float q = time+angle;

    float r = .02 + pattern((angle/tau)*30.)*.02;

    float a = sdbox2d(boffset(p,time),r);
    float b = sdbox2d(boffset(p,time+1./5.),r);
    float c = sdbox2d(boffset(p,time+2./5.),r);
    float d = sdbox2d(boffset(p,time+3./5.),r);
    float e = sdbox2d(boffset(p,time+4./5.),r);
    return min(min(min(a,b),min(c,d)),e);
}

float scene(vec3 p)
{
    p.xz = mod(p.xz+8.,16.)-8.;

    float angle = atan(p.x,p.z);

    float q = .75;

    p.y += (angle/tau)*(q+q);

    p.y = mod(p.y+q,(q+q))-q;

    vec2 a = vec2(length(p.xz)-1., p.y);

    return scene2(a, angle);
}

void main(void)
{
    vec4 out_color = vec4(0.0);
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;

    uv.x *= resolution.x/resolution.y;

    uv *= 1.+length(uv)*.3;

    vec3 cam = vec3(0,0,-5);
    vec3 dir = normalize(vec3(uv, 2.5));

    cam.yz = rotate(cam.yz, pi/5.);
    dir.yz = rotate(dir.yz, pi/5.);

    cam.xz = rotate(cam.xz, pi/4.);
    dir.xz = rotate(dir.xz, pi/4.);

    cam.y += time;

    float t =0.;
    float k = 0.;
    int iter=0;
    for(int i=0;i<100;++i)
    {
        k = scene(cam+dir*t)*.7;
        t+=k;
        iter=i;
        if (k < .001)break;
    }
    vec3 h = cam+dir*t;
    vec2 o = vec2(.002,0);
    vec3 n = normalize(vec3(
        scene(h+o.xyy)-scene(h-o.xyy),
        scene(h+o.yxy)-scene(h-o.yxy),
        scene(h+o.yyx)-scene(h-o.yyx)
    ));

    if (k < .001)
    {
        float iterFog = 1.-float(iter)/100.;
        iterFog = pow(iterFog, 3.);
        float light = max(n.y,0.);
        out_color.rgb += mix(vec3(.01,.01,.1), vec3(.1,.5,.5), iterFog);
        out_color.rgb += mix(vec3(0.), vec3(sin(time),sin(time+2.),sin(time+4.))+1., light*iterFog);
    }
    else
    {
        out_color *= 0.;
    }

    out_color.rgb = mix(out_color.rgb, vec3(out_color.r+out_color.g+out_color.b)/3., .5);

    glFragColor = out_color;
}
