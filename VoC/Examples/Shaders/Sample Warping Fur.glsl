#version 420

// original https://www.shadertoy.com/view/3tyXDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
MIT License

Copyright (c) 2020 oddlama

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// SETTINGS

// Adjusts the animation speed
const float time_speed = 0.3;
// grid pixel dimensions
const vec2 grid_size = vec2(30.0);
// length of line (CAREFUL DONT go > 6, this is O(n^2) !! )
const float line_len_factor = 4.0;
// Thickness of lines
const float line_width = 4.6;

// PRE-COMPUTED CONSTANTS, DON'T CHANGE

const ivec2 grid_neighborhood = ivec2(int(line_len_factor) - 1);
const float line_width_antialias = 1.0;
const float line_bounding_width = line_width + line_width_antialias;

////////////////////////////////////////////////// NOISE FUNCTIONS

float random (in vec2 x) {
    return fract(sin(dot(x.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise (in vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5
float fbm(in vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

////////////////////////////////////////////////// Helpers

vec2 nearest_grid_pos(vec2 frag_coord) {
    return round(frag_coord / grid_size) * grid_size;
}

vec2 screenToUniform(vec2 x) {
    return x * vec2(1. / resolution.x);
}

float fbm_warp(vec2 x, out vec2 q, out vec2 r) {
    q = vec2(fbm(x + vec2(0.0, 0.0)),
             fbm(x + vec2(5.2, 1.3)));

       float t = (time + 29.) * time_speed;
    r = vec2(fbm(x + 4.0 * q + vec2(1.7, 9.2) + .15 * t),
             fbm(x + 4.0 * q + vec2(8.3, 2.8) + .12 * t));
    return fbm(x + 4.0 * r);
}

////////////////////////////////////////////////// VECTOR FIELDS
// f = vectorfield at screen pos, f_color = color at screen pos

float f(vec2 x, out vec2 y) {
    x = screenToUniform(x);
    vec2 q, r;
    float k = fbm_warp(x, q, r);
    r = (r + vec2(-.5)) * 2.;
    y = grid_size * line_len_factor * r;
    return k;
}

vec3 f_color(vec2 x) {
    x = screenToUniform(x);
    vec2 q, r;
    float f = fbm_warp(x * 2., q, r);
    
    vec3 col = vec3(0.0);
    col = mix( vec3(0.4,0.2,0.2), vec3(1.5,0.4,0.1), f );
    col = mix( col, vec3(0.1,0.6,0.9), dot(r,r) );
    col = mix( col, vec3(0.2,1.19,1.09), 0.5*q.y*q.y );
    col *= (1. + q.x * q.x * q.x);
    col = mix( col, vec3(0.0,1.39,1.49), 0.3*smoothstep(1.2,1.3,abs(r.y)+abs(r.x)) );
    col *= f * 2.0;
    return col;
}

////////////////////////////////////////////////// MAIN

void main(void) {
    vec3 col = vec3(0.0);
    
    // Any pixel can be occluded by multiple lines. Only lines from neighboring
    // grid anchors will be considered.
    float active_lines = 0.0;
    for (int i = -grid_neighborhood.x; i <= grid_neighborhood.x; ++i) {
        for (int j = -grid_neighborhood.y; j <= grid_neighborhood.y; ++j) {
            // Beginning of the line is at the nearest grid anchor
            vec2 line_a = nearest_grid_pos(gl_FragCoord.xy + grid_size * vec2(i, j));
            // End of the line is the beginning but offset by the value of
            // our vector field at that position
            vec2 x;
            float k = f(line_a, x);
            vec2 line_b = line_a + x;
            
            vec2 line_dir = normalize(x);
            // Project pixel coord to the line
            float px_proj = dot(line_dir, gl_FragCoord.xy);
            // la will always be <= lb. (To proof simply replace line_b with line_a + line_dir, solve inequality)
            // Informal: The projected point x on d is always <= the projected point (x + d) on d.
            float la_proj = dot(line_dir, line_a);
            float lb_proj = dot(line_dir, line_b);
            // We account for the line width by subtracting from la and adding to lb.
            float la_proj_w = la_proj - line_width;
            float lb_proj_w = lb_proj + line_width;
            
            // Check if projected point is on line
            if (la_proj_w < px_proj && px_proj < lb_proj_w) {
                // Calculate distance to line segment on this local axis
                float dx = distance(px_proj, clamp(px_proj, la_proj, lb_proj));
                
                // Now do the projection on the perpendicular axis to get the distance on
                // the axis perpendicular to the line
                vec2 perp = line_dir.yx * vec2(1, -1);
                float px_proj_perp = dot(perp, gl_FragCoord.xy);
                float la_proj_perp = dot(perp, line_a);
                
                // Distance is easier here, as the line is infinitely small, so we don't need clamping.
                float dy = distance(la_proj_perp, px_proj_perp);

                // Calculate distance from line segment given distances on local axis
                float dist = length(vec2(dx, dy));
                if (dist < line_bounding_width) {
                    // alpha is the relative position of px in the line
                    float alpha = smoothstep(la_proj, lb_proj, px_proj);
                    
                    //vec3 c = mix(col_a, col_b, alpha);
                    vec3 c = f_color(gl_FragCoord.xy);
                    
                    // Line gets lighter at the very end (alpha), but influenced by vector field (k).
                    // Also add antialiasing to the line edge
                    float blend = alpha * (.2 + k * 2.) * (1. - smoothstep(line_width, line_bounding_width, dist));
                    // Blend with previously calculated factor, also make shorter darker everywhere
                    float len_f = length(x) / (length(grid_size) * line_len_factor);
                    c *= blend * 1.3 * len_f * (.7 + len_f);
                    
                    // Blend color with max
                    col = max(col, c);
                }
            }
        }
    }

    
    // Output to screen
    glFragColor = vec4(col, 1.0);
}
