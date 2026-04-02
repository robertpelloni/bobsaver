#version 420

// original https://www.shadertoy.com/view/tlX3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define REFL_COUNT 10
#define WALL_THICKNESS 0.05

const float ico_a = 0.525731;
const float ico_b = 0.850651;

#define ICO_FACES 20
const uvec3 icoIndices[ICO_FACES] = uvec3[ICO_FACES](
    uvec3(0, 1, 4),
    uvec3(0, 6, 1),
    uvec3(2, 5, 3),
    uvec3(2, 3, 7),
    
    uvec3(4, 5, 8),
    uvec3(4, 10, 5),
    uvec3(6, 9, 7),
    uvec3(6, 7, 11),

    uvec3(8, 9, 0),
    uvec3(8, 2, 9),
    uvec3(10, 1, 11),
    uvec3(10, 11, 3),
    
    uvec3(0, 4, 8),
    uvec3(0, 9, 6),
    uvec3(1, 10, 4),
    uvec3(1, 6, 11),
    uvec3(2, 8, 5),
    uvec3(2, 7, 9),
    uvec3(3, 11, 7),
    uvec3(3, 5, 10)
);

// Returns the position of icosahedron vertex of index i
// The vertices of an icosahedron lie on the corners of three rectangles
// that are orthogonal to each other.
vec3 icoVec(uint index) {
    uint i = index / 4u;
    uint j = index - i * 4u;
    float asign = (j & 1u) == 1u ? -1.0 : 1.0;
    float bsign = j >= 2u ? -1.0 : 1.0;
    
    if (i == 0u) {
        return vec3(0.0, asign * ico_a, bsign * ico_b);
    } else if (i == 1u) {
        return vec3(bsign * ico_b, 0.0, asign * ico_a);
    } else { // i == 2
        return vec3(asign * ico_a, bsign * ico_b, 0.0);
    }
}

struct TriangleHit {
    float t;
    vec3 bary;
    vec3 normal;
};
    
const TriangleHit noHit = TriangleHit(1000.0, vec3(0.0), vec3(0.0));

// Möller–Trumbore Ray-triangle intersection algorithm
TriangleHit rayTriHit(vec3 origin, vec3 dir, uvec3 indices) {
    vec3 v1 = icoVec(indices.x);
    vec3 v2 = icoVec(indices.y);
    vec3 v3 = icoVec(indices.z);
    
    vec3 d12 = v2 - v1;
    vec3 d13 = v3 - v1;
    
    vec3 h = cross(dir, d13);
    float a = dot(d12, h);
    float f = 1.0 / a;
    
    vec3 s = origin - v1;
    float u = dot(s, h) * f;
    vec3 q = cross(s, d12);
    float v = dot(dir, q) * f;
    float w = 1.0 - u - v;
    float t = dot(d13, q) * f;
    
    if (t >= 0.0001 && u >= 0.0 && u < 1.0 && v >= 0.0 && w > 0.0) {
        TriangleHit hit;
        hit.t = t;
        hit.bary = vec3(u, v, w);
        hit.normal = normalize(cross(d12, d13));
        return hit;
    }

    return noHit;
}

// Ray - icosahedron intersection, assuming the origin is outside
TriangleHit rayIcoOuterHit(vec3 origin, vec3 dir) {
    for (int i = 0; i < ICO_FACES; i++) {
        TriangleHit hit = rayTriHit(origin, dir, icoIndices[i]);
        if (hit.t <= 10.0 && dot(dir, hit.normal) < 0.0) {
            return hit;
        }
    }
    return noHit;
}

// Ray - icosahedron intersection, assuming the origin is inside
TriangleHit rayIcoInnerHit(vec3 origin, vec3 dir) {
    for (int i = 0; i < ICO_FACES; i++) {
        TriangleHit hit = rayTriHit(origin, dir, icoIndices[i]);
        if (hit.t <= 10.0) return hit;
    }
    return noHit;
}

