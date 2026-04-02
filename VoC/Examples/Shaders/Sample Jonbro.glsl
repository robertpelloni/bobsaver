#version 420

// original https://www.shadertoy.com/view/lsGSDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
float sinNorm(float val)
{
    return (sin(val)+1.0)*0.5;
}
float str(float ratio, float toff)
{
    return sinNorm((toff)*PI*ratio);
}
float moire(vec2 uv, float phase)
{    
    float toff = phase;
    vec2 center = vec2(str(1.0, toff)*0.3, str(1.3, toff)*0.15)+vec2(0.5, 0.5);
    vec2 center2 = vec2(str(0.2, toff)*0.13, str(0.1, toff)*0.3)-vec2(0.5, 0.5);
    vec2 center3 = vec2(str(2.0, toff)*0.2, str(1.0, toff)*0.25)+vec2(0.5, 0.5);
    vec2 center4 = vec2(str(1.0, toff)*1.3, str(0.2, toff))-vec2(0.5, 0.5);
    float c = sinNorm((length(uv-center)+1.5*sinNorm(length(uv-center2)))*250.0);
    float c2 = sinNorm((length(uv-center3)+sinNorm(length(uv-center4)))*250.0);
    float cavg = (c+c2)*0.5;
    c = 1.0-smoothstep(ceil(min(c, c2)-0.5),1.0-cavg,0.5);//, 0.01);
    return c;
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float p1 = mod((time+0.0)*0.25, 1.0);
    float c = moire(uv, p1*0.25)*sin(p1*PI);

    p1 = mod((time+0.25)*0.25, 1.0);
    c = max(c, moire(uv, p1*0.25)*sin(p1*PI));

    p1 = mod((time+1.0)*0.25, 1.0);
    c = max(c, moire(uv, p1*0.25)*sin(p1*PI));
    p1 = mod((time+2.0)*0.25, 1.0);
    c = max(c, moire(uv, p1*0.25)*sin(p1*PI));
    glFragColor = vec4(c,c,c,1.0);
}
