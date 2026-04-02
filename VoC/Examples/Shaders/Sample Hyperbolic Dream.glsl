#version 420

// original https://neort.io/art/bsekn0k3p9f6ochicpu0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// This code generates Poincare disk (hyperbolic tessellation) represented by Schlafli symbol {n1, n2}.
// The original triangle consists of straight line L1, L2, and circle C.

const float pi = acos(-1.0);

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

void main() {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    float t = time / 2.0;
    p *= atan(1.0 - fract(t), 2.0) * 5.0;
    
    float r1 = hash(floor(t));
    float r1o = hash(floor(t) - 1.0);
    float r2 = hash(r1);
    float r3 = hash(r2);
    
    float n1 = floor(3.0 + r1 * 8.0);
    float n1o = floor(3.0 + r1o * 8.0);
    if(abs(n1 - n1o) < 0.1) {
        n1 = 10.0 + floor(pow(2.0, r2 * 6.0));
    }
    float n2 = floor(floor(4.0 / (n1 - 2.0)) + 2.0 + pow(2.0, r3 * 5.0));
    
    float angle1 = pi / n1; // Angle between line L1 and L2
    float angle2 = pi / n2; // Angle of intersection between line L2 and circle C
    
    float coeff = 1.0 / sqrt(cos(angle2) * cos(angle2) - sin(angle1) * sin(angle1));
    float R = sin(angle1) * coeff; // Radius of circle C
    vec2 c = vec2(cos(angle2) * coeff, 0); // Center coordinates of circle C
    
    // Inversion about unit circle
    if(dot(p, p) > 1.0) {
        p = p / dot(p, p);
    }
    
    // Repeat inversions until p reaches the region of the original triangle
    for(int i = 0; i < 100; i++) {
        if(p.y < 0.0) {
            // Inversion about line L1
            p.y *= -1.0;
        }
        else if(p.y > tan(angle1) * p.x) {
            // Inversion about line L2
            float theta2 = angle1 * 2.0;
            p *= mat2(cos(theta2), sin(theta2), sin(theta2), -cos(theta2));
        }
        else if(length(p - c) < R) {
            // Inversion about circle C
            p = (p - c) * R * R / dot(p - c, p - c) + c;
        } else {
            float u = abs(sin((atan(p.x, p.y) - length(p) * 5.0) * 7.0) * 0.5) + 0.3;
            float s = 0.01 / abs(u - length(p));
            glFragColor = vec4(vec3(s), 1.0) + texture2D(backbuffer, gl_FragCoord.xy / resolution) * 0.9;
            return;
        }
    }
}
