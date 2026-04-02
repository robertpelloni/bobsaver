#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 hsv(in float h, in float s, in float v) {
    return mix(vec3(1.0), clamp((abs(fract(h + vec3(3, 2, 1) / 3.0) * 6.0 - 3.0) - 1.0), 0.0 , 1.0), s) * v;
}

void main(void)
{
    float t = time*0.1;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = uv*2.0 - 1.0;
    //p.x *= resolution.x/resolution.y;
    p = vec2(p.x*sin(t) + p.y*cos(t), p.x*cos(t)-p.y*sin(t));
    float x = atan(p.y, p.x)/6.28+3.14;
    float r = 0.5;
    vec4 col = texture2D(backbuffer, abs(mod(p, 1.0)-0.5))*0.9;
    vec2 y = p;
    for (int i = 0; i < 3; i++) {
        y = vec2(y.x*sin(r) + y.y*cos(r), -y.x*cos(r)+y.y*sin(r));
        y = abs(mod(y+t, 2.0)-1.0);
    }
    col = mix(col, hsv(r+length(y), 1.0, 1.0).xyzz, 
              smoothstep(0.03, 0.0, min(abs(y.x), abs(y.y))));
    glFragColor = col;
}
