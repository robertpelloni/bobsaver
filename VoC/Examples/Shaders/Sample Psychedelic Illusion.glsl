#version 420

//original https://www.shadertoy.com/view/MsBGRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec2 p)
{
    //return sin(atan(p.y, p.x)*5.0+length(p)*8.0);
    //return sin(atan(p.y, p.x)*8.0)-sin(length(p)*8.0);
    //return sin(p.x*8.0)*cos(p.y*8.0);
    return sin(atan(p.y, p.x)+length(p)*8.0);
}

float aaline(float x)
{
    return smoothstep(0.0, 0.1, x) * smoothstep(0.5, 0.6, 1.0-x);
}

void main(void)
{
    vec2 uv = -1.0 + 2.0*gl_FragCoord.xy / resolution.xy;
    uv.x *= resolution.x / resolution.y;
    float f = map(uv);
    float v = 0.0;
    v += aaline(mod(atan(uv.y, uv.x)/6.28+length(uv)+time*0.3*sign(f), 0.05)*20.0);
    v *= smoothstep(0.0, 0.1, abs(f));
    glFragColor = vec4(v);
}
