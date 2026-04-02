#version 420

// original https://www.shadertoy.com/view/tlVSWy#

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEPS = 100;
const float DIST_THRESHOLD = 0.001;
const float MAX_DIST = 1000000.0;

vec4 smoothMin(vec4 a, vec4 b, float k) {
    float h = max(0.0, min(1.0, (b.w - a.w) / k + 0.5));
    float m = h * (1.0 - h) * k;
    //return (h * a + (1.0 - h) * b) - m * 0.5;
    return mix(b, a, vec4(h)) - vec4(0.0, 0.0, 0.0, m * 0.5);
}

float sphere(vec3 point, vec3 pos, float radius) {
    return length(point - pos) - radius;
}

float capsule(vec3 point, vec3 a, vec3 b, float radius) {
    vec3 ap = point - a;
    vec3 ab = a - b;
    float t = dot(ap, ab) / dot(ab, ab);
    t = clamp(t, 0.0, 1.0);
    vec3 c = a + t * ab;
    return length(point - c) - radius;
}

float torus(vec3 point, vec3 pos, float radius0, float radius1) {
    point -= pos;
    float x = length(vec3(point.x, 0.0, point.z)) - radius0;
    float y = point.y;
    return length(vec2(x, y)) - radius1;
}

float plane(vec3 point, vec3 p, vec3 n) {    
    return dot(n, point - p);
}

vec3 repeat(vec3 point, vec3 c) {
    return mod(abs(point), c) - 0.50 * c;
}

vec3 cc = vec3(1.0);

vec4 getDist(vec3 point) {
    vec4 dist = vec4(1.0, 1.0, 1.0, MAX_DIST);
    
    // Ceiling, floor
    //vec3 planeColor = vec3(242.0,208.0,106.0)/255.0;
    vec3 planePos[5];
    planePos[0] = vec3(0.0);
    planePos[1] = vec3(0.0, 15.0, 0.0);
    planePos[2] = vec3(100.0, 0.0, 0.0);
    planePos[3] = vec3(0.0, 0.0, -25.0);
    planePos[4] = vec3(0.0, 0.0, 25.0);
    vec3 planeNormal[5];
    planeNormal[0] = vec3(0.0, 1.0, 0.0);
    planeNormal[1] = vec3(0.0, -1.0, 0.0);
    planeNormal[2] = vec3(-1.0, 0.0, 0.0);
    planeNormal[3] = vec3(0.0, 0.0, 1.0);
    planeNormal[4] = vec3(0.0, 0.0, -1.0);
    vec3 c0 = vec3(9.0,23.0,48.0)/210.0;
    vec3 c1 = vec3(1.0,0.0,0.0);
    vec3 planeColor[5];
    planeColor[0] = c0;
    planeColor[1] = c0;
    planeColor[2] = c0;
    planeColor[3] = c1;
    planeColor[4] = vec3(0.0,1.0,0.0);
    for (int i = 0; i < 5; i++) {
        float plane = plane(point, planePos[i], planeNormal[i]);
        dist = smoothMin(dist, vec4(planeColor[i], plane), 5.0);
    }
    float ceiling = plane(point, vec3(100.0, 0.0, 0.0), normalize(vec3(-1.0, 0.0, 0.0)));
    float floor_ = plane(point, vec3(0.0, -0.0, 0.0), normalize(vec3(0.0, 1.0, 0.0)));
    float c = plane(point, vec3(0.0, 15.0, 0.0), normalize(vec3(0.0, -1.0, 0.0)));
    
    // Pillars
    point.xz = repeat(point, vec3(20.0)).xz;
    
    for (int i = 0; i < 2; i++) {
        float y = -1.5 + -4.0 * float(i) + mod(time, 8.0) * 4.0;
        vec4 s = vec4(
            vec3(220.0,103.0,97.0)/255.0,
            sphere(point, vec3(0.0, y, 0.0), 1.0)
        );
        dist = smoothMin(dist, smoothMin(dist, s, 2.0), 0.0);
        //cc = mix(vec3(1.0), vec3(1.0,0.0,0.0),
    }
    
    vec4 t = vec4(
        vec3(76.0,152.0,199.0)/255.0,
        torus(point, vec3(0.0, 0.0, 0.0), 2.0, 0.2)
    );
    dist = smoothMin(dist, t, 1.0);
    
    for (int i = 0; i < 3; i++) {
        float y = 4.0 * float(i) - mod(time, 5.0) * 8.0 + 18.0;
        vec4 t = vec4(
            vec3(76.0,152.0,199.0)/255.0,
            torus(point, vec3(0.0, y, 0.0), 2.0, 0.3)
        );
        dist = smoothMin(dist, t, 8.0);
    }
    
    float y = mod(time, 2.5) * 20.0;
    vec4 s = vec4(
        1.0, 1.0, 0.0,
        sphere(point, vec3(5.0, 30.0 - y, -10.0), 0.5)
    );
    dist = smoothMin(dist, s, 10.0);
    
    return dist;
}

