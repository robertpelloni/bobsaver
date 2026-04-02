#version 420

// original https://www.shadertoy.com/view/7dKyWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct RayHit {
    bool hit;
    vec3 pos;
    int id;
};

struct ObjectDistance {
    float dist;
    int id;
};

const float pseudoInfty = 3.4e38;
const int boxId = 0;

// Coordinate Transformations
vec3 mengerSponge(vec3 p, int iterations, int step, float t) {
    if (iterations == 0) {
        return p;
    }
    float mirrorPlaneDistance = 3.5;
    mirrorPlaneDistance *= 2.0;
    p = p * 0.5 + 0.5;
    if (step >= 6) {
        if (p.y > mix(mirrorPlaneDistance + 0.5, 0.5, t)) {
            p.y = mix(2.0 * mirrorPlaneDistance + 1.0, 1.0, t) - p.y;
        }
        t = 1.0;
    }
    if (step >= 5) {
        if (p.x > mix(mirrorPlaneDistance + 0.5, 0.5, t)) {
            p.x = mix(2.0 * mirrorPlaneDistance + 1.0, 1.0, t) - p.x;
        }
        t = 1.0;
    }
    if (step >= 4) {
        if (p.z > mix(mirrorPlaneDistance + 0.5, 0.5, t)) {
            p.z = mix(2.0 * mirrorPlaneDistance + 1.0, 1.0, t) - p.z;
        }
        t = 1.0;
    }
    if (step >= 3) {
        if (p.x - mix(mirrorPlaneDistance, 0.0, t) > p.z) {
            p.xz = vec2(p.z + mix(mirrorPlaneDistance, 0.0, t), p.x - mix(mirrorPlaneDistance, 0.0, t));
        }
        t = 1.0;
    }
    if (step >= 2) {
        if (p.y - mix(mirrorPlaneDistance, 0.0, t) > p.z) {
            p.yz = vec2(p.z + mix(mirrorPlaneDistance, 0.0, t), p.y - mix(mirrorPlaneDistance, 0.0, t));
        }
        t = 1.0;
    }
    if (step >= 1) {
        if (p.z > (mix(mirrorPlaneDistance + 1.0, 1.0, t) / 3.0)) {
            p.z = (mix(2.0 * mirrorPlaneDistance + 2.0, 2.0, t) / 3.0) - p.z;
        }
        t = 1.0;
    }
    if (step >= 0) {
        p *= mix(1.0, 3.0, t);
        t = 1.0;
    }
    for (int i = 0; i < iterations - 1; i++) {
        if (p.y > 0.5) {
            p.y = 1.0 - p.y;
        }
        if (p.x > 0.5) {
            p.x = 1.0 - p.x;
        }
        if (p.z > 0.5) {
            p.z = 1.0 - p.z;
        }
        if (p.x  > p.z) {
            p.xz = vec2(p.z, p.x);
        }
        if (p.y > p.z) {
            p.yz = vec2(p.z, p.y);
        }
        if (p.z > (1.0 / 3.0)) {
            p.z = (2.0 / 3.0) - p.z;
        }
        p *= 3.0;
    }
    p = p * 2.0 - 1.0;
    return p;
}

float scaleFactor(int iterations, int step, float t) {
    if (step == 0) {
        return pow(3.0, float(iterations - 1)) * mix(1.0, 3.0, t);
    }
    return pow(3.0, float(iterations));
}

float gain(float x, float k) {
    float a = 0.5 * pow(2.0 * ((x < 0.5) ? x : 1.0 - x), k);
    return (x < 0.5) ? a : 1.0 - a;
}

vec2 gain(vec2 v, float k) {
    return vec2(gain(v.x, k), gain(v.y, k));
}

float sdBox(vec3 pos, vec3 b) {
    vec3 posCorner = abs(pos) - b;
    return length(max(posCorner, 0.0)) + min(max(posCorner.x, max(posCorner.y, posCorner.z)), 0.0);
}

ObjectDistance sceneDistance(vec3 pos) {
    int MAX_ITERATIONS = 7;
    float time = time * 0.9;
    int iterations = int(time) / 8 + 1;
    int step = int(time) % 8;
    float k = 8.0;
    float t = gain(fract(time) * 0.5 + 0.5, k);
    
    if (iterations > MAX_ITERATIONS && fract(time) < 0.5 && int(time) % 8 == 0) {
        iterations = MAX_ITERATIONS + 1;
    } else {
        iterations = min(iterations, MAX_ITERATIONS);
    }
    
    if (step == 0) {
        t = gain(fract(time), k);
    }
    if (step == 7) {
        t = 1.0;
    }
    
    float d = sdBox(mengerSponge(pos, iterations, step, t), vec3(1.0)) / scaleFactor(iterations, step, t);
    return ObjectDistance(d, boxId);
}

