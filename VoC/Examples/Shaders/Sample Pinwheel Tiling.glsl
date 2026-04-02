#version 420

// original https://www.shadertoy.com/view/tdlBz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// See http://tilings.math.uni-bielefeld.de/substitution/pinwheel/

#define NITERS 7 // Change to alter the subdivision fineness
#define BORDER 0
#define T (time / 10.0) // Change to alter speed

/*
 * In the following, let P, Q, R denote the vertices of a right triangle PQR of
 * sides 1:2:√5, with short side PQ and long side QR, like the following:
 * 
 *   P
 *   +
 *   |\__
 *   |   \_____
 *   |         \____
 *   |              \____
 *   |                   \_____  √5
 * 1 |                         \____
 *   |                              \____
 *   |                                   \_____
 *   |                                         \___
 *   +-+                                           \
 *   +-+--------------------------------------------+
 * Q                       2                        R
 *
 */

/*
 * The vector ⟂{x, y} == {-y, x} perpendicular to the given vector.
 * The key properties of this "2D cross vector" are, for all vectors u, v:
 *
 * - ⟂⟂v == -v
 * - v•⟂v == 0
 * - u•⟂v == -v•⟂u
 * - u•⟂v == |u|*|v|*sin(α), with α the angle between u and v in that order
 *
 * When u•v is the parallel component of v along u,
 * then u•⟂v is the perpendicular component of v along u.
 *
 * See Francis S. Hill, "The Pleasures of 'perp dot' Products", in Graphics Gems IV
 */
#define PERP(v) (vec2(-v.y, v.x))

/*
 * A point X is inside the triangle PQR iff its barycentric coordinates (s:t:1-s-t) are
 * in the range [0, 1]; that is, iff there exist 0 ≤ s, t ≤ 1; 0 ≤ s + t ≤ 1 such that
 * X == s*P + (1 - s - t)*Q + t*R == s*(P - Q) + Q + t*(R - Q).
 *
 * In the 1:2:√5 right triangle, ±2*(P - Q) = ⟂(R - Q), with the plus-minus sign
 * accounting for orientation. Substituting and solving for s, t we have:
 *
 * s == (X - Q)•(P - Q) / (P - Q)•(P - Q)
 * t == (X - Q)•(R - Q) / (R - Q)•(R - Q)
 *
 * The point X is then inside the triangle PQR iff s, t, s + t are all in range [0, 1].
 */

/*
 * Return the barycentric coordinates (s : t : 1-s-t) of point X in 1:2:√5 triangle PQR.
 */
vec3 barycentric(in vec2 x, in vec2 p, in vec2 q, in vec2 r)
{
    vec2 u = x - q;
    vec2 v = p - q;
    vec2 w = r - q;
    float s = dot(u, v)/dot(v, v);
    float t = dot(u, w)/dot(w, w);
    return vec3(s, t, 1.0 - s - t);
}

/*
 * Test if point X lies inside the 1:2:√5 triangle PQR.
 * The predicate rearranges the calculation above to avoid divisions.
 */
bool ptInTriangle(in vec2 x, in vec2 p, in vec2 q, in vec2 r)
{
    vec2 u = x - q;
    vec2 v = p - q;
    vec2 w = r - q;
    float a = dot(u, v);
    float b = dot(v, v);
    float c = dot(u, w);
    float d = dot(w, w);
    return 0.0 <= a && a <= b && 0.0 <= c && c <= d && a*d + b*c <= b*d;
}

/*
 * Return +1 if the 1:2:√5 triangle PQR is in CCW orientation, that is,
 * if the short side PQ is CCW to the long side QR; otherwise return -1.
 */
float ccw(in vec2 p, in vec2 q, in vec2 r)
{
    vec2 u = p - q;
    vec2 v = r - q;
    vec2 w = PERP(v);
    return 2.0 * dot(u, w) / dot(v, v);
}

#define PI 3.14159265359

/*
 * Compute the orientation α ∈ [0, 1] of the 1:2:√5 triangle PQR,
 * as a fraction of π/2, modulo vertical reflections and rotations by π/2.
 */
float rot(in vec2 p, in vec2 q, in vec2 r)
{
    vec2 u = r - q;
    float a = (2.0 / PI) * ccw(p, q, r) * atan(u.y, u.x);
    return fract(a);
}

/*
 * Color point X in triangle PQR with hash H according to its orientation.
 */
