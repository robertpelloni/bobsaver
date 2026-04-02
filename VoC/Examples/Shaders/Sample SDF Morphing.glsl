#version 420

// original https://www.shadertoy.com/view/3dVyWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
This shader uses my Raymarcher Template shader (https://www.shadertoy.com/view/3styDs).
*/

// Default (background) color:
vec3 backgroundColor = vec3(0.0, 0.0, 0.0);

// Light variables:
vec3 lightDirection = vec3(-0.58, 0.58, 0.58);
vec3 lightColor = vec3(1.0, 1.0, 1.0);

// Camera variables:
vec3 cameraPosition = vec3(0.0, 0.0, 1000.0);
vec3 cameraRight = vec3(1.0, 0.0, 0.0);
vec3 cameraUp = vec3(0.0, 1.0, 0.0);
vec3 cameraForward = vec3(0.0, 0.0, -1.0);
float cameraFocalLength = 400.0;

// Ray marching constants:
const vec3 GRADIENT_STEP = vec3(0.001, 0.0, 0.0);
const float MAX_TRACE_DISTANCE = 2000.0;
const float MIN_HIT_DISTANCE = 0.001;
const int MAX_STEPS = 500;

// Signed Distance Functions (SDFs):
float udPlane(in vec3 p, in vec3 n) {
    return abs(dot(n, normalize(p))) * length(p);
}

float sdCuboid(in vec3 p, in float h, in float w, in float d) {
    return max(abs(p.x) - 0.5 * w, max(abs(p.y) - 0.5 * h, abs(p.z) - 0.5 * d));
}

float sdCylinder(in vec3 p, in float h, in float r) {
    return max(abs(p.y) - 0.5 * h, length(p.xz) - r);
}

float sdTorus(in vec3 p, in float r1, in float r2) {
    return length(vec2(length(p.xz) - r1, p.y)) - r2;
}

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

// Constructive Solid Geometry (CSG) Operators:
float Union(in float sdf1, in float sdf2) {
    return min(sdf1, sdf2);
}

float Subtraction(in float sdf1, in float sdf2) {
    return max(sdf1, -sdf2);
}

float Intersection(in float sdf1, in float sdf2) {
    return max(sdf1, sdf2);
}

// Transformations:
vec3 Translate(in vec3 p, in vec3 t) {
    return p - t;
}

vec3 Rotate(in vec3 p, in vec3 r) {
    vec3 rad = radians(-r);
    vec3 cosRad = cos(rad);
    vec3 sinRad = sin(rad);

    mat3 xRotation = mat3(1.0,      0.0,       0.0,
                          0.0, cosRad.x, -sinRad.x,
                          0.0, sinRad.x,  cosRad.x);

    mat3 yRotation = mat3( cosRad.y, 0.0, sinRad.y,
                                0.0, 1.0,      0.0,
                          -sinRad.y, 0.0, cosRad.y);

    mat3 zRotation = mat3(cosRad.z, -sinRad.z, 0.0,
                          sinRad.z,  cosRad.z, 0.0,
                               0.0,       0.0, 1.0);

    return zRotation * yRotation * xRotation * p;
}

vec3 Scale(in vec3 p, in vec3 s) {
    return p / s;
}

// Scene mapping function:
float mapScene(in vec3 p) {
    p = Rotate(p, vec3(vec2(time * 20.0), 0.0));
    float interpVal = 1.5 + sin(time * 0.5) * 1.5;
    float cube = sdCuboid(p, 200.0, 200.0, 200.0);
    float cylinder = sdCylinder(p, 200.0, 100.0);
    float torus = sdTorus(p, 100.0, 50.0);
    float sphere = sdSphere(p, 100.0);
    float shape1 = cube;
    float shape2 = cylinder;
    if (interpVal >= 1.0 && interpVal < 2.0) {
        interpVal -= 1.0;
        shape1 = cylinder;
        shape2 = torus;
    }

    if (interpVal >= 2.0 && interpVal <= 3.0) {
        interpVal -= 2.0;
        shape1 = torus;
        shape2 = sphere;
    }

    return mix(shape1, shape2, interpVal);
}

// Normal calculation function (using gradient):
vec3 calculateNormal(in vec3 p) {
    float gradientX = mapScene(p + GRADIENT_STEP.xyy) - mapScene(p - GRADIENT_STEP.xyy);
    float gradientY = mapScene(p + GRADIENT_STEP.yxy) - mapScene(p - GRADIENT_STEP.yxy);
    float gradientZ = mapScene(p + GRADIENT_STEP.yyx) - mapScene(p - GRADIENT_STEP.yyx);
    return normalize(vec3(gradientX, gradientY, gradientZ));
}

// Material calculation functions:
vec3 calculateAmbient(in vec3 p, in vec3 normal) {
    return 0.5 + 0.5 * normal;
}

vec3 calculateDiffuse(in vec3 p, in vec3 normal) {
    return vec3(0.0, 0.0, 0.0);
}

vec3 calculateSpecular(in vec3 p, in vec3 normal) {
    return vec3(0.0, 0.0, 0.0);
}

float calculateShininess(in vec3 p, in vec3 normal) {
    return 0.0;
}

// Raymarching loop:
vec4 rayMarch(in vec3 ro, in vec3 rd) {
    float distanceTraveled = 0.0;
    for (int iterations=0; iterations < MAX_STEPS; ++iterations) {
        vec3 currentPosition = ro + rd * distanceTraveled;
        float distanceToClosest = mapScene(currentPosition);
        if (distanceToClosest < MIN_HIT_DISTANCE) {
            vec3 normal = calculateNormal(currentPosition);

            // Illumination is calculated using the Phong illumination model.
            vec3 materialAmbient = calculateAmbient(currentPosition, normal);
            vec3 materialDiffuse = calculateDiffuse(currentPosition, normal);
            vec3 materialSpecular = calculateSpecular(currentPosition, normal);
            float materialShininess = calculateShininess(currentPosition, normal);

            vec3 illuminationAmbient = materialAmbient * lightColor;
            float lambertian = max(0.0, dot(normal, lightDirection));
            vec3 illuminationDiffuse = lambertian * materialDiffuse * lightColor;
            vec3 reflection = reflect(lightDirection, normal);
            float specularAngle = max(0.0, dot(reflection, rd));
            vec3 illuminationSpecular = pow(specularAngle, materialShininess) * materialSpecular * lightColor;

            return vec4(illuminationAmbient + illuminationDiffuse + illuminationSpecular, 1.0);
        }

        if (distanceTraveled > MAX_TRACE_DISTANCE) {
            break;
        }

        distanceTraveled += distanceToClosest;
    }

    return vec4(backgroundColor, 1.0);
}

// Pixel shader output function:
void main(void) {
    vec2 halfResolution = 0.5 * resolution.xy;
    vec2 xy = gl_FragCoord.xy - halfResolution;
    vec3 rayOrigin = cameraPosition + cameraForward * cameraFocalLength;
    vec3 rayDirection = normalize(rayOrigin - (cameraPosition - cameraRight * xy.x - cameraUp * xy.y));
    glFragColor = rayMarch(rayOrigin, rayDirection);
}
