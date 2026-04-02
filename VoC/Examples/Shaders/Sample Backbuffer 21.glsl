#version 420

uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

void main( void ) {
    vec2 aspect = vec2(resolution.x/resolution.y, 1);
    if(aspect.x<aspect.y)aspect = vec2(1, resolution.y/resolution.x);;
    vec2 p = gl_FragCoord.xy / resolution.xy;
    p = p - vec2(0.5);
    p = p * aspect;
    if(p.x * p.x > 0.25) {
        glFragColor.xyz = vec3(1);
        return;
    }
    float r = sqrt(p.x * p.x + p.y * p.y);
    float rr = r;
    float a = atan(p.y, p.x);
    if (r != 0.0) {
        r = 0.25 / r;
    }
    p.x = r * cos(a+mouse.x*6.28);
    p.y = r * sin(a+mouse.y*6.28);
    p += vec2(0.5);
    p = abs(mod(p,vec2(1.0))-0.5);
    p += vec2(0.5);
    p /= aspect;
    float c = texture2D(backbuffer, p).x;
    c = c * c;
    c = c + (rr - 0.46875);
    glFragColor.xyz = vec3(sqrt(c));
}
