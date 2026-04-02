#version 420

// original https://www.shadertoy.com/view/7sV3RV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//// This shader displays the view of someone (the white dot) living on the surface of a torus of revolution.
//// The red part is the positively curved outer part of the torus,
//// the blue part is the negatively curved inner part.

// The tube radius is always 1. The midradius is the radius of the circle followed by the tube.
const float midradius = 1.5;
// If the midradius is close to or less than 1, significant numerical instability will occur,
// and you need to crank up the number of integration steps below.

// Number of numerical integration steps to compute geodesic differential equation
// Increase to improve numerical accuracy and fix yellow areas, decrease for performance
const int integrationSteps = 40;

// Length of a unit, in pixels. Larger values will zoom the screen out.
// This may require more integration steps for accuracy at large distances.
const float unitLength = 20.0;

// Number of latitude/longitude lines
const float latitudeLines = 8.0;
const float longitudeLines = midradius * latitudeLines;

// Parametrization of the torus:
// P = ((m+cos(y))cos(x), ((m+cos(y))sin(x), sin(y))
// m is the midradius

// Geodesic differential equation:
// (m+cos(y))x'' - sin(y)x'y' = 0
// 2y'' + sin(y)x'x' = 0

// Given position and velocity of a curve in parameter space representing a geodesic, compute second derivatives of that curve.
vec2 dd(vec2 pos, vec2 dpos) {
    vec2 ddpos;
    ddpos.x = sin(pos.y) * dpos.x * dpos.y / (midradius+cos(pos.y));
    ddpos.y = -sin(pos.y) * dpos.x * dpos.x / 2.0;
    return ddpos;
}

// Convert second-order 2D differential equation function to first-order 4D
vec4 D(vec4 pdp) {
    return vec4(pdp.zw, dd(pdp.xy, pdp.zw));
}

// Euler method
vec4 step_eu(vec4 v, float dt) {
    vec4 Dv = D(v);
    return v + dt * Dv;
}

// Midpoint method
vec4 step_mp(vec4 v, float dt) {
    vec4 Dv = D(v);
    vec4 Dvm = D(v + 0.5 * dt * Dv);
    return v + dt * Dvm;
}

// Classic 4-step Runge-Kutta method
vec4 step_rk(vec4 v, float dt) {
    vec4 Dv1 = D(v);
    vec4 Dv2 = D(v + 0.5 * dt * Dv1);
    vec4 Dv3 = D(v + 0.5 * dt * Dv2);
    vec4 Dv4 = D(v + dt * Dv3);
    return v + dt * (Dv1 + 2.0 * Dv2 + 2.0 * Dv3 + Dv4) / 6.0;
}

vec3 gridColor(vec2 uv) {
    float p = 2.0;
    float pi = 3.14159265359;
    vec2 r = abs(2.0*fract(uv/vec2(2.0*pi/longitudeLines, 2.0*pi/latitudeLines))-vec2(1.0, 1.0));
    float g = 0.5*float(r.x > 0.9) + 0.8*float(r.y > 0.9);
    return vec3(cos(uv.y), g, -cos(uv.y));
}

// Iteratively follow geodesic in small steps
vec2 iter(vec2 uv, vec2 pos0) {
    // Convert screen coordinates to tangent coordinates isometrically
    vec2 dpos0 = uv/vec2(midradius+cos(pos0.y), 1.0);
    vec4 pdp = vec4(pos0, dpos0);
    const float stepSize = 1.0 / float(integrationSteps);
    for (int i = 0; i < integrationSteps; ++i) {
        pdp = step_rk(pdp, stepSize);
    }
    return pdp.xy;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy) / unitLength;
    vec2 pos0 = vec2(0.0, time);
    vec4 visibleColor = vec4(gridColor(iter(uv, pos0)), 1.0);
    vec4 dotColor = vec4(1.0, 1.0, 1.0, 1.0);
    glFragColor = mix(visibleColor, dotColor, float(dot(uv, uv) < 0.03));
}
