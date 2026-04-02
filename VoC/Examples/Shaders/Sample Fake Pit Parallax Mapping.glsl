#version 420

// original https://www.shadertoy.com/view/sdXBzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float aastep(float threshold, float value) {
    float afwidth = 0.7 * length(vec2(dFdx(value), dFdy(value)));
    return smoothstep(threshold-afwidth, threshold+afwidth, value);
}

void main(void)
{
    // Fit unit circle in viewport
    vec3 uvw = vec3((2.0*gl_FragCoord.xy-resolution.xy)/min(resolution.x, resolution.y), 0.0);

    float tilt = 0.7 - 0.7*cos(time);
    float Ct = cos(tilt);
    float St = sin(tilt);
    // Note to self: GLSL matrix constructors enumerate elements column by column!
    mat2 Rt = mat2(Ct, St, -St, Ct); // Transforms from object space to view space
    mat2 invRt = mat2(Ct, -St, St, Ct); // Transforms from view space to object space

    // This is not "proper" ray tracing, just a straight projection to object coords
    vec3 N = vec3(0.0, 0.0, 1.0); // Object space
    vec3 q = uvw;
    vec3 qv = q; // Save "ray origin" in view space
    q.z = q.y * St/Ct; // Hit point for current fragment in view space, with z "traced"
    q.yz = invRt*q.yz; // Hit point is now in object space
    // vec3 V = vec3(0.0, 0.0, 1.0); // This simple demo doesn't use V for anything
    // V.yz = invRt*V.yz; // View direction is now in object space

    // ("Hit point" y in object space is now (view y) * (Ct + St*St/Ct)

    float rpit = 0.9;  // Radius of pit
    float dpit = 0.25; // Depth of pit (relative to radius)
    float robj = length(q.xy) - rpit; // Distance to rim in object space
    float pitmask = aastep(0.0, robj); // Binary mask for fragments "in the pit"
    vec3 dp = -dpit*St*N; // Object space offset for displaced fake lower rim
    dp.yz = Rt*dp.yz; // dp is now in view space
    // Displace the hit point in view xy, discard and "retrace" z to the tilted plane
    vec3 q_ = qv + dp;
    q_.z = q_.y * St/Ct; // Retrace (reproject) to the tilted object plane in view space
    q_.yz = invRt*q_.yz; // q_ is now in object space on the object plane
    float pitmaskd = aastep(0.0, length(q_.xy) - rpit); // Mask for "bottom of the pit"
    // Recompute the texture coordinates on the fake pit wall: "move up to the rim"
    vec2 s; // This is our possibly adjusted 2-D texcoord in the object plane
    if((1.0-pitmask)*pitmaskd == 0.0) { // In the pit, but not at bottom: on the "wall"
        // We're either outside the pit (texcoords are fine, don't touch them)
        // or on the bottom (texcoords are not needed, because it's a hole)
        s = q.xy;
    }
    else { // We're inside the pit *and* on the fake wall: stretch the texcoords
        // (Retrace translation with dp in view space to z=0 in obj space. A bit tricky.)
        // We need to solve a 2nd order equation to find where q_ crossed the upper rim.
        vec2 a = q.xy;
        vec2 b = dp.xy;
        float bb = dot(b,b);
        float c = dot(a,b)/bb;
        float d = c*c - (dot(a,a) - rpit*rpit)/bb;
        if(d < 0.0) { // Shouldn't happen given the circumstances, but play it safe
            vec2 s = q.xy;
        } else {
            float t = - c + sqrt(d);
            s = a + t*b;
            // TODO: find a way to "smooth-bevel the texcoords"
            // We need to interpolate with q from *outside* the rim, somehow
            // s = mix(q.xy, s, smoothstep(0.0,1.0,t)); // Meh, fail
        }
    }
    float spokes = aastep(0.0, sin(atan(s.y, s.x)*50.0));  // Looks a bit weird
    float grid = aastep(0.0, sin(s.y*10.0)+sin(s.x*10.0)); // in this ortho proj,
    vec3 pattern = vec3(1.0-spokes, 1.0-grid, 0.5*spokes+0.5*grid); // but okay
    float planeshade = 1.0 - 0.3*(1.0-pitmask)*pitmaskd;
    vec3 planecolor = vec3((pitmask+(1.0-pitmask)*pitmaskd)*planeshade*pattern);
    
    glFragColor = vec4(planecolor, 1.0);
}
