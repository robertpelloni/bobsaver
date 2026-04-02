#version 420

// original https://www.shadertoy.com/view/llXGzB

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

//Neon Light Illusion by nimitz (twitter: @stormoid)

void main(){
    vec4 o = gl_FragCoord/resolution.xyxx-.5, d=o, r, z=d-d;
    float t = time, c;
    o.z += t;
    for(int i=0;i<99;i++)
        c= dot( (r = cos(o + o.w*sin(t*.9)*.15)).xyz, r.xyz),
        o -= d* dot( (r = cos(r/c*7.)).zy, r.zy ) *c*.2,
        z += abs(sin(vec4(9,0,1,1)+(o.y + t + o.w)))*.12*c/(o.w*o.w+ 6.5);
    glFragColor = z*z*z;
}
