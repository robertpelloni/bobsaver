#version 420

// original https://www.shadertoy.com/view/MdcyD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 mul (vec3 a, vec3 b) {
    return vec3(a.x*b.x-a.y*b.y, a.y*b.x+a.x*b.y, a.z*b.z);
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x = uv.x*4.-2.;
    uv.y = uv.y*4.-1.5;
    uv.x *= resolution.x/resolution.y;
    vec3 c = vec3(0);
    vec3 v = uv.xyx;
    vec3 f = vec3(0.5*cos(0.5*time));
    float g = 1.;
    vec3 w = vec3(1,1,2);// this just seemed to work - would like to know why
    for (int i = 0; i < 100; i++) {
        f =  mul(mul(v,f),f-w);
        c += exp(-10000.*(v.y-f.z)*(v.y-f.z));
        if (dot(f.xy,f.xy) > 100.) g = 0.;
    }
    if (g>0.)c=1.-c;
    glFragColor = vec4(((c+g)*2.-1.)*sin(time)*0.5+0.5,1.0);
}
