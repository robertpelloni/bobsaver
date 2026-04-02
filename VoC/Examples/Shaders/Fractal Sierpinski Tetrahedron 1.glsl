#version 420

// original https://neort.io/art/bt0it9c3p9f8mi6u6elg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = acos(-1.0);
const float rot_speed = 1.0; // rotation speed
const float change_speed = 0.2; // change speed of fractal level

mat3 rotate3D(float angle, vec3 axis) {
    vec3 n = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        n.x * n.x * r + c,
        n.x * n.y * r - n.z * s,
        n.z * n.x * r + n.y * s,
        n.x * n.y * r + n.z * s,
        n.y * n.y * r + c,
        n.y * n.z * r - n.x * s,
        n.z * n.x * r - n.y * s,
        n.y * n.z * r + n.x * s,
        n.z * n.z * r + c
    );
}

// Tetrahedron of side length a by Kamoshika
float sdIsoTetrahedron(vec3 p, float a) {
    float h = sqrt(6.0) / 12.0 * a;
    float d1 = dot(p, normalize(vec3(-1.0, -1.0, -1.0))) - h;
    float d2 = dot(p, normalize(vec3(1.0, 1.0, -1.0))) - h;
    float d3 = dot(p, normalize(vec3(-1.0, 1.0, 1.0))) - h;
    float d4 = dot(p, normalize(vec3(1.0, -1.0, 1.0))) - h;
    float dBox = length(max(abs(p) - sqrt(2.0) / 4.0 * a, 0.0));
    
    return max(max(max(max(dBox, d1), d2), d3), d4);
}

// https://qiita.com/aa_debdeb/items/bffe5b7a33f5bf65d25b
// The code has been changed.
const float max_iterations = 10.0;
const float iterations = 6.0;
float deRecursiveTetrahedron(vec3 p, float offset, float scale) {
    float coeff = 1.0;
    vec3 z = p;
    for(float i = 1.0; i < max_iterations + 1.0; i++) {
        if(fract(time * change_speed) < i / (iterations + 1.0)) {
            break;
        }
        
        if(z.x + z.y < 0.0) {
            z.xy = -z.yx;
        }
        if(z.y + z.z < 0.0) {
            z.yz = -z.zy;
        }
        if(z.z + z.x < 0.0) {
            z.zx = -z.xz;
        }
        
        z *= scale;
        coeff *= scale;
        z -= offset * (scale - 1.0);
    }
    return sdIsoTetrahedron(z, offset * 2.0 * sqrt(2.0)) / coeff;
}

float distFunc(vec3 p) {
    return deRecursiveTetrahedron(p, 1.5, 2.0);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    
    vec3 cPos = vec3(0.0, 0.3, 5.0);
    vec3 cDir = vec3(0.0, 0.0, -1.0);
    
    const float angle1 = asin(2.0 / sqrt(6.0));
    const vec3 axis1 = vec3(1.0, 0.0, -1.0);
    float angle2 = time * rot_speed;
    vec3 axis2 = vec3(-1.0, 1.0, -1.0);
    
    cPos *= rotate3D(-angle1, axis1);
    cPos *= rotate3D(-angle2, axis2);
    
    const float fov = 60.0 * 0.5 * pi / 180.0;
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));
    ray *= rotate3D(-angle1, axis1);
    ray *= rotate3D(-angle2, axis2);
    
    float distance = 0.0;
    vec3 rPos = cPos;
    for(int i = 0; i < 64; i++) {
        distance = distFunc(rPos);
        if(abs(distance) < 0.0001) {
            glFragColor = vec4(vec3(4.0 / float(i) + 0.2), 1.0);
            return;
        }
        rPos += ray * distance;
    }
    glFragColor = vec4(vec3(0.1), 1.0);
}
