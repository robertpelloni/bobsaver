#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void) {
    glFragColor=vec4(0.0);
    vec2 uv = (gl_FragCoord.xy/resolution.xy)-.5;
    vec4 back=texture2D(backbuffer,uv*0.95+.5);
    uv.x *= resolution.x/resolution.y;

    float a = 2.0*atan(uv.y/uv.x);
    uv*=2./(sin(a-time*6.)*2.+sin(a*9.+time*7.)) ;

    float c = (abs(length(uv)-.3) * 12.0);

    glFragColor += (vec4(sin(time*40.)/c, sin(time*50.)/c, 0.8/c, 1)+back*8.)/8.7;
}
