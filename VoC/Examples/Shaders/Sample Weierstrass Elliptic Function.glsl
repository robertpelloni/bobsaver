#version 420

// original https://www.shadertoy.com/view/WtXGzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Basic domain coloring plot (https://en.wikipedia.org/wiki/Domain_coloring)
// of the equianharmonic case of the Weierstrass elliptic function w = ℘(z ; 0, 1) and its derivative (https://en.wikipedia.org/wiki/Weierstrass%27s_elliptic_functions)

#define PI 3.14159265359
#define SCALE 6.0 // plot scale
#define SPACING 0.125 // grid line spacing

// from Fabrice Neyret, 
#define cis(a) vec2( cos(a), sin(a) )
#define cmul(A,B) ( mat2( A, -(A).y, (A).x ) * (B) )
#define cinv(Z) ( vec2( (Z).x, -(Z).y ) / dot(Z, Z) ) 
#define cdiv(A,B) cmul( A, cinv(B) )

// periodic function with needle-like peaks
float needles( float x )
{
    float ax = abs(6.0 * mod(2.0 * x, 2.0) - 6.0);
    return 0.5 * (7.0 - ax - abs(5.0 - ax));
}

// modified DLMF coloring, adapted from https://www.shadertoy.com/view/WtXGWN
vec3 smooth_dlmf( float h )
{
    vec3 rgb = clamp( vec3(1., -1., -1.) * abs((vec3(8., 4., 8.) * mod(h, 1.0) - vec3(4.5, 1.5, 5.5))) + vec3(-1.5, 1.5, 2.5), 0.0, 1.0 );
    return rgb * rgb * rgb/(1.0 - 3.0 * rgb * (1.0 - rgb));
}

// Weierstrass elliptic function via Padé approximation + argument doubling, https://doi.org/10.1093/imanum/10.1.119
// real and imaginary parts of ℘(z) is packed into the first two components,
// while the real and imaginary parts of ℘'(z) are in the last two.

vec4 wpequ( in vec2 z)
{
     const float om = 1.529954037057; // real semiperiod
     const float o3 = 0.57735026919; // 1/sqrt(3)
     const vec2 ep = vec2(0.5, 0.866025403784); // exp(i * pi/3)
     // constants for Padé approximation
     const float P0 = 0.00328332715973; // 3191/971880
     const float P1 = 0.0148207056102; // 205/13832

    // period reduction and rescaling
    vec2 zt = z - 2.0 * om * (vec2(floor(0.5 - o3 * dot(vec2(ep.x, -ep.y), z)/om), 0.0) + floor(o3 * z.y/om + 0.5) * ep);
    vec2 zz = (dot(zt, zt) > 0.25) ? 0.125 * zt : zt;

    // evaluate the Padé approximants
    vec2 z2 = cmul(zz, zz), z4 = cmul(z2, z2), z3 = cmul(zz, z2), z6 = cmul(z4, z2);
    vec2 wp = cinv(z2) + cdiv(cmul(z4/28.0, vec2(1.0, 0.0) + z6/2730.), vec2(1.0, 0.0) + cmul(z6/420., z6/1729.0 - vec2(1.0, 0.0)));
    vec2 pd = cdiv(cmul(z3/7.0, vec2(1.0, 0.0) + P0 * z6), vec2(1.0, 0.0) + cmul(z6/3738.0, P1 * z6 - vec2(13.4, 0.0))) - 2.0 * cinv(z3);
    
    // argument doubling
    if (dot(zt, zt) > 0.25) {
      for (int k = 0; k < 3; k++) {
           vec2 tmp1 = cmul(wp, cmul(wp, wp)), tmp2 = cmul(pd, pd);
           pd = cdiv(cmul(tmp2 - vec2(18.0, 0.0), tmp2) - vec2(27.0, 0.0), 8.0 * cmul(pd, tmp2));
           wp = cdiv(cmul(tmp1 + vec2(2.0, 0.0), wp), 4.0 * tmp1 - vec2(1.0, 0.0));
      }
    }

    return vec4(wp, pd);
}

void main(void)
{
    vec2 aspect = resolution.xy / resolution.y;
    vec2 z = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
    z *= SCALE;
    
    vec4 wpd = wpequ(cmul(z, cis(0.1 * time)) + time);
    vec2 w = mix(wpd.zw, wpd.xy, 0.5 + 0.5 * cos(0.3 * time)); // express transition as a linear combination of the function and its derivative
    float ph = atan(w.y, w.x);
    float lm = log(0.0001 + length(w));
    
    vec3 c = vec3(1.0);
    c = smooth_dlmf(0.5 * (ph / PI));

    c = mix( vec3(1.0), c, 0.5 + 0.5 * needles((0.5 * (lm/PI))/SPACING) * needles((0.5 * (ph / PI))/SPACING));
    glFragColor = vec4(c, 1.0);
}