vec3 color(in vec2 x, in float h, in vec2 p, in vec2 q, in vec2 r)
{
    //float a = rot(p, q, r);
    vec3 c = vec3(1.0, h, h);
    vec3 y = barycentric(x, p, q, r);
    //c = y;
#if BORDER
    float s = min(y.x, min(y.y, y.z));
    c = mix(vec3(0.0), c, smoothstep(0.0, 5.0*float(NITERS)/resolution.x, s));
#endif
    return c;
}

/*
 * The base case decides in which of the two triangles resulting from dividing a
 * 1:2 rectangle along the diagonal the point X lies:
 *
 * (0,1)                                         (2,1)
 *  +----------------------------------------------+
 *  |\__                                           |
 *  |   \_____                                     |
 *  |         \____                                |
 *  |              \____                           |
 *  |                   \_____                     |
 *  |                         \____                |
 *  |                              \____           |
 *  |                                   \_____     |
 *  |                                         \___ |
 *  +-+                                           \|
 *  +-+--------------------------------------------+
 * (0,0)                                        (2,0)
 * 
 * This triangle is then subdivided in points S, T, U, V with QU ⟂ RP, ST ⟂ RP and
 * SV ⟂ QU, such that the resulting triangles are similar, in the following order:
 * 
 *   P
 *   |\_
 *   |  \_____ U
 *   |        \____
 *   |  1    /\_   \____
 *   |      /   \__     \_____
 *   |     /       \_         \____  T
 *   |  V +    3     \_    4       \____
 *   |   / \_____      \__         /    \_____
 *   |  /        \_____   \_      /           \____
 *   | /     2         \____\__  /       5         \__
 *   +-------------------------\/---------------------\
 * Q                           S                       R
 *
 * The point X is tested against each of these five smaller triangles, and the process
 * is repeated with new points P, Q, R in the same order as above, to the specified
 * number of iterations.
 *
 * By keeping track of the triangle index at each subdivision, one can compute
 * a hash of the input point X corresponding uniquely to the triangle containing it.
 */

/*
 * Test point X with 0 ≤ X.x ≤ 2, 0 ≤ X.y ≤ 1 against the tiling of depth n.
 * Return the tile color as a vec3.
 */
vec3 tile(in vec2 x, in int n)
{
    float h = 0.0; // hash, or sequence of triangles in the subdivision
    
    // Base case
    vec2 p, q, r;
    if (x.y + 0.5 * x.x <= 1.0) {
        p = vec2(0.0, 1.0);
        q = vec2(0.0, 0.0);
        r = vec2(2.0, 0.0);
        h = 0.0;
    } else {
        p = vec2(2.0, 0.0);
        q = vec2(2.0, 1.0);
        r = vec2(0.0, 1.0);
        h = 0.5;
    }

    // Subdivide
    for (int i = 0; i < n; i++) {
        vec2 s = mix(q, r, 0.5);
        vec2 u = mix(p, r, 0.2);
        vec2 t = mix(u, r, 0.5);
        vec2 v = mix(q, u, 0.5);
        // Find the enclosing triangle among
        // {p, u, q}, {q, v, s}, {u, v, s}, {s, t, u}, {s, t, r}
        if (ptInTriangle(x, p, u, q)) {
            r = q;
            q = u;
            h += 0.0;
        } else if (ptInTriangle(x, q, v, s)) {
            p = q;
            q = v;
            r = s;
            h += 1.0;
        } else if (ptInTriangle(x, u, v, s)) {
            p = u;
            q = v;
            r = s;
            h += 2.0;
        } else if (ptInTriangle(x, s, t, u)) {
            p = s;
            q = t;
            r = u;
            h += 3.0;
        } else if (ptInTriangle(x, s, t, r)) {
            p = s;
            q = t;
            h += 4.0;
        }
        h *= 0.2;
    }
    // At this point, 0 ≤ h < 1
    return color(x, h, p, q, r);
}

void main(void)
{
    float k = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / k;
    // 0 ≤ p.x < 2, 0 ≤ p.y < 1
    vec2 p = vec2(2.0*fract(uv.x), fract(2.0*uv.y));
    float s = 0.5 + 0.5 * sin(2.0*PI*T);
    int n = int(round(float(NITERS) * s));
    vec3 col = tile(p, n);
    glFragColor = vec4(col, 1.0);
}
