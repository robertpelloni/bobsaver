#version 420

// original https://www.shadertoy.com/view/tts3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv-=time * .01 -.5;
    uv*=10.;
    float s = random(floor(uv)*10.);    
    float a = 10.*random(floor(uv)) + time * 3.;
    vec2 u = fract(uv)-.5 + vec2(sin(a),cos(a))*.2;
    float d = length(u);
    float k = smoothstep(d,d+.05,s*.3);
    glFragColor = vec4(k);
}
