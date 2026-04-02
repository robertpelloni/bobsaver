#version 420

// original https://www.shadertoy.com/view/4sVfWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926535897932384626433832795;
void main(void) {
    vec2 f = gl_FragCoord.xy;
    vec2 uv = f/resolution.y - 0.5;  
    float t = 999.999 + time * 10.0;
    float d = length(uv*1.5);
     uv = tan(10.5+uv*5.0);
    float  angle = atan(uv.y,uv.x);
    float k = cos(PI+(t+t*d/10.0)+angle*10.0)*1.7;
    glFragColor = vec4(k);
}
