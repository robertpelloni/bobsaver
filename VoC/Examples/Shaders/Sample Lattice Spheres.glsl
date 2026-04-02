#version 420

// original https://neort.io/art/bucmaes3p9f7gige8tl0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = acos(-1.);

float rand(in vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

mat3 rotate3D(in float angle, in vec3 axis) {
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

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y) * 1.5;
    p += time * 0.5;
    vec3 color = vec3(0);
    
    vec2 id1 = floor(p + 0.5);
    p -= id1;
    
    vec3 cPos = vec3(0, 0, 5);
    float targetDepth = 2.5;
    vec3 ray = normalize(vec3(p * 1.58, -targetDepth));
    vec3 lightDir = normalize(vec3(-1, 1, 2));
    float radius = 1.5;
    
    float b = dot(cPos, ray);
    float ray2 = dot(ray, ray);
    float D = b*b - (dot(cPos,cPos) - radius*radius) * ray2;
    if(D > 0.) {
        float coef = (-b - sqrt(D)) / ray2;

        vec3 rPos = cPos + ray * coef;
        vec3 normal = normalize(rPos);
        float s = dot(lightDir, normal);
        float diff = max(s, 0.1);
        float spec = pow(max(s, 0.), 40.);
        vec2 scale = vec2(32., 16.);

        float v1 = rand(id1);
        rPos *= rotate3D(time + 2.*pi*v1, vec3(-1));

        float phi = acos(rPos.z/length(rPos.zx)) / pi * 0.5 * scale.x;
        float theta = acos(rPos.y/radius);
        if(rPos.x < 0.) {
            theta = 2.*pi - theta;
        }
        theta *= 1./pi * scale.y;
        vec2 uv = vec2(phi, theta);
        vec2 id2 = floor(uv);
        uv -= id2;
        if(uv.y > uv.x) {
            uv = uv.yx;
        }
        float d = min(1.0 - uv.x, uv.y);
        float v2 = rand(id2 + v1);
        
        vec3 base = vec3(0.5, v2, v1);
        base *= mix(0., 10., d) * v2;
        base += 0.01 / d;
        color = base * diff + spec;
    } else {
        color = vec3(0.2);
    }
    
    glFragColor = vec4(color, 1.);
}
