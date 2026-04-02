#version 420

// original https://www.shadertoy.com/view/XdjBWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323
#define RAYS 11.0
#define PROB 0.75
#define SIZE 0.45

float random (vec2 st) {
    return fract(sin(dot(st, vec2(12.5629849,78.1384))) * 41631.4232);
}

void main(void) {
    vec2 p = gl_FragCoord.xy / resolution.xy - vec2(0.5, 0.5);
    p.x *= resolution.x / resolution.y;
    float t = time - 10.0;
    
    float dist = length(p);
    float angle = atan(p.y, p.x) + PI;
  
    // create, subdivide vortex
    float angle_2 = angle * RAYS / PI + cos(dist * 15.0) * cos(t * 0.5) * (0.5 / (dist + 0.1));
    
    float cell_angle = mod(floor(angle_2), RAYS * 2.0);
    float cell_dist = pow(dist, 0.6) * 10.0 - (t + 0.5) * (mod(cell_angle, 2.0) - 0.5) * (0.4 + 0.6 * random(vec2(cell_angle + 0.1)));

    float s = abs(floor(cell_dist));
    float c = length(vec2(abs(fract(angle_2) - 0.5),
                          abs(fract(cell_dist)) - 0.5));
    // anti aliasing
    float eps = 10.0 / (dist * PI * resolution.y);
    
    float mask = 1.0 - smoothstep(SIZE - eps, SIZE + eps, c);
    mask *= step(random(vec2(s, cell_angle)), PROB);
    
    // rainbow
    float col_ang = cell_angle * PI / RAYS;
    vec3 col = cos(vec3(col_ang) + vec3(0.0, 2.0/3.0, 4.0/3.0) * PI) * 0.5 + 0.5;

    // normal
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 n2 = rot * vec2(fract(angle_2) - 0.5, fract(cell_dist) - 0.5);
    vec3 norm = normalize(vec3(n2.x, n2.y, cos(c / SIZE * 0.5 * PI)));
    
    // lights
    vec3 l1 = clamp(dot(normalize(vec3(-1.0, 0.0, 0.0)), norm), 0.0, 1.0) * vec3(0.6, 0.9, 0.95);
    vec3 l2 = pow(clamp(dot(normalize(vec3(0.0, -1.0, 1.0)), norm), 0.0, 1.0), 16.0) * vec3(0.95, 0.9, 0.6);
    
    glFragColor = vec4(mix(vec3(1.0), col + 0.5 * l1 + l2, mask), 1.0);

    // gamma correction
    glFragColor.xyz = pow(glFragColor.rgb, vec3(1.0/2.2));
}
