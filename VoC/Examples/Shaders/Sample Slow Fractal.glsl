#version 420

// original https://www.shadertoy.com/view/4ldyDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float sdf(vec3 p) {
    p = abs(p);
    for (float i = 0.; i < 5.; i++) {
        p -= 3.;
        vec3 q = vec3(0., atan(p.y, p.x), length(p));
        q.x = asin(p.z / q.z);
        q.xy += q.z * 0.35;
        p = vec3(cos(q.x)*cos(q.y), cos(q.x)*sin(q.y), sin(q.x)) * q.z;
        p = abs(p);
    }
    return sphere(p - vec3(2., 2., 1.), 1.);
}

vec3 gradient(vec3 p, float dist) {
    vec2 eps = vec2(0.005, 0.);
    float dx = sdf(p + eps.xyy) - dist;
    float dy = sdf(p + eps.yxy) - dist;
    float dz = sdf(p + eps.yyx) - dist;
    return normalize(vec3(dx, dy, dz));
}

float ambientOcclusion(vec3 p, vec3 normal, float steps, float dist) {
    float r = 0.;
    for (float i = 0.; i < steps; i++) {
        float d = i / steps * dist;
        float a = sdf(p + d * normal);
        r = abs(a/d);
    }
    return r / steps;
}

float translucency(vec3 p, vec3 normal, float steps, float dist) {
    float r = 0.;
    for (float i = 0.; i < steps; i++) {
        float d = i / steps * dist;
        float a = -sdf(p - d * normal);
        r = abs(a/d);
    }
    return 1. - r / steps;
}

void animateCam(out vec3 camPos, inout vec3 dir) {
    const float part1 = 20.;
    const float part2 = 2.;
    const float part3 = 10.;
    const float part4 = 10.;
    const float part5 = 2.;
    const float part6 = 8.;
    const float part7 = 2.;
    const float total = part1 + part2 + part3 + part4 + part5 + part6 + part7;
    float time = mod(time, total);
    if (time <= part1) {
        camPos = vec3(sin(time / part1 * 6.28) * 1.2, 0., fract(time / part1) * 15. - 10.);
        return;
    }
    time -= part1;
    if (time < part2) {
        camPos = vec3(0., 0., 5.);
        float a = fract(time / part2) * 1.57;
        dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;
        return;
    }
    time -= part2;
    if (time < part3) {
        camPos = vec3(0., 0., 5.);
        float a = fract(time / part3) * 1.57 + 1.57;
        dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;
        camPos -= vec3(10., 0., 2.) * fract(time / part3);
        return;
    }
    time -= part3;
    if (time < part4) {
        float a = 3.14;
        dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;
        a = fract(time / part4);
        camPos = vec3(-10., 0., 3.) - a * vec3(-sin(a *6.28) * 1. - 2., 0., 13.);
        return;
    }
    time -= part4;
    if (time < part5) {
        camPos = vec3(-8., 0., -10.);
        float a = 3.14 + fract(time/part5) * 1.57;
        dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;
        return;
    }
    time -= part5;
    if (time < part6) {
        float a = fract(time/part6);
        camPos = vec3(-8., 0., -10.) + a * vec3(8., 0., sin(3.14 * sqrt(a)));
        a = 4.71;
        dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;
        return;
    }
    time -= part6;
    camPos = vec3(0., 0., -10.);
    float a = 4.71 + 1.57 * fract(time/part7);
    dir.xz = mat2(cos(a), sin(a), -sin(a), cos(a)) * dir.xz;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 dir = vec3(uv, 1./tan(radians(90.) * .5));
    dir = normalize(dir);
    vec3 camPos = vec3(0.);
    animateCam(camPos, dir);
    
    float dist;
    float t = 0.;
    float i = 0.;
    vec3 p;
    bool hit = false;
    float stepSize = 0.025;
    for (; i < 1000.; i++) {
        p = t * dir + camPos;
        dist = sdf(p);
        if (abs(dist) < 0.005) {
            hit = true;
            break;
        }
        t += dist * stepSize;
        if (t > 100.)
            break;
    }
    
    vec3 col = vec3(0.);
    if (hit) {
        vec3 normal = gradient(p, dist);

        vec3 lightDir = vec3(1.);
        float diffuse = max(0.2, dot(normal, lightDir)) * 0.6;
        vec3 lighting = vec3(0.2);
        lighting += diffuse;
        float translucent = translucency(p, normal, 5., .05);
        float diffuseBack = max(0., dot(-normal, lightDir) * translucent) * 0.4;
        lighting += diffuseBack;
        vec3 camDir = normalize(camPos - p);
        float specular = pow(max(dot(normalize(camDir + lightDir), normal), 0.), 16.) * 0.6;
        lighting += specular;
        float rim = 1. - abs(dot(camDir, normal));
        lighting += rim * rim * .3;
        float ao = ambientOcclusion(p, normal, 3., 1.);
        lighting *= .3 + .7 * ao;

        col = mix(vec3(0., 1., 1.), vec3(0., 0., 1.), i/300.);
        col = mix(col, vec3(0., 1., 0.), t / 100.) * lighting;
    }
    glFragColor = vec4(col, 1.);
}
