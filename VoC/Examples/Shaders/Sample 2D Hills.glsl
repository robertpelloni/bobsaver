#version 420

// original https://www.shadertoy.com/view/XcjXDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by "2D Wavy Hills" (https://www.shadertoy.com/view/Xc2SWc)

// 3d simplex noise from https://www.shadertoy.com/view/XsX3zB

vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}

float circle(vec2 uv, float r) {
    return smoothstep(.1,0.,length(uv) - r);
}
void main(void) {
    float a = time / 1.;
    vec2 w = gl_FragCoord.xy/resolution.x * 50. + a;
    vec2 dir = (-gl_FragCoord.xy/resolution.xy + .5) * 4.;
    vec2 uv = (fract(w) - .5);
    vec2 id = floor(w);
    
    vec3 col = vec3(0.);
    
    for (int x=-3;x<=3;x++) {
        for (int y=-3;y<=3;y++) {
            float size = abs(simplex3d(vec3((id + vec2(x, y))*0.06, a / 10.)));
            col += mix(
                       vec3(0.039,0.051,0.063) / 49.,
                       mix(vec3(0.000,0.518,1.000), vec3(0.890,0.051,0.263), size + .2),
                       circle((uv - vec2(x, y)) + dir * size * 2., 0.5 * size)
                   );
        }
    }

    glFragColor = vec4(col,1.0);
}
