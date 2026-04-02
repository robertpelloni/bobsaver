#version 420

// original https://www.shadertoy.com/view/wlGXWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float SCALE = 2.;
const float LINES_WIDTH = 0.05;
const float DOT_SPEED_LIMITER = 5.;
const float EGC_SCALE = 1.;
const int MAX_TRAIL_ITEMS = 500;

const vec3 GRID_COLOR = vec3(.01, .07, .06);
const vec3 DOT_COLOR = vec3(1., 1., 1.);
const vec3 BLURRED_COLOR = vec3(.15, .68, .83);
const vec3 RING_COLOR = vec3(.10, .24, .25);

float remap01(float t, float a, float b) {
    return (t - a) / (b - a);
}

float Circle(vec2 uv, vec2 position, float radius, float blur) {
    float distance = length(uv - position);

    return smoothstep(radius, radius - blur, distance);
}

float GridLines(float t, float lines) {
    return step(fract(t * lines), LINES_WIDTH);
}

vec3 Ring(vec2 uv, vec2 position) {
    float ring = Circle(uv, position, .08, .01);
    ring -= Circle(uv, position, .065, .01);
    
    return RING_COLOR * ring;
}

float spike(float x, float d, float w, float raiseBy) {
    float f1 = pow(abs(x + (d * SCALE)), raiseBy);

    return exp(-f1 / w);
}

float generateEGC(float x) {
    x -= .5 * SCALE;

    float a = 0.4 * SCALE;
    float d = .3;
    float w = 0.001;
    
    float f1 = a * spike(x, d, w, 2.);
    float f2 = a * spike(x, d - 0.1, 2. * w, 2.);
    float f3 = a * 0.7 * spike(x, d - 0.3, 0.002, 2.);
    float f3a = 0.15 * spike(x, d - 0.37, 0.0001, 4.);
    float f4 = 0.25 * spike(x, d - 0.5, 0.005, 2.);
    float f5 = 0.1 * spike(x, d - 0.75, 0.0001, 4.);

    float f6 = a * spike(x, d - 1., 0.002, 2.);
    float f7 = 0.5 * spike(x, d - 1.1, w, 2.);

    float f8 = 0.1 * spike(x, d - 1.3, 0.0001, 4.);
    float f9 = 0.1 * spike(x, d - 1.45, 0.0001, 4.);

    return f1 - f2 + f3 + f3a - f4 + f5 + f6 - f7 - f8 + f9;
}

float getDotXPosition() {
    // Animate the dot position from left --> right
    float dotX = abs(sin(time));
    dotX = fract(time / DOT_SPEED_LIMITER);
    dotX *= 2. * SCALE;

    return dotX;
}

vec3 MovingDot(vec2 uv, vec2 dotPosition) {
    float movingDot = Circle(uv, dotPosition, .015, .01);
    float smallBlurredDot = Circle(uv, dotPosition, .06, .1);
    float bigBlurredDot = Circle(uv, dotPosition, .3, .6);

    vec3 color = DOT_COLOR * movingDot;
    color += BLURRED_COLOR * smallBlurredDot;
    color += BLURRED_COLOR * bigBlurredDot;
    color += Ring(uv, dotPosition);

    return color;

}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Scale the view
    uv *= SCALE;

    uv.y -= .5 * SCALE; // Center the Y axis
    uv.x *= resolution.x / resolution.y; // Keeps the aspect ratio

    float grid = GridLines(uv.x, 6.) + GridLines(uv.y, 6.);
    vec3 color = GRID_COLOR * grid;

    float dotX = getDotXPosition();
    vec2 dotPosition = vec2(dotX, generateEGC(dotX));

    color += MovingDot(uv, dotPosition);

    for(int i = 1; i < MAX_TRAIL_ITEMS; i++) {
        float delayedX = dotX - (float(i) * 0.002);
        vec2 trailPosition = vec2(delayedX, generateEGC(delayedX));

        float trail = Circle(uv, trailPosition, 0.028, 0.1);
        float trailBlur = Circle(uv, trailPosition, 0.06, 0.5);

        float q = 1. - remap01(float(i), 1., float(MAX_TRAIL_ITEMS));

        color += (DOT_COLOR * q) * trail;
        color += trailBlur * (BLURRED_COLOR * q);
    }

    glFragColor = vec4(color,1.0);
}
