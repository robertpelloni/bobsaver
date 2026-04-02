#version 420

// original https://www.shadertoy.com/view/NsVGWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int   RIBBON_COUNT = 13;
const float RIBBON_WIDTH = .005;
const float RIBBON_EDGE_WIDTH = .003;
const float RIBBON_EDGE_START = RIBBON_WIDTH - RIBBON_EDGE_WIDTH;
const float SCALE_CHANGE = .9;
const float SCALE_CHANGE_VARIATION = .02;
const float SCALE_CHANGE_SPEED = 1.7;
const float WAVE1_PERIOD = 10.;
const float WAVE1_SPEED  = 3.;
const float WAVE1_IMPACT = .05;
const float WAVE2_PERIOD = 8.;
const float WAVE2_SPEED  = 2.5;
const float WAVE2_IMPACT = .2;

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 st =
        (2.* gl_FragCoord.xy - resolution.xy)
        / min(resolution.x, resolution.y);
    vec3 color = vec3(0);
    for (int i = 0; i < RIBBON_COUNT; i++) {
        st *= (
            SCALE_CHANGE
            + (
                sin(time * SCALE_CHANGE_SPEED)
                * SCALE_CHANGE_VARIATION
            )
        );
        float dist = length(st);
        float shapeSpace = abs(
            st.x
            + sin(st.y * WAVE1_PERIOD + time * WAVE1_SPEED) * WAVE1_IMPACT * (1.2 - uv.y)
            + sin(st.y * WAVE2_PERIOD + time * WAVE2_SPEED) * WAVE2_IMPACT * (1.4 - uv.y)
        );
        float ribbon = smoothstep(
            RIBBON_WIDTH,
            RIBBON_EDGE_START,
            shapeSpace
        );
        color += vec3(ribbon);
    }

    glFragColor = vec4(color, 1);
}
