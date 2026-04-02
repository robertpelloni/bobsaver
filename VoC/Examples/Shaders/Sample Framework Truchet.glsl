#version 420

// original https://www.shadertoy.com/view/mt2Bzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CONTROLS

const float GRID_SIZE = 8.;
// seconds to complete a full turning cycle
const float CYCLE_PERIOD = 6.;
// should be half or less than CYCLE_PERIOD
// as there are two turns in a period.
const float TURNING_TIME = .4;

// DERIVED / CONSTANT

const float FULL_TURN = 6.2831853071;
const float HALF_TURN = FULL_TURN / 2.;
const float QUARTER_TURN = HALF_TURN / 2.;

const float THIRD = 1. / 3.;

const vec2 NE = vec2(1., 1.);
const vec2 NW = vec2(0., 1.);
const vec2 SE = vec2(1., 0.);
const vec2 DN = vec2(.5, 1.);
const vec2 DS = vec2(.5, 0.);

// MATH FUNCTIONS

// 0.0-0.5 : constant : floor(x)
// 0.5-1.0 : linearly increasing : floor(x) - floor(x + 1)
float paused_linear(float x) {
    return floor(x) + max(0., fract(x) - .5) * 2.;
}

// produces a staircase pattern in 2d space
vec2 staircase(float x) {
    return vec2(
        paused_linear(x - .5),
        paused_linear(x)
    );
}

// square wave with rounded corners
float rounded_square_wave(float x, float knee_width) {
    return smoothstep(
        .5 - knee_width,
        .5 + knee_width,
        1. - abs(fract(x) - .5) * 2.
    );
}

vec2 rotate(vec2 uv, float angle) {
    return mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    ) * uv;
}

float rand(vec2 p){
    return fract(sin(dot(p.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec4 make_grid(vec2 uv) {
    vec2 coord = floor(uv * GRID_SIZE);
    vec2 cell_uv = fract(uv * GRID_SIZE);
    return vec4(coord, cell_uv);
}

float aa_step(float d, float x) {
    float aa = 5. / resolution.y;
    return smoothstep(d - aa, d + aa, x);
}

// CELL CONSTRUCTORS

// T cell
vec3 t_cell_masks(vec2 st) {
    float shared = st.y > THIRD * 2. ? 1. : 0.;
    shared -= 1. - aa_step(THIRD / 2., length(st - DN));
    
    vec3 masks = vec3(1. - shared, shared, 1.);
    
    masks.x -= 1. - aa_step(THIRD, length(st));
    masks.x -= 1. - aa_step(THIRD, length(st - SE));
    
    masks.y -= 1. - aa_step(THIRD, length(st - NW));
    masks.y -= 1. - aa_step(THIRD, length(st - NE));
    
    masks.z -= masks.x;
    masks.z -= masks.y;
    
    return masks;
}

// ÷ cell
vec3 i_cell_masks(vec2 st) {
    vec3 masks = vec3(0., 1., 0.);
    vec2 qr = .5 - abs(st - .5);
    
    masks.x = (st.y > THIRD && st.y < THIRD * 2.) ? 1. : 0.;
    masks.x += 1. - aa_step(THIRD / 2., length(st - DS));
    masks.x += 1. - aa_step(THIRD / 2., length(st - DN));
    
    masks.z = 1. - aa_step(THIRD, length(qr));
    
    masks.y -= masks.x;
    masks.y -= masks.z;
    
    return masks;
}

// + cell
vec3 cross_cell_masks(vec2 st) {
    vec3 masks = vec3(1., 0., 1.);
    vec2 qr = .5 - abs(st - .5);
    
    masks.z -= aa_step(THIRD, length(qr));
    masks.x = 1. - masks.z;
    
    return masks;
}

// empty cell
vec3 empty_cell_masks(vec2 st) {
    vec3 masks = vec3(1.);
    
    // octagonal reflection
    vec2 qr = .5 - abs(st - .5);
    qr = qr.x > qr.y ? qr : vec2(qr.y, qr.x);
    qr = qr.x + qr.y <= 1. ? qr : 1. - qr;
    
    masks.x -= aa_step(THIRD / 2., length(qr - DS));
    masks.z -= aa_step(THIRD, length(qr));
    masks.y -= masks.x + masks.z;
    
    return masks;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    float angle = rounded_square_wave(
        (time + 1.5) / CYCLE_PERIOD,
        TURNING_TIME / CYCLE_PERIOD
    ) * QUARTER_TURN;
    uv = rotate(uv, angle);
    // TODO: The combination of the smooth rotation with the hard corners
    // of the staircase movement causes visual issues that are more obvious
    // when TURNING_TIME is higher than 1.5s or so. The corners of the
    // staircase movement should be smoothed to fix this (probably with a
    // change to paused_linear).
    uv += staircase(time / CYCLE_PERIOD);
    
    vec4 grid = make_grid(uv);
    
    float h = rand(grid.xy / 100.);
    vec2 st = grid.zw;
    
    // randomly rotate tile
    st = h > .5 ? st : vec2(st.y, st.x);
    
    // randomly flip tile
    st.y = h > .25 && h < .75 ? st.y : 1. - st.y;
    
    vec3 masks = vec3(0);
    int type = int(h * 57.) % 4;
    switch (type) {
        case 0:
            masks = t_cell_masks(st);
            break;
        case 1:
            masks = i_cell_masks(st);
            break;
        case 2:
            masks = cross_cell_masks(st);
            break;
        case 3:
            masks = empty_cell_masks(st);
            break;
    }
    
    vec3 color = vec3(0);
    color += vec3(.01, .01, .01) * masks.x;
    color += vec3(0.06, 0.75, 0.23) * masks.y;
    color += vec3(.9, .9, .9) * masks.z;

    vec3 srgb = pow(color.rgb, vec3(1. / 2.2));
    glFragColor = vec4(srgb, 1.0);
}
