#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WtXXWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

/**
 * Based heavily on jlfwong's excellent raymarching tutorials
 * and some very helpful hints from the Shadertoy Community on Facebook,
 * this is my first venture into Shadertoy and raymarching.
 *
 * Please feel free to share your comments, I'm sure I've got the math
 * wrong in a number of places as most of it was figured out simply
 * by changing things until it seemed to work :-P
 *
 * My use of 4x4 matrices to describe transforms are there
 * to get the polar texture coordinates right. This required a lot
 * of rewriting and there's probably a simpler way...
 */

float sphere(vec4 p, float r) {
    return length(p.xyz) - r;
}

/** Normalize angles to -PI..PI range
 * WebGL seems to disagree when theta becomes too big or too small?
 */
const float PI = 3.1415;
const float TWO_PI = PI * 2.0;

float n_theta(float theta) {
    return theta - TWO_PI * floor((theta + PI) / TWO_PI);
}

float n_sin(float theta) {
    return sin(n_theta(theta));
}

float n_cos(float theta) {
    return cos(n_theta(theta));
}

/* 4x4 matrix funxtions */

mat4 m_rotateX(float r) {
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, n_cos(r), n_sin(r)*-1.0, 0.0,
        0.0, n_sin(r), n_cos(r), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 m_rotateY(float r) {
    return mat4(
        n_cos(r), 0.0, n_sin(r), 0.0,
        0.0, 1.0, 0.0, 0.0,
        n_sin(r)*-1.0, 0.0, n_cos(r), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 m_rotateZ(float r) {
    return mat4(
        n_cos(r), n_sin(r)*-1.0, 0.0, 0.0,
        n_sin(r), n_cos(r), 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 m_translate(vec3 v) {
    return mat4(
        1.0, 0.0, 0.0, v.x,
        0.0, 1.0, 0.0, v.y,
        0.0, 0.0, 1.0, v.z,
        0.0, 0.0, 0.0, 1.0
    );
}

/** 
/**
 * SDF scene definition
 */
float scene(vec4 sp, inout mat4 matrix, inout vec4 color) {
    float dist = MAX_DIST;
    float d = MAX_DIST;
    mat4 m = mat4(1.0); // Don't move/rotate camera here, see definition of "eye" in main()
    vec4 c = vec4(0.0, 0.0, 0.0, 0.0); // Will be replaced by object color (or discarded). 4th component = EMISSIVE yes/no, not ALPHA

    // Add a red shape
    m = m_translate(vec3(2.0, n_sin(time*5.0)*0.5, 0.0)) * m_rotateY(n_sin(time)*PI);
    c = vec4(1.0, 0.2, 0.2, 0.0);
    d = sphere(sp*m, 1.0);
    if (abs(d) < abs(dist)) { dist = d; matrix = m; color = c; }

    // Add a green shape
    m = m_translate(vec3(0.0, n_cos(time*5.0)*0.5, 0.0)) * m_rotateX((time+n_sin(time))*3.0);
    c = vec4(0.2, 1.0, 0.2, 0.0);
    d = sphere(sp*m, 1.0);
    if (abs(d) < abs(dist)) { dist = d; matrix = m; color = c; }

    // Add a blue shape
    m = m_translate(vec3(-2.0, n_sin(time*5.0)*0.5, 0.0)) * m_rotateZ(n_cos(time)*PI*-1.0);
    c = vec4(0.0, 0.2, 1.0, 0.0);
    d = sphere(sp*m, 1.0);
    if (abs(d) < abs(dist)) { dist = d; matrix = m; color = c; }

    // Visualize light sources as small spheres

    // Light1
    m = m_translate(vec3(-3.0 * n_sin(time),
                         -1.0,
                         -3.0 * n_cos(time))); // Matches light1Pos moveent
    c = vec4(0.6, 0.3, 0.3, 1.0); // alpha 1.0 = emissive
    d = sphere(sp*m, 0.05);
    if (abs(d) < abs(dist)) { dist = d; matrix = m; color = c; }

    // Light2
    m = m_translate(vec3(-2.0 * n_sin(0.37 * time),
                          -2.0 * n_cos(0.37 * time),
                          -2.0)); // Matches light2Pos movement
    c = vec4(0.3, 0.6, 0.3, 1.0); // alpha 1.0 = emissive
    d = sphere(sp*m, 0.05);
    if (abs(d) < abs(dist)) { dist = d; matrix = m; color = c; }

    // Light3
    m = m_translate(vec3(-2.0 * n_sin(0.17 * time),
                          -2.0 * n_cos(0.43 * time),
                          -2.0)); // Matches light3Pos movement
    c = vec4(0.3, 0.3, 0.6, 1.0); // alpha 1.0 = emissive
    d = sphere(sp*m, 0.05);
    if (abs(d) < abs(dist)) { dist = d; matrix = m; color = c; }

    return dist;
}

float shortestDistanceToSurface(vec4 eye, vec4 marchingDirection, float start, float end, inout mat4 matrix, inout vec4 color) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = scene(eye + depth * marchingDirection, matrix, color);
        if (dist < EPSILON) {
                  return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec4 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec4(xy, -z, 1.0));
}

/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec4 p) {
    mat4 m = mat4(1.0); // Returned by scene, unused here
    vec4 c = vec4(0.0, 0.0, 0.0, 0.0); // Returned by scene, unused here
    return normalize(vec3(
        scene(vec4(p.x + EPSILON, p.y, p.z, 1.0), m, c) - scene(vec4(p.x - EPSILON, p.y, p.z, 1.0), m, c),
        scene(vec4(p.x, p.y + EPSILON, p.z, 1.0), m, c) - scene(vec4(p.x, p.y - EPSILON, p.z, 1.0), m, c),
        scene(vec4(p.x, p.y, p.z  + EPSILON, 1.0), m, c) - scene(vec4(p.x, p.y, p.z - EPSILON, 1.0), m, c)
    ));
}

/**
 * Lighting contribution of a single point light source via Phong illumination.
 *
 * The vec3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec4 eye, vec3 normal,
                          vec3 lightPos, vec3 lightIntensity) {
    vec3 N = normal;
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye.xyz - p);
    vec3 R = normalize(reflect(-L, N));

    float dotLN = dot(L, N);
    float dotRV = dot(R, V);

    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    }

    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

/**
 * Lighting via Phong illumination.
 *
 * The vec3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec4 eye, vec3 normal) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;

    vec3 light1Pos = vec3(3.0 * n_sin(time),
                          1.0,
                          3.0 * n_cos(time));
    vec3 light1Intensity = vec3(0.6, 0.3, 0.3);

    color += phongContribForLight(k_d, k_s, alpha, p, eye, normal,
                                  light1Pos,
                                  light1Intensity);

    vec3 light2Pos = vec3(2.0 * n_sin(0.37 * time),
                          2.0 * n_cos(0.37 * time),
                          2.0);
    vec3 light2Intensity = vec3(0.3, 0.6, 0.3);

    color += phongContribForLight(k_d, k_s, alpha, p, eye, normal,
                                  light2Pos,
                                  light2Intensity);

    vec3 light3Pos = vec3(2.0 * n_sin(0.17 * time),
                          2.0 * n_cos(0.43 * time),
                          2.0);
    vec3 light3Intensity = vec3(0.3, 0.3, 0.6);

    color += phongContribForLight(k_d, k_s, alpha, p, eye, normal,
                                  light3Pos,
                                  light3Intensity);
    return color;
}

/**
 * Return a transform matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction. See rayDirection.
 */
mat4 viewMatrix(vec4 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye.xyz);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

/**
 * Given a signed float value, wrap it to 0..1 range
 * Useful for out-of-range UV coordinates
 */
float wrap_to_normal(float n) {
    if (n > 1.0) {
        return n - floor(n);
    }
    if (n < 0.0) {
        return n + ceil(abs(n));
    }
    return n;
}

vec3 checkerboard(float u, float v) {
    float r = 8.0; // Repetitions for uv 0..1
    int ur = int(wrap_to_normal(u) * r);
    int vr = int(wrap_to_normal(v) * r);
    if ((ur+vr) % 2 == 1) {
        return vec3(1.0, 1.0, 1.0);
    } else {
        return vec3(0.2, 0.2, 0.2);
    }
}

void main(void) {
    vec4 viewDir = rayDirection(45.0, resolution.xy);
    vec4 eye = vec4(0.0, 0.0, 12.0, 1.0) * m_rotateX(PI/-6.0) * m_rotateY(PI/6.0 + (time*0.3));

    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    mat4 transform = mat4(1.0);
    vec4 color = vec4(0.0, 0.0, 0.0, 0.0); // Will be replaced by object color. 4th component is EMISSIVE yes/no

    vec4 worldDir = viewToWorld * viewDir;

    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST, transform, color);

    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        // Use a simple gradient on the lower half screen for background
        glFragColor = vec4(0.0, 0.0, 1.0-((gl_FragCoord.y/resolution.y)+0.5), 1.0);
            return;
    }

    // The closest point on the surface to the eyepoint along the view ray
    vec4 p = eye + dist * worldDir;

    vec3 normal = estimateNormal(p);

    // Calculate polar coordinates using a vector from p to center of object
    // c = 0,0,0 * transform so p * transform should point in the right direction
    vec4 pc = p * transform;
    float u = atan(pc.z, pc.x) / PI; // Latitude
    float v = atan(pc.y, sqrt((pc.x * pc.x) + (pc.z * pc.z))) / PI; // Longitude
    vec3 texel = checkerboard(u, v);

    vec3 K_a = vec3(0.2, 0.2, 0.2);
    vec3 K_d = color.rgb;
    vec3 K_s = vec3(1.0, 1.0, 1.0);
    float shininess = 20.0;
    vec3 phong = phongIllumination(K_a, K_d, K_s, shininess, p.xyz, eye, normal);

    glFragColor = vec4(phong.rgb * texel, 1.0);
    if (color.a == 1.0) {
        glFragColor = vec4(glFragColor.rgb + color.rgb, 1.0); // color.a is EMISSIVE yes/no
    }
}
