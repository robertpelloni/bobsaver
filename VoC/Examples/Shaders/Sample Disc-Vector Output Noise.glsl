#version 420

// original https://www.shadertoy.com/view/wlcXzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////// K.jpg's Smooth Re-oriented 8-Point BCC Noise (OpenSimplex 2, Smooth Version) //////////////////
///////////////////////// Modified to output a 2D vector instead of a standard 1D value. /////////////////////////

// Borrowed from Stefan Gustavson's noise code
vec4 permute(vec4 t) {
    return t * (t * 34.0 + 133.0);
}

// Gradient set is a normalized expanded rhombic dodecahedron
vec3 grad(float hash) {
    
    // Random vertex of a cube, +/- 1 each
    vec3 cube = mod(floor(hash / vec3(1.0, 2.0, 4.0)), 2.0) * 2.0 - 1.0;
    
    // Random edge of the three edges connected to that vertex
    // Also a cuboctahedral vertex
    // And corresponds to the face of its dual, the rhombic dodecahedron
    vec3 cuboct = cube;
    cuboct[int(hash / 16.0)] = 0.0;
    
    // In a funky way, pick one of the four points on the rhombic face
    float type = mod(floor(hash / 8.0), 2.0);
    vec3 rhomb = (1.0 - type) * cube + type * (cuboct + cross(cube, cuboct));
    
    // Expand it so that the new edges are the same length
    // as the existing ones
    vec3 grad = cuboct * 1.22474487139 + rhomb;
    
    // To make all gradients the same length, we only need to shorten the
    // second type of vector. We also put in the whole noise scale constant.
    // The compiler should reduce it into the existing floats. I think.
    grad *= (1.0 - 0.042942436724648037 * type) * 3.5946317686139184;
    
    return grad;
}

// BCC lattice split up into 2 cube lattices
vec2 bccNoisePart(vec3 X) {
    vec3 b = floor(X);
    vec4 i4 = vec4(X - b, 2.5);
    
    // Pick between each pair of oppposite corners in the cube.
    vec3 v1 = b + floor(dot(i4, vec4(.25)));
    vec3 v2 = b + vec3(1, 0, 0) + vec3(-1, 1, 1) * floor(dot(i4, vec4(-.25, .25, .25, .35)));
    vec3 v3 = b + vec3(0, 1, 0) + vec3(1, -1, 1) * floor(dot(i4, vec4(.25, -.25, .25, .35)));
    vec3 v4 = b + vec3(0, 0, 1) + vec3(1, 1, -1) * floor(dot(i4, vec4(.25, .25, -.25, .35)));
    
    // Gradient hashes for the four vertices in this half-lattice.
    vec4 hashes = permute(mod(vec4(v1.x, v2.x, v3.x, v4.x), 289.0));
    hashes = permute(mod(hashes + vec4(v1.y, v2.y, v3.y, v4.y), 289.0));
    vec4 hashesRaw = permute(mod(hashes + vec4(v1.z, v2.z, v3.z, v4.z), 289.0));
    hashes = mod(hashesRaw, 48.0);
    vec4 outDirHashes = mod(floor(hashesRaw / 48.0), 6.0);
    vec4 outDirAngles = outDirHashes / 6.0 * 3.14159 * 2.0; // You could easily create more than 6 output base directions, with a wider-ranged hash
    
    // Gradient extrapolations & kernel function
    vec3 d1 = X - v1; vec3 d2 = X - v2; vec3 d3 = X - v3; vec3 d4 = X - v4;
    vec4 a = max(0.75 - vec4(dot(d1, d1), dot(d2, d2), dot(d3, d3), dot(d4, d4)), 0.0);
    vec4 aa = a * a; vec4 aaaa = aa * aa;
    vec3 g1 = grad(hashes.x); vec3 g2 = grad(hashes.y);
    vec3 g3 = grad(hashes.z); vec3 g4 = grad(hashes.w);
    vec4 extrapolations = vec4(dot(d1, g1), dot(d2, g2), dot(d3, g3), dot(d4, g4));
    vec4 extrapolationsP = extrapolations * sin(outDirAngles);
    vec4 extrapolationsQ = extrapolations * cos(outDirAngles);
    
    // Return it all as a vec4
    return vec2(dot(aaaa, extrapolationsP), dot(aaaa, extrapolationsQ));
   
}

// Classic "Simplex" noise lattice orientation.
vec2 bccNoise_XYZ(vec3 X) {
    
    // Orthonormal rotation, not a skew transform.
    X = dot(X, vec3(2.0/3.0)) - X;
    return bccNoisePart(X) + bccNoisePart(X + 144.5);
}

// Gives X and Y a triangular alignment, and lets Z move up the main diagonal.
// Should be better for terrain or a time varying X/Y plane. Z repeats.
vec2 bccNoise_PlaneFirst(vec3 X) {
    
    // Orthonormal rotation, not a skew transform.
    mat3 orthonormalMap = mat3(
        0.788675134594813, -0.211324865405187, -0.577350269189626,
        -0.211324865405187, 0.788675134594813, -0.577350269189626,
        0.577350269189626, 0.577350269189626, 0.577350269189626);
    
    X = orthonormalMap * X;
    return bccNoisePart(X) + bccNoisePart(X + 144.5);
}

//////////////////////////////// End noise code ////////////////////////////////

// Borrowed from https://www.shadertoy.com/view/Wt3XzS by FabriceNeyret2
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    
    // Normalized pixel coordinates (from 0 to 1 on largest axis)
    vec2 uv = gl_FragCoord.xy / max(resolution.x, resolution.y);
    uv *= 10.0;
    
    // Input point
    vec3 X = vec3(uv, mod(time, 578.0) * 0.8660254037844386);
    
    // Evaluate noise
    vec2 noiseResult = bccNoise_PlaneFirst(X);
    
    float phi = atan(noiseResult.y, noiseResult.x);
    vec3 col = hsv2rgb(vec3(phi/(2.*3.14159), .8, .8));

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
