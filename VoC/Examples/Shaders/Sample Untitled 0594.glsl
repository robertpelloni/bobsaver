#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define RGB(r, g, b) vec3(r / 255.0, g / 255.0, b / 255.0)
const vec3 WHITE = vec3(1.0, 1.0, 1.0);
const vec3 BLUE = RGB(85.0, 205.0, 252.0);
const vec3 PINK = RGB(247.0, 168.0, 184.0);
const vec3 RED = RGB(200.0, 168.0, 184.0);

vec3 band(vec2 pos) {
    float y = abs(pos.y) - 0.5;
    if (y <= 0.0) return WHITE;
    if (y <= 1.0) return PINK;
    if (y <= 1.4) return BLUE;
    if (y <= 2.) return RED;
}

void main() {

    //vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 position = (gl_FragCoord.xy / resolution.xy * 4.0) - vec2(0.0, 2.5);
    float X = position.x*64.;
    float Y = position.y*48.;
    float t = time*0.6;
    float o = sin(-cos(t+X/400.)-t+Y/6.+sin(X/(5.+cos(t*.1)+sin(X/9.+Y/10.))));
    //glFragColor = vec4( hsv2rgb(vec3( o, 1., .5)), 1. );

    glFragColor = vec4(band(position + vec2(0., cos(position.x*7. + o + time))), 2.0);
}
