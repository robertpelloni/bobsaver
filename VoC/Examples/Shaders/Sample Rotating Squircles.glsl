#version 420

// original https://www.shadertoy.com/view/ltVcDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define INSCRIBE 0 // set to 1 to prevent squircles from overlapping

float squircle(in vec2 pos, in float rad4) {
    vec2 tmp = pos * pos;
    vec2 deriv = 4.0 * pos * tmp;
    tmp = tmp * tmp;
    float val4 = dot(vec2(1.0, 1.0), tmp);
    float deriv_mag = length(deriv);
    float sdf = (val4 - rad4) / deriv_mag;
    return clamp(0.5 * sdf * resolution.y, 0.0, 1.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    const float pi = 3.141592654;
    
    float time = mod(time, 2.0 * pi);
    time = (0.5 * pi) * smoothstep(0.25 * pi, 0.75 * pi, time) +
        (0.5 * pi) * smoothstep(1.25 * pi, 1.75 * pi, time);
    
    float vel = 0.5;
    float ct = cos(vel * time);
    float st = sin(vel * time);
    
    mat2 rot = mat2(ct, st, -st, ct);
    
    float rad4 = max(resolution.y, resolution.x) / resolution.y;
    rad4 = rad4 * rad4 * rad4 * rad4 + 1.0;
    vec3 col = vec3(1.0, 0.0, 1.0);
    float sign_val = -1.0;
    vec3 curr_col = vec3(1.0, 0.0, 0.0);
    
    for (int i = 0; i < 64; ++i) {
        uv = rot * uv;
        float s = 1.0 - squircle(uv, rad4);
        col += sign_val * s * curr_col;
        sign_val = sign_val * -1.0;
        curr_col = curr_col.zxy;
#if INSCRIBE
        rad4 = rad4 * 0.5;
#else        
        rad4 = rad4 * 0.75;
#endif        
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
