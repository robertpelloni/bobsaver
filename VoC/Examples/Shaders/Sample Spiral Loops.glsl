#version 420

// original https://neort.io/art/br0eb4c3p9f48fkiuh2g

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;
            
vec3 lightDir = normalize(vec3(1.,1.,1.));

vec3 rotate(vec3 p, float angle, vec3 axis) {
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

float spiral(vec3 p) {
    p.xy *= mat2(sin(vec4(0,11,11,0)));
    p.yz *= mat2(sin(vec4(0,11,11,0)));
    float l = length(p.xy);
    float d = sin(atan(p.y, p.x)-p.z);
    float dist = length(vec2(l-3.,d)) - 0.1;
    return dist;
}

float sceneDist(vec3 p) {
    vec3 q = rotate(p,50.,vec3(1.,-4.4,1.3));
    float s2 = spiral(vec3(q.x + time,q.y-4.,q.z-50.));
    q = rotate(p,50.,vec3(0.5,1.,1.));
    float s3 = spiral(vec3(q.x + time,q.y-10.,q.z-30.));
    q = rotate(p,150.,vec3(0.5,0.5,1.));
    float s4 = spiral(vec3(q.x + time,q.y-10.,q.z-30.));
    q = rotate(p,50.,vec3(0.5,0.8,0.9));
    float s5 = spiral(vec3(q.x + time,q.y,q.z-40.));
    q = rotate(p,90.,vec3(0.5,0.4,1.));
    float s6 = spiral(vec3(q.x + time,q.y,q.z-50.));
    q = rotate(p,30.,vec3(1.,10.,-1.));
    float s7 = spiral(vec3(q.x + time,q.y + 7.,q.z-20.));
    q = rotate(p,46.,vec3(0.7,1.,1.));
    float s8 = spiral(vec3(q.x + time + 3.,q.y,q.z-40.));
    q = rotate(p,140.,vec3(1.,1.,1.));
    float s9 = spiral(vec3(q.x + time,q.y+15.,q.z-30.));

    return min(min(min(min(min(min(min(s2,s3),s4),s5),s6),s7),s8),s9);
}

const float EPS = 0.01;
vec3 getNormal(vec3 p) {
    return normalize(vec3(
        sceneDist(p + vec3(EPS,0.,0.)) - sceneDist(p + vec3(-EPS,0.,0.)),
        sceneDist(p + vec3(0.,EPS,0.)) - sceneDist(p + vec3(0.,-EPS,0.)),
        sceneDist(p + vec3(0.,0.,EPS)) - sceneDist(p + vec3(0.,0.,-EPS))
    ));
}

vec4 spiralLoop(vec2 uv) {
    vec3 ro = vec3(0.,0.,-5.);

    float screenZ = 4.;
    vec3 rd = normalize(vec3(uv, screenZ));

    float d = 0.0;
    vec3 col = vec3(0.95);

    for (int i=0; i<60; i++) {
        vec3 rayPos = ro + rd * d;
        float dist = sceneDist(rayPos);

        if(dist < 0.1) {
            d += dist;
            rayPos = ro + rd * d;
            vec3 normal = getNormal(rayPos);
            float diff = dot(normal, lightDir);
            col = vec3(diff);
            break;
        }

        d += dist;
    }

    return vec4(col, 1.0);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    glFragColor = spiralLoop(uv);
    return;
}
