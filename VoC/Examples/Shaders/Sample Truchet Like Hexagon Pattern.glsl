#version 420

// original https://www.shadertoy.com/view/tsV3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415927
vec2 s = vec2(1,1.73);

vec2 rot(vec2 a, float t)
{
    float s = sin(t);
    float c = cos(t);
    return vec2(a.x*c-a.y*s,
                a.x*s+a.y*c);
}

//thanks to BigWIngs/The Art Of Code's videos on hex tiling and truchet patterns
float hex(in vec2 p)
{
    p=abs(p);
    return max(dot(p,normalize(s)),p.x);
}

vec4 hexCoords(vec2 p)
{
    vec2 hs = s*.5,
         c1 = mod(p,s)-hs,
         c2 = mod(p-hs,s)-hs;
    vec2 hc= dot(c1, c1)<dot(c2,c2)?c1:c2;
    return vec4(hc, p-hc);
    
}

float li(float px, float lt, float d, vec2 hc)
{
    return smoothstep(0.,px,length(hc.x+d)-lt);
}

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    vec2 p = ((2.*f-resolution.xy)/resolution.y)*4.+vec2(0,time);
    vec4 hc = hexCoords(p+10.);
    float id = hc.z*hc.w*2.1238712;
    if(mod(id,3.)<=1.)hc.xy=rot(hc.xy,PI/3.);
    else if(mod(id,4.)<=2.)hc.xy=rot(hc.xy,-PI/3.);
    float px = 18./resolution.y, d = 0.25, lt = .075, 
        t =li(px,lt,d, hc.xy)*li(px,lt,-d, hc.xy);

    glFragColor.rgb=vec3(1.-t);
}
