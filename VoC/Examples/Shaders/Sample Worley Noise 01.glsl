#version 420

// original https://www.shadertoy.com/view/tlf3zn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//2D hash function:
vec2 hash2(vec2 p)
{
     return fract(cos(p*mat2(56.,37.,81.,-26.))*28.9);   
}
//Simple Worley noise function:
float worley(vec2 p)
{
    vec3 s = vec3(-1,0,1);
     vec2 f = floor(p);
    
    vec2 v = hash2(f+s.xx)-p+f+s.xx;
    float d = dot(v,v);
    v = hash2(f+s.yx)-p+f+s.yx;
    d = min(d,dot(v,v));
    v = hash2(f+s.zx)-p+f+s.zx;
    d = min(d,dot(v,v));
    
    v = hash2(f+s.xy)-p+f+s.xy;
    d = min(d,dot(v,v));
    v = hash2(f+s.yy)-p+f+s.yy;
    d = min(d,dot(v,v));
    v = hash2(f+s.zy)-p+f+s.zy;
    d = min(d,dot(v,v));

    v = hash2(f+s.xz)-p+f+s.xz;
    d = min(d,dot(v,v));
    v = hash2(f+s.yz)-p+f+s.yz;
    d = min(d,dot(v,v));
    v = hash2(f+s.zz)-p+f+s.zz;
    d = min(d,dot(v,v));
    return sqrt(d);
}

void main(void)
{
    float noise = worley(gl_FragCoord.xy/64.+time);
    glFragColor = vec4(noise,noise,noise,1.);
}
