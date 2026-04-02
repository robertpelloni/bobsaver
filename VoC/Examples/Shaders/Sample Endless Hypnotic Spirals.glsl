#version 420

// original https://www.shadertoy.com/view/WsXGDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SCALE 3.0

#define SCENE_ROTATION_SPEED -0.1

#define PLANE_ROTATION_SPEED 0.3

#define EDGE_SHARPNESS 20000.0

#define AIR_PERSPECTIVE 2.0

#define SPIRAL_SPEED 5.0

mat2 rotate2d(float angle){
    return mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    );
}

void main(void) {
    vec2 pixel = (gl_FragCoord.xy -.5 * resolution.xy) / resolution.y;
    pixel *= rotate2d(time * SCENE_ROTATION_SPEED);
    vec2 trans = vec2(pixel.x / pixel.y, 1.0 / pixel.y);
    trans *= rotate2d(time * PLANE_ROTATION_SPEED);    
    trans *= SCALE;
    
    vec2 inner = mod(trans, 2.0) - vec2(1);
    float angle = atan(inner.x, inner.y);
    float dist = length(inner);
    float luminance = sin(dist * 16.0 + angle - (time * SPIRAL_SPEED));

    // apply air perspective
    luminance *= pow(abs(pixel.y * 2.0), AIR_PERSPECTIVE);
    glFragColor = vec4(vec3(luminance),1.0);
}
