#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    float l = length(p);

    float c = step(1.0,l);
    float a = atan(p.y,p.x) * 2.0;

    glFragColor = vec4(sin(a * 10. + floor(l * 20.) * time));

}
