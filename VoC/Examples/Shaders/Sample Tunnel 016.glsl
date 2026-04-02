#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi= 3.14159265359;
const float spinspeed=0.2;
const float movespeed=-1.;
const float spirals=3.;
const float twist = 3.3;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-mouse*resolution)/resolution.y;
    
    float l = length(uv);
    float pos = atan(uv.x, uv.y) + fract(time * spinspeed) * pi;
    float distortion = time*movespeed + twist / sqrt(l);
    vec2 s = 2.0*abs(fract(vec2(pos + distortion, 2.0*(pos - distortion))/pi*spirals) - vec2(0.5));
    float d = dot(s,s);
    float f = smoothstep(0.0, 0.1, 1.0-d);
    vec3 color = vec3(f*l);
    
    glFragColor = vec4(color, 1.0);
}
