#version 420

// original https://www.shadertoy.com/view/Nddczr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define AA 1

// If you have a strong PC, make it bigger.
#define AA 3

const float sqrt3 = sqrt(3.);
const float PI = acos(-1.);
const float PI2 = acos(-1.) * 2.;

float hash12(in vec2 v) {
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rotate2D(in float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, s, -s, c);
}

vec3 render(in vec2 p) {
    vec3 col = vec3(0);
    
    float scale = 3.;
    
    // Log-polar coordinates.
    p = vec2(log(length(p)) - time * 0.5, atan(p.y, p.x));
    p *=  sqrt3 / PI * scale * 0.5;
    
    // Hexagonal tiling.
    vec2 c = normalize(vec2(1, sqrt3));
    vec2 h = c * 0.5;
    vec2 a = mod(p, c) - h;
    vec2 b = mod(p - h, c) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    
    //vec2 ID = floor(mod(p - g + 1e-4, s * scale) / h);
    p = p - g + 1e-4;
    p.y = mod(p.y, sqrt3 * scale);
    vec2 ID = floor(p / h);
    
    float n = floor(hash12(ID) * 3.);
    g *= rotate2D(n * PI / 3.);
    g.y = abs(g.y);
    float d = g.y;
    g.y -= 0.5 / sqrt3;
    
    float e;
    if(g.y > -0.375 / sqrt3) {
        // Circle.
        e = atan(g.y, g.x) * 9.;
    } else {
        // Line.
        e = (0.75 - g.x * 10.) * PI2;
    }
    
    d = min(d, abs(length(g) - 0.25 / sqrt3));
    col += vec3(1) * smoothstep(0.08, 0., d);
    
    float dir = sign(mod(n, 2.) - 0.5); // Direction of movement.
    col *= sin(e - dir * time * 9.) * 0.4 + 0.6;
    
    return col;
}

void main(void)
{
    vec3 col = vec3(0);
    
    // Anti-aliasing.
    for(int m = 0; m < AA; m++) {
        for(int n = 0; n < AA; n++) {
            vec2 of = vec2(m, n) / float(AA) - 0.5;
            vec2 p = ((gl_FragCoord.xy + of) * 2. - resolution.xy) / min(resolution.x, resolution.x);
            col += render(p);
        }
    }
    col /= float(AA * AA);
    
    glFragColor = vec4(col, 1.0);
}
