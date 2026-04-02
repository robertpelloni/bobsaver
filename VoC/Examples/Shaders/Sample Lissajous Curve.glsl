#version 420

// original https://www.shadertoy.com/view/MtGyz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.141592
#define ratio (2.0/3.0)
#define speed 2
#define offset (pi*0.0)
#define radius 0.45
#define trail (pi*3.0)
#define detail 20
#define thickness 0.01

vec2 get_point(float time) {
    vec2 p;
    p.x = cos(time * float(speed));
    p.y = sin(time * float(speed) * float(ratio) + float(offset));
    p *= float(radius);
    return p;
}

float point_linesegment_dist(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    float l_sq = dot(ab, ab);
    if (l_sq <= 0.000001)
        return distance(p, a);
    vec2 ap = p - a;
    float proj = dot(ap, ab) / l_sq;
    proj = clamp(proj, 0.0, 1.0);
    vec2 pp = a + proj * ab;
        
    return distance(p, pp);
}

void main(void) {

    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    float on_line = 0.0f;
    float inv_detail = (1.0 / float(detail));
    for    (float t = 0.0; t >= -float(trail); t -= inv_detail) {
        // t is the offset back in time to look at where the curve was
        vec2 p0 = get_point(time + t);
        vec2 p1 = get_point(time + t - inv_detail);
        
        float trail_amount = 1.0 + (t / float(trail));

        float dist = point_linesegment_dist(uv, p0, p1);
        float coverage = 1.0 - dist / (float(thickness) * trail_amount);
        coverage *= sqrt(trail_amount); // Fade out the trail
        on_line = max(on_line, coverage);
    }

    vec3 color = mix(vec3(0.0, 0.0, 0.0), vec3(0.5, 1.0, 0.0), on_line);

    glFragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
