#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
const float n_circles = 100.;
const float max_radius = .3;
const float min_radius = .1;
const float seed1 = 69.7;
const float seed2 = 82.4;
const float seed3 = 62.5;

float rand(float x, float seed) {
    return fract(sin(x) * seed);
}

float randFromTo(float x, float seed, float min, float max){
    return rand(x, seed) * (max - min) + min;
}

bool drawCircle(vec2 pos, vec2 center, float radius, inout vec3 color) {
    vec2 translatedCenter = vec2(sin(time) * randFromTo(center.x, seed1, -1.8, 1.8) + center.x, sin(time) * randFromTo(center.y, seed1, -1., 1.) + center.y);
    bool ret =  distance(pos, translatedCenter) <= radius;
    if (ret) {
        color = vec3(max (0.2, abs(center.x)), max (0.2, abs(center.y)), max (0.2, abs(center.y - center.x)));
    }
    return ret;
}

bool drawCircleOnMousePosition(float minRes, vec2 pos, float radiusMultiplier, inout vec3 color) {
    vec2 mousePosition = (mouse * resolution * 2. - resolution) / minRes;
    return drawCircle(pos, mousePosition, .1 * radiusMultiplier, color);
}

void drawCircles(vec2 pos, float radiusMultiplier, inout vec3 color) {
    for (float i=0.; i<n_circles; i++){
        if (drawCircle(pos, vec2(randFromTo(i, seed1, -1.8, 1.8), randFromTo(i, seed2, -1., 1.)), randFromTo(i, seed3, min_radius, max_radius) * radiusMultiplier, color)) {
            break;
        }
    }
}

void main( void ) {
    float minRes = min(resolution.x, resolution.y);
    vec2 pos = (gl_FragCoord.xy * 2. - resolution) / minRes;
    float radiusMultiplier = abs(sin(time / 1.5));
    vec3 color;
    //if (drawCircleOnMousePosition(minRes, pos, radiusMultiplier, color) == false) {
        drawCircles(pos, radiusMultiplier, color);
    //}
    glFragColor = vec4(color, 1);
}

