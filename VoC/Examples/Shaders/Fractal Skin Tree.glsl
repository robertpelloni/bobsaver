#version 420

// original https://www.shadertoy.com/view/wssGRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 4.0

#define FOUR_LEVELS 0 // set to 0 to make 3 levels, 1 to make 4 levels

const mat3 mat_a = mat3(0.8, 0.6, 0.0,
                        -0.6, 0.8, 0.0,
                        0.0, 0.0, 1.0) * mat3(0.96, 0.0, 0.28, 0.0, 1.0, 0.0, -0.28, 0.0, 0.96);

const mat3 mat_b = mat3(0.96, 0.0, -0.28, 0.0, 1.0, 0.0, 0.28, 0.0, 0.96) *
    mat3(0.6, -0.8, 0.0,
         0.8, 0.6, 0.0,
         0.0, 0.0, 1.0);

const mat3 mat_c = mat3(0.8, 0.0, -0.6, 0.0, 1.0, 0.0, 0.6, 0.0, 0.8) *
    mat3(1.0, 0.0, 0.0,
         0.0, 0.96, -0.28,
         0.0, 0.28, 0.96);

const float cutoff = 0.81; // ad-hoc, should be much larger

float pill(in vec3 pt, in float l, in float r) {
    vec3 to_core = abs(pt - vec3(0.0, 0.5 * l, 0.0));
    to_core.y -= 0.5 * l;
    to_core = max(vec3(0.0), to_core);
    return length(to_core) - 2.0 * r;
}

float s_min(in float x, in float y, in float s) {

    float bridge =
        clamp(abs(x-y)/s, 0.0, 1.0);
    return min(x,y) - 0.25 * s * (bridge - 1.0) * (bridge - 1.0);
}

float sdf_4(in vec3 pt) {
    float d = pill(pt, 0.25, 0.025);
    return d;
}

float sdf_3(in vec3 pt) {
    vec3 off = vec3(0.0, 0.25, 0.0);
    if (dot(pt-off, pt-off) > cutoff) {
        return length(pt-off);
    }
    float d = pill(pt, 0.25, 0.025);
#if FOUR_LEVELS    
    d = s_min(d, 0.8 * sdf_4(1.25 * mat_a * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_4(1.25 * mat_b * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_4(1.25 * mat_c * (pt - off)), 0.025);
#endif
    return d;
}

float sdf_2(in vec3 pt) {
    vec3 off = vec3(0.0, 0.25, 0.0);
    if (dot(pt-off, pt-off) > cutoff) {
        return length(pt-off);
    }
    float d = pill(pt, 0.25, 0.025);
    d = s_min(d, 0.8 * sdf_3(1.25 * mat_a * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_3(1.25 * mat_b * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_3(1.25 * mat_c * (pt - off)), 0.025);
    return d;
}

float sdf_1(in vec3 pt) {
    vec3 off = vec3(0.0, 0.25, 0.0);
    if (dot(pt-off, pt-off) > cutoff) {
        return length(pt-off);
    }
    float d = pill(pt, 0.25, 0.025);
    d = s_min(d, 0.8 * sdf_2(1.25 * mat_a * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_2(1.25 * mat_b * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_2(1.25 * mat_c * (pt - off)), 0.025);
    return d;
}

float sdf(in vec3 pt) {
    vec3 off = vec3(0.0, 0.25, 0.0);
    if (dot(pt-off, pt-off) > cutoff) {
        return length(pt-off);
    }
    float d = pill(pt, 0.25, 0.025); // temporary sdf
    d = s_min(d, 0.8 * sdf_1(1.25 * mat_a * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_1(1.25 * mat_b * (pt - off)), 0.025);
    d = s_min(d, 0.8 * sdf_1(1.25 * mat_c * (pt - off)), 0.025);
    return d;
}

vec3 sdf_grad(in vec3 pt) {
    float f = sdf(pt);
    const float h = 0.001;
    const float h_inv = 1000.0;
    
    return h_inv *
        vec3(sdf(pt + vec3(h, 0.0, 0.0)) - f,
             sdf(pt + vec3(0.0, h, 0.0)) - f,
             sdf(pt + vec3(0.0, 0.0, h)) - f);
}

float raymarch(in vec3 pt, in vec3 dir) {
    vec3 d = normalize(dir);
    vec3 p = pt;
    float accum = 0.0;
    float s = sdf(pt);
    for(int i = 0; i < 128; ++i) {
        if (accum > MAX_DIST || s < 1.0e-3) {
            return accum;
        }
        accum += 0.75 * s;
        p = pt + accum * d;
        s = sdf(p);
    }
    if (s > 1.0e-3) {
        return MAX_DIST + 1.0;
    }
    return accum;
}

float raymarch_out(in vec3 pt, in vec3 dir) {
    vec3 d = normalize(dir);
    vec3 p = pt;
    float accum = 0.0;
    float s = sdf(pt);
    for(int i = 0; i < 2; ++i) {
        if (accum > 1.0e-3 && s > -1.0e-3) {
            return accum;
        }
        accum += 0.75 * max(abs(s), 1.0e-3);
        p = pt + accum * d;
        s = sdf(p);
    }
    if (s < -1.0e-3) {
        return 1000.0;
    }
    return accum;
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 dir = normalize(vec3(uv, 6.0));
    
    vec3 orig = vec3(0.0, 0.34, -2.5);
    
    float theta = 0.1 * time;
    float ct = cos(theta);
    float st = sin(theta);
    
    mat3 spin = mat3(ct, 0.0, st,
                     0.0, 1.0, 0.0,
                     -st, 0.0, ct);
    
    orig = spin * orig;
    dir = spin * dir;
    
    float dist = raymarch(orig, dir);
    
    float bright = 0.0;
    
    vec3 refl_color = vec3(1.0);
    vec3 trans_color = vec3(1.0, 0.5, 0.4);
    const vec3 light_dir = vec3(1.0, 0.0, 0.0);
    float thru_dist = 1000.0;
    vec3 n = dir;
    if (dist < MAX_DIST) {
        n = normalize(sdf_grad(orig + dir * dist));
        bright = smoothstep(0.0, 0.2, abs(dot(dir, n)));
        dir = mix(dir, normalize(reflect(dir, n)), bright);
        thru_dist = raymarch_out(orig + dir * (dist + 1.0e-2), light_dir);
        refl_color = vec3(0.8, 0.7, 0.6);
    }

    vec3 col = (0.5 + 0.5 * bright) *
        (0.2 * smoothstep(0.7, 1.0, dot(dir, light_dir)) + 0.7 * smoothstep(0.1, 1.0,
                                                                      dot(n, light_dir)))*
        refl_color;
    
    col += bright * (1.0 / max(abs(1.0 * thru_dist), 0.5)) * trans_color;

    // Output to screen
    glFragColor =  vec4(col,1.0);
}
