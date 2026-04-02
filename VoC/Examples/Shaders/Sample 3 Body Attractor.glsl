#version 420

// original https://www.shadertoy.com/view/slX3z8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 3 Body Attractor
//
// Inspired by this video:
// The relationship between chaos, fractal and physics: https://www.youtube.com/watch?v=C5Jkgvw-Z6E&t=336s

#define G 1.0               // Gravity strength

#define M_BODY 1.0          // Mass of the simulated body

#define M_A1 1.0            // Mass of attractor 1
#define M_A2 1.0            // Mass of attractor 2
#define M_A3 1.0            // Mass of attractor 3

#define SPEED    0.05       // Controls the speed of the attractors
#define SCALE    4.5        // Controls how zoomed in the view is
#define EXPOSURE 1.5        // Controls the brightness

#define SHOW_ATTRACTORS     // Toggle red, green and blue circles representing the attractor positions

#define NOF_ITERATIONS 200  // Number of simulation iterations
#define Z_DISTANCE 5.0      // Minimum distance between any attractor and body
#define TIMESTEP 1.0        // Simulation timestep

vec2 A1;
vec2 A2;
vec2 A3;

struct Body {
    vec2 pos;
    vec2 vel;
    vec2 acc;
};

float d2(vec2 A, vec2 B) {
    vec2 C = A - B;
    return dot(C, C);
}

float d2_3d(vec3 A, vec3 B) {
    vec3 C = A - B;
    return dot(C, C);
}

vec3 get_closest_attractor_color(vec2 pos) {
    float d2_A1 = d2(pos, A1);
    float d2_A2 = d2(pos, A2);
    float d2_A3 = d2(pos, A3);
    
    if (d2_A1 < d2_A2 && d2_A1 < d2_A3) return vec3(1.0 / d2_A1,0,0);
    if (d2_A2 < d2_A3) return vec3(0,1.0 / d2_A2,0);
    return vec3(0,0,1.0 / d2_A3);
}

// A gravity-ish simulation routine
Body update_body(Body p, float dt) {
    // Calculate force
    vec2 F = vec2(0);
    F += normalize(A1 - p.pos) * G * (M_A1 * M_BODY) / (d2_3d(vec3(p.pos, 0), vec3(A1, Z_DISTANCE)));
    F += normalize(A2 - p.pos) * G * (M_A2 * M_BODY) / (d2_3d(vec3(p.pos, 0), vec3(A2, Z_DISTANCE)));
    F += normalize(A3 - p.pos) * G * (M_A3 * M_BODY) / (d2_3d(vec3(p.pos, 0), vec3(A3, Z_DISTANCE)));
    
    // Update acceleration, position and velocity
    p.acc = F / M_BODY;
    p.pos = p.pos + p.vel * dt + 0.5 * p.acc * dt * dt;
    p.vel = p.vel + p.acc * dt;

    return p;
}

vec3 get_color(vec2 initial_pos) {
    Body p;
    p.pos = initial_pos;
    p.vel = vec2(0);
    p.acc = vec2(0);
    
    vec3 color = vec3(0);
    
    for (int i = 0; i < NOF_ITERATIONS; i++) {
       p = update_body(p, TIMESTEP);
       color += get_closest_attractor_color(p.pos);
    }
    
    return color / float(NOF_ITERATIONS);
}

vec2 unit_vec(float angle) {
    return vec2(cos(angle), sin(angle));
}

vec3 normalize_color(vec3 raw) {
    return 2.0 / (exp(-EXPOSURE * raw) + 1.0) - 1.0;
}

vec2 normalize_gl_fragcoord(vec2 frag_coord) {
    return ((frag_coord/resolution.x) - 0.5 * vec2(1.0, resolution.y / resolution.x)) * SCALE;
}

void main(void)
{    
    
    // Create interesting positions for attractos
    A1 = sin(-time * SPEED * 3.0) * unit_vec(-time * SPEED * 11.0);
    A2 = 1.2 * unit_vec( time * SPEED * 5.0);
    A3 = normalize_gl_fragcoord(mouse*resolution.xy.xy);

        
    vec2 pos = normalize_gl_fragcoord(gl_FragCoord.xy);
    
    vec3 col = get_color(pos);
    col = normalize_color(col);
    
    #ifdef SHOW_ATTRACTORS
    if (d2(A1, pos) < 0.0025) col = vec3(1,0,0);
    if (d2(A2, pos) < 0.0025) col = vec3(0,1,0);
    if (d2(A3, pos) < 0.0025) col = vec3(0,0,1);
    #endif

    glFragColor = vec4(col,1.0);
}