RayHit rayMarch(vec3 rayOrigin, vec3 rayDirection) {
    int maxIterations = 512;
    float maxT = 25.0;
    float epsilon = 1.0e-5;
    
    float t = 0.0;
    vec3 pos;
    ObjectDistance objDist;
    for (int i = 0; i <= maxIterations; i++) {
        pos = rayOrigin + t * rayDirection;
        objDist = sceneDistance(pos);
        t += objDist.dist / 4.0;
        if (objDist.dist < epsilon) {
            return RayHit(true, pos, objDist.id);
        }
        if (t > maxT) {
            return RayHit(false, pos, objDist.id);
        }
    }
    return RayHit(false, pos, objDist.id);
}

vec3 calculateNormal(vec3 pos) {
    vec2 epsilon = vec2(1.0e-5, 0.0);
    vec3 normal = vec3(0.0);
    normal.x = sceneDistance(pos + epsilon.xyy).dist - sceneDistance(pos - epsilon.xyy).dist;
    normal.y = sceneDistance(pos + epsilon.yxy).dist - sceneDistance(pos - epsilon.yxy).dist;
    normal.z = sceneDistance(pos + epsilon.yyx).dist - sceneDistance(pos - epsilon.yyx).dist;
    return normalize(normal);
}

vec3 triplanarMap(sampler2D sampler, vec3 n, float k) {
    vec3 w = pow(abs(n), vec3(k));
    vec3 tex = (w.x * texture(sampler, 3.0 * (normalize(n).yz * 0.5 + 0.5)) + 
                w.y * texture(sampler, 3.0 * (normalize(n).zx * 0.5 + 0.5)) + 
                w.z * texture(sampler, 3.0 * (normalize(n).xy * 0.5 + 0.5))).rgb;
    tex /= w.x + w.y + w.z;
    return tex;
}

vec4 render() {
    vec4 glFragColor;
    // Normalized pixel coordinates (from -1 to 1)
    vec2 screenPos = (gl_FragCoord.xy - resolution.xy / 2.0) / max(resolution.y, resolution.x) * 2.0;
    
    float animate = 0.1 * time;
    vec3 cameraPosition = vec3(2.0 * sin(animate), 2.1, 3.0 * cos(animate));
    // vec3 cameraPosition = vec3(1.0, 3.0, 3.0);
    vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
    float fov = radians(100.0);
    
    vec3 rayOrigin = cameraPosition;
    vec3 cameraDirection = normalize(cameraTarget - cameraPosition);
    vec3 screenHorizontal = normalize(vec3(-cameraDirection.z, 0.0, cameraDirection.x));
    vec3 screenVertical = normalize(cross(screenHorizontal, cameraDirection));
    vec3 rayDirection = normalize(tan(fov / 2.0) * screenPos.x * screenHorizontal + tan(fov / 2.0) * screenPos.y * screenVertical + cameraDirection);
    
    vec3 albedo = vec3(1.0);
    vec3 lightDirection = normalize(vec3(2.0, 3.0, 1.0));
    
    RayHit rayHit = rayMarch(rayOrigin, rayDirection);
    
    vec3 normal = calculateNormal(rayHit.pos);
    if (rayHit.id == boxId) {
        albedo = vec3(0.7, 0.2, 1.0) * 1.4;
    }
    vec3 color;
    rayHit = rayMarch(rayHit.pos + 0.0001 * normal, lightDirection);
    if (rayHit.hit) {
        // Shadow
        color = dot(normal, lightDirection) * albedo * albedo * 0.1;
    } else {
        // Light
        color = clamp(dot(normal, lightDirection), 0.0, 1.0) * albedo;
    }
    
    color = clamp(color, 0.0, 1.0);
    // Output to screen
    return vec4(color, 1.0);
}

void main(void) {
    glFragColor = vec4(0.0);
    
    // Set higher if your computer allows:
    int MULTISAMPLE = 1;
    // Samples MULTISAMPLE x MULTISAMPLE so 4 is plenty
    
    for (int x = 0; x < MULTISAMPLE; x++) {
        for (int y = 0; y < MULTISAMPLE; y++) {
            glFragColor += render();
        }
    }
}
