#version 420

// original https://www.shadertoy.com/view/NsBXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 1000.0
#define MIN_DIST 0.01

// 2D matrix rotation
vec2 rot(vec2 p, float a) {
    return (p * mat2(cos(a), -sin(a), sin(a), cos(a)));
}

// Hexagon SDF by iq
float Hexagon(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404,0.5,0.577350269);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

// SDFs of the objects in the scene
float Dist(vec3 point) {
    // Strand 1
    vec2 sqp1 = mod(abs(point.xz), 20.0)-vec2(10, 10);
    sqp1 = rot(sqp1, point.y/2.0) + 0.3;
    float c1 = Hexagon(sqp1, 1.0);
    // Strand 2
    vec2 sqp2 = mod(abs(point.yz+10.0), 20.0)-vec2(10, 10);
    sqp2 = rot(sqp2, point.x/4.0) + 0.3;
    float c2 = Hexagon(sqp2, 1.0);
    // Strand 3
    vec2 sqp3 = mod(abs(point.xy+vec2(10,0)), 20.0)-vec2(10, 10);
    sqp3 = rot(sqp3, point.z/4.0) + 0.3;
    float c3 = Hexagon(sqp3, 1.0);
    return min(min(c1,c2),c3);
}

vec2 RayMarch (vec3 cameraOrigin, vec3 rayDirection) {
    float minDist = 0.0;
    int steps = 0;
    while (steps < MAX_STEPS) {
        vec3 point = cameraOrigin + rayDirection * minDist;
        float dist = Dist(point);
        minDist += dist;
        if (dist < MIN_DIST || abs(minDist) > MAX_DIST) {
            break;
        }
        steps++;
    }
    return vec2(minDist, steps);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/(resolution.y);
    uv -= vec2(resolution.x/resolution.y/2.0, 0.5);
    vec3 cameraPosition = vec3(0, 5.0, 0);
    cameraPosition.xy = rot(cameraPosition.xy, 0.0);
    cameraPosition.z += time*10.0;
    cameraPosition.x += time*4.0;
    cameraPosition.y += 10.0;
    vec3 ray = normalize(vec3(uv.x,uv.y, 0.5));
    ray.xz = rot(ray.xz, time/5.0);
    ray.xy = rot(ray.xy, -time/5.0);
    vec2 march = RayMarch(cameraPosition, ray);
    vec3 rayPoint = cameraPosition + march.x * ray;
    vec3 col = mix(vec3(0), mix(vec3(0.9, 0.5, 0.6), vec3(0.5, 0.5, 1.0), sin(time/10.0)*0.5+0.5),march.y/50.0);
    //vec3 col = mix(vec3(0), mix(vec3(0.9, 0.5, 0.6), vec3(0.5, 0.5, 1.0), sin(time/10.0)*0.5+0.5),1.-march.y/50.0);
    glFragColor = vec4(col,1.0);
}
