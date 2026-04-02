#version 420

// original https://www.shadertoy.com/view/DtKyRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float mapRange(float v, float a0, float b0, float a1, float b1) {
    float t = (v - a0) / (b0 - a0);
    return mix(a1, b1, t);
}

vec2 rotateDeg(vec2 v, float angleDeg) {
    float angleRad = radians(angleDeg);
    float cosAngle = cos(angleRad);
    float sinAngle = sin(angleRad);
    
    return vec2(
        v.x * cosAngle - v.y * sinAngle,
        v.x * sinAngle + v.y * cosAngle
    );
}

vec2 oscillatingRotationDeg(vec2 pos, float minAngle, float maxAngle, float period) {
    float phase = mapRange(time, 0., period, 0., radians(360.));
    float angleDeg = mapRange(sin(phase), -1., 1., minAngle, maxAngle);
    return rotateDeg(pos, angleDeg);
}

const int STRIPE_COUNT = 6;
const float STRIPE_WIDTH = 0.15;
const float STRIPE_BLUR = 0.07;
const float STRIPE_SPEED = 0.3;

const float MIN_ANGLE_DEG = -5.;
const float MAX_ANGLE_DEG = 95.;

const float OSCILLATION_PERIOD = 40.;

const vec3 STRIPE_COLORS[STRIPE_COUNT] = vec3[STRIPE_COUNT](
    vec3(.24, .12, .02),  // brown
    vec3(.73, .28, .02),  // mid orange
    vec3(0.898, 0.204, 0.0439),  // bright orange
    vec3(0.949, 0.541, 0.059),  // yellow
    vec3(.15, 0.3, 0.),  // green
    vec3(0.047, 0.337, 0.475)  // blue
);

void main(void)
{
    vec2 pos = (2. * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
    pos = oscillatingRotationDeg(pos, MIN_ANGLE_DEG, MAX_ANGLE_DEG, OSCILLATION_PERIOD);
    
    // flare out a bit towards the top and bottom with a parabola
    pos.x = pos.x * (1. - pow(abs(pos.y) / 3., 2.));
    
    // scroll sideways
    pos.x += time * STRIPE_SPEED;

    // Repeat the pattern forever.
    // Normalize stripeX so that each stripe is 1 unit wide.
    float stripeX = mod(pos.x, float(STRIPE_COUNT) * STRIPE_WIDTH) / STRIPE_WIDTH;
    
    vec3 color;
    
    int rightColorIndex = int(floor(stripeX + .5)) % STRIPE_COUNT;
    int leftColorIndex = (rightColorIndex + STRIPE_COUNT - 1) % STRIPE_COUNT;
    
    float t = fract(stripeX + .5);
    
    float mask = smoothstep(.5 - STRIPE_BLUR, .5 + STRIPE_BLUR, t);
    
    vec3 leftColor = mix(STRIPE_COLORS[leftColorIndex], STRIPE_COLORS[leftColorIndex] * .5, mask);
    vec3 rightColor = mix(STRIPE_COLORS[rightColorIndex] * .5, STRIPE_COLORS[rightColorIndex], mask);
    
    color = mix(leftColor, rightColor, mask);

    glFragColor = vec4(color, 1.);
}