vec4 march(vec3 rayOrigin, vec3 rayDir) {
    vec3 c = vec3(1.0);
    float dist = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 point = rayOrigin + rayDir * dist;
        vec4 d = getDist(point);
        dist += d.w;
        c = d.xyz;
        if (d.w < DIST_THRESHOLD || dist > MAX_DIST) {
            break;
        }
    }
    
    return vec4(c, dist);
}

vec3 getNormal(vec3 point) {
    float dist = getDist(point).w;
    float e = 0.01;
    return normalize(vec3(
        dist - getDist(point - vec3(e, 0, 0)).w,
        dist - getDist(point - vec3(0, e, 0)).w,
        dist - getDist(point - vec3(0, 0, e)).w
    ));
}

vec3 getLighting(vec3 point, vec3 normal, vec3 rayDir) {
    vec3 lights[1];
    lights[0] = vec3(40.0, 5.0, 0.0);
    
    vec3 diff = vec3(0.5);
    for (int i = 0; i < 1; i++) {
        vec3 lightPos = lights[i];
    
        //lightPos.x += sin(time) * 5.0;
        vec3 lightDir = normalize(lightPos - point);
        
        // Diffuse lighting
        diff += max(0.0, dot(lightDir, normal)) * vec3(0.8);

        // Shadow
        float dist = march(point + normal * 0.01, lightDir).w;
        if (dist < length(lightPos - point)) {
            diff *= 0.8;
        }
        
        vec4 c = vec4(0.0);
        for (int i = 0; i < 2; i++) {
            rayDir = normalize(reflect(rayDir, normal));
            vec4 a = march(point + normal * 0.1, rayDir);
            c.xyz += a.xyz;
            c.w = a.w;
            point += rayDir * a.w;
            normal = getNormal(point);
        }
        
        if (c.w < MAX_DIST) {
            return vec3(diff) + c.xyz;
        } else {
            return vec3(diff);
        }
    }
    
    return diff;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    vec3 cameraTarget = vec3(2.0, 2.5, 0.0);
    vec3 cameraPos = vec3(25.0, 10.0, 0.0);
    //vec3 cameraDir = normalize(cameraTarget - cameraPos);
    vec3 cameraDir = normalize(vec3(1.0,0.0,0.0));
    vec3 up = normalize(vec3(0.0, 1.01, 0.0));
    vec3 cameraRight = normalize(cross(cameraDir, up));
    vec3 cameraUp = normalize(cross(cameraRight, cameraDir));
    
    vec3 pixel = cameraPos + cameraDir + cameraRight * uv.x + cameraUp * uv.y;
    vec3 rayDir = normalize(pixel - cameraPos);

    vec3 col = vec3(0);
    
    vec3 rayOrigin = cameraPos;
    vec4 dist = march(rayOrigin, rayDir);
    vec3 point = rayOrigin + rayDir * dist.w;
    
    if (dist.w < MAX_DIST) {
        col = getLighting(point, getNormal(point), rayDir) * dist.xyz;
    }
    
    float viewingDistance = 100.0;
    vec3 fog = mix(vec3(1.0), vec3(0.0), clamp(dist.w, 0.0, viewingDistance) / viewingDistance);
    //col.xyz *= fog;
    
    glFragColor = vec4(col, 1.0);
}
