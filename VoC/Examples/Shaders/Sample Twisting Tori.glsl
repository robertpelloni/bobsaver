#version 420

// original https://www.shadertoy.com/view/7sfSWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// For ray marching:
const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

// FROM https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

// From ??
mat4 rotation3d(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
        0.0,                                0.0,                                0.0,                                1.0
    );
}

// They key SDF
float weirdTorus( vec3 p, vec2 t, float time_offset)
{    
    // Varying width based on angle
    float angle = acos(dot(normalize(p.xz), normalize(vec2(sin(time+time_offset), cos(time+time_offset)))));
    float width = -0.018 + t.y*abs(sin(angle*1.5));
    
    // Mess with height
    float static_angle = acos(dot(normalize(p.xz), normalize(vec2(0., 1.))));
    p.y += 0.06*cos(static_angle*4.); // These values need tweaking...
    p.x += 0.06*cos(static_angle*3.14);

    
    // Torus:
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-width;
}

// Three together with some rotation between them 
float sceneSDF(vec3 samplePoint) { 

    // Rotate viewing angle
    samplePoint = (rotation3d(vec3(0.4,0.,0.1), 0.5)*vec4(samplePoint, 0.)).xyz;
    
    // The first twisty torus
    float t1 = weirdTorus(samplePoint, vec2(0.4,0.050),  0.);
    
    // Rotate and add a second one then a third
    samplePoint = (rotation3d(vec3(0., 1., 0.), 0.3)*vec4(samplePoint, 0.)).xyz;
    float t2 = weirdTorus(samplePoint, vec2(0.4, 0.05), 0.);
    samplePoint = (rotation3d(vec3(0., 1., 0.), 0.3)*vec4(samplePoint, 0.)).xyz;
    float t3 = weirdTorus(samplePoint, vec2(0.4, 0.05), 0.);
    
    // Combine and return the final distance
    return min(t1, min(t2, t3));

}

// Ray marching stuff from https://www.shadertoy.com/view/llt3R4
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
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
vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

// Generating the final image
void main(void)
{    
    vec3 dir = rayDirection(0.298 * 100., resolution.xy);
    vec3 eye = vec3(0., 0, 5.); // Can edit this to move based on mouse position for interactivity
    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * dir;
    
    // An estimated normal
    vec3 n = estimateNormal(p);
    
    // Lighting - fake image based lighting as shown in https://www.youtube.com/watch?v=FilPE91ACOA&t=1s
    vec3 color = vec3(pow(length(sin(n*2.)*.5+.5)/sqrt(3.), 2.));
    
    glFragColor = vec4(color, 1.0);
}
