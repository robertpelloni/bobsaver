#version 420

// original https://www.shadertoy.com/view/Xls3Rl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float x = uv.x*2.0;
    float y = uv.y;
    float n = time*4.0;
    float bom = (x*32.0+atan(y*8.0-4.+sin(n/4.0+sin(x*2.0+sin(y*2.0)))*4.)*32.0+n);
    float abe = cos((bom)/4.);
    float clo = clamp(abe,0.,1.);
    float cla = clamp(-abe,0.,1.);
    glFragColor = vec4(-clo*0.75+abs(sin(x-n/3.))*cla*0.7,sin(x+n/4.)*cla,abs(abe),1.0);
}
