#version 420

// original https://www.shadertoy.com/view/7dBXzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// check out https://www.twitch.tv/sableraph
// sableraph is posting creative coding chanllange every week and then review
// sketches on the stream every Sunday. This time the topic was "duality"

// Some comments:

// I like that using trigonometric shapes is reducing the need of antialiasing whatsover

// I started with grayscale, but then decided to apply distance based and angular
// based chromatic abberration, which gives more video synthesis-like aesthetics
// Maybe my childhood CRT experience makes me love vaporwave aesthetics so much :)

#define SCALE                  70.0
#define ROTATION_SPEED         -1.
#define DISTANCE_SPREAD        -.02
#define ANGLE_SPREAD           .1
#define SHAPE_RANGE            2.
#define OSCILLATION_SPEED      .15
#define OSCILLATION_AMPLITUDE  .2
#define MIRROR_TRUE            1.
#define MIRROR_FALSE           -1.

float getColorComponent(float dist, float angle, float mirror) {
    return clamp(
        sin(
            (dist * SCALE)
                + angle * mirror
                + (cos(dist * SCALE))
                - (time * ROTATION_SPEED) * mirror
        )
        - dist * SHAPE_RANGE
        ,0. // try putting small negative value here, like -.2 :)
        ,1.
    );
}

vec3 getSwirl(vec2 center, float dist, float mirror) {
    float angle = atan(center.x, center.y);
    return vec3(
        getColorComponent(dist * (1. - DISTANCE_SPREAD), angle - ANGLE_SPREAD, mirror),
        getColorComponent(dist * (1. + 0.)             , angle - 0.          , mirror),
        getColorComponent(dist * (1. + DISTANCE_SPREAD), angle + ANGLE_SPREAD, mirror)
    );    
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy -.5 * resolution.xy) / resolution.y;
    vec2 oscillation = vec2(
        sin(time * OSCILLATION_SPEED),
        0.
    ) * OSCILLATION_AMPLITUDE;
    vec2 uv1 = uv + oscillation;
    vec2 uv2 = uv - oscillation;
    float dist1 = length(uv1);
    float dist2 = length(uv2);
    vec3 color =
        getSwirl(uv1, dist1, MIRROR_TRUE)
        + getSwirl(uv2, dist2, MIRROR_FALSE);
    glFragColor = vec4(color, 1.);
}