// Shading of walls, returns reflectivity in alpha
vec4 wallColor(vec3 dir, TriangleHit hit) {
    float d = min(min(hit.bary.x, hit.bary.y), hit.bary.z);
    
    // Texturing of walls
    vec3 albedo = vec3(0.0);//texture(iChannel1, vec2(hit.bary.xy * 2.0)).rgb;
    albedo = pow(albedo, vec3(2.2)) * 0.5;
    
    // Simple diffuse lighting
    float lighting = 0.2 + max(dot(hit.normal, vec3(0.8, 0.5, 0.0)), 0.0);
    
    if (dot(dir, hit.normal) < 0.0) {
        // Outer walls, just add a black line to hide seams
        float f = clamp(d * 1000.0 - 3.0, 0.0, 1.0);
        albedo = mix(vec3(0.01), albedo, f);
        return vec4(albedo * lighting, f);
    } else {
        // Inner walls, add fancy lights
        float m = max(max(hit.bary.x, hit.bary.y), hit.bary.z);
        vec2 a = fract(vec2(d, m) * 40.6) - 0.5;
        float b = 1.0 - sqrt(dot(a, a));
        b = 0.2 / (dot(a, a) + 0.2);
        
        float lightShape = 1.0 - clamp(d * 100.0 - 2.0, 0.0, 1.0);
        lightShape *= b;
        
        vec3 emissive = vec3(3.5, 1.8, 1.0);
        return vec4(mix(albedo * lighting, emissive, lightShape), 0.0);
    }
    return vec4(1.0);
}

// Background cubemap
vec3 background(vec3 dir) {
    vec3 col = vec3(0.0);//texture(iChannel0, dir).rgb;
    col = pow(col, vec3(2.2));
    
    // de-tonemap
    float origLuma = dot(col, vec3(0.2126, 0.7152, 0.0722)) * 0.7;
    return 2.5 * col / (1.0 - origLuma);
}

vec3 drawRay(vec3 origin, vec3 dir) {
    vec3 color = vec3(0.0);
    
    // First test ray intersection with the outer shell
    TriangleHit hit = rayIcoOuterHit(origin, dir);
    if (hit.t > 10.0) {
        return background(dir);
    }
    
    // Render reflections
    vec3 reflDir = reflect(dir, hit.normal);
    vec3 bgColor = pow(background(reflDir), vec3(1.0));
    float fresnel = 0.04 + 0.96 * pow(1.0 - max(dot(dir, -hit.normal), 0.0), 5.0);
    color += bgColor * fresnel;
    
    // Check if we're close enough to the edge of the triangle to render a wall
    float d = min(min(hit.bary.x, hit.bary.y), hit.bary.z);
    if (d < WALL_THICKNESS) {
        vec4 wc = wallColor(dir, hit);
        return color * wc.a + wc.rgb;
    }
    
    // Move origin inside the icosahedron and check inner intersections
    origin = origin + hit.t * dir;
    hit = rayIcoInnerHit(origin, dir);
    vec3 transmittance = vec3(1.0);
    
    // Bounce rays inside the icosahedron until a wall is hit or we run out of iterations
    for (int i = 0; i < REFL_COUNT; i++) {
        float d = min(min(hit.bary.x, hit.bary.y), hit.bary.z);
        if (d < WALL_THICKNESS) {
            return color + transmittance * wallColor(dir, hit).rgb;
        }
        
        origin = origin + hit.t * dir;
        dir = reflect(dir, hit.normal);
        origin += dir * 0.001;
        transmittance *= vec3(0.50, 0.47, 0.38); // Every reflection loses some light
        
        hit = rayIcoInnerHit(origin, dir);
    }
    
    return color;
}

// Returns a 3x3 rotation matrix from a defined forward vector and an up vector
mat3x3 lookAt(vec3 forwardVec, vec3 upVec) {
    vec3 Z = normalize(forwardVec);
    vec3 X = normalize(cross(forwardVec, upVec));
    vec3 Y = normalize(cross(X, forwardVec));

    return mat3x3(X, Y, Z);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5) / resolution.y;
    
    // Camera movement and rotation. It always looks at the origin.
    vec2 movement = vec2(time * 0.2, sin(time * 0.2) * 0.5);

    float cameraRadius = 2.4;
    vec3 cameraPos = cameraRadius * vec3(
        cos(movement.x)*cos(movement.y),
        sin(movement.y),
        sin(movement.x)*cos(movement.y)
    );
    
    vec3 forwardVec = normalize(-cameraPos);
    mat3x3 rotMat = lookAt(forwardVec, vec3(0, 1, 0));
    
    vec3 screenRay = normalize(vec3(uv, 1.0));
    vec3 cameraRay = normalize(rotMat * screenRay);
    
    vec3 color = drawRay(cameraPos, cameraRay);

    // Tonemaping and gamma correction
    color = color / (color * 0.5 + 0.5);
    color = pow(color, vec3(1.0 / 2.2));
    
    // Output to screen
    glFragColor = vec4(color,1.0);
}
