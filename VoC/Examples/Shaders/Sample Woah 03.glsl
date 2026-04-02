#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void){
    float dx = gl_FragCoord.x - (resolution.x * mouse.x);
    float dy = gl_FragCoord.y - (resolution.y * mouse.y);
    float dist = sqrt(dx * dx + dy * dy) * sin(time * 5.0);
    glFragColor = vec4(vec3(sin(dist), cos(dist), tan(dist)), 1.0);
}
