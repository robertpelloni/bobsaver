#version 420

// original https://www.shadertoy.com/view/XlyfDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 coords){
    return fract(cos(dot(coords, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c) * v;
}

vec2 applyCamera(vec2 pixCoords) {
    vec2 cameraCenter = vec2(
        3. * cos(time * 0.1) + 0.05 * time,
        3. * sin(time * 0.2)
    );
    float zoom  = (resolution.x / 10.) * (1. + 0.3 * cos(time));
    float angle = 0.1 * time;
    
    vec2 coords = (pixCoords / zoom) - cameraCenter;
    return rotate(coords, angle);
}

vec3 backgroundColor (vec2 coords) {
    float light = 0.7 + 0.3 * cos(2. * coords.y + 5. * time);
    return vec3(
        1.,
        0.5 + 0.5 * light,
        light * (0.6 + 0.4 * cos(25. * coords.x))
    );    
}

vec3 insideCircleColor (float distanceToCenter, float random) {
    return vec3(
        0.5 + 0.5 * random,
        cos(20. * distanceToCenter),
        0.5 + 0.5 * cos(random*99.)
    );
}

float radius (float random) {
    return (0.3 + 0.2 * random) * (0.8 + 0.3 * cos(6. * random * time));
}

float relativeDistanceToCenter (vec2 coords, float random) {
    vec2  circleCenter     = vec2(0.5);
    float distanceToCenter = distance(mod(coords, 1.), circleCenter);
    return distanceToCenter / radius(random);
}

void main(void) {

    vec2 pixCoords = gl_FragCoord.xy;
    vec4 color;

    vec2 coords = applyCamera(pixCoords);
    
    float random = rand(floor(coords));
  
    float d = relativeDistanceToCenter(coords, random);
    
    
    if (d < 1.) {
        color = vec4(insideCircleColor(d, random), 1.);
    } else {
        color = vec4(backgroundColor(coords), 1.);
    }

    glFragColor = color;
    
}

