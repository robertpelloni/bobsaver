#version 420

// original https://www.shadertoy.com/view/3sSGzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* https://www.shadertoy.com/view/XsX3zB
 *
 * The MIT License
 * Copyright © 2013 Nikita Miropolskiy
 * 
 * ( license has been changed from CCA-NC-SA 3.0 to MIT
 *
 *   but thanks for attributing your source code when deriving from this sample 
 *   with a following link: https://www.shadertoy.com/view/XsX3zB )
 *
 * ~
 * ~ if you're looking for procedural noise implementation examples you might 
 * ~ also want to look at the following shaders:
 * ~ 
 * ~ Noise Lab shader by candycat: https://www.shadertoy.com/view/4sc3z2
 * ~
 * ~ Noise shaders by iq:
 * ~     Value    Noise 2D, Derivatives: https://www.shadertoy.com/view/4dXBRH
 * ~     Gradient Noise 2D, Derivatives: https://www.shadertoy.com/view/XdXBRH
 * ~     Value    Noise 3D, Derivatives: https://www.shadertoy.com/view/XsXfRH
 * ~     Gradient Noise 3D, Derivatives: https://www.shadertoy.com/view/4dffRH
 * ~     Value    Noise 2D             : https://www.shadertoy.com/view/lsf3WH
 * ~     Value    Noise 3D             : https://www.shadertoy.com/view/4sfGzS
 * ~     Gradient Noise 2D             : https://www.shadertoy.com/view/XdXGW8
 * ~     Gradient Noise 3D             : https://www.shadertoy.com/view/Xsl3Dl
 * ~     Simplex  Noise 2D             : https://www.shadertoy.com/view/Msf3WH
 * ~     Voronoise: https://www.shadertoy.com/view/Xd23Dh
 * ~ 
 *
 */

// discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3

#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)
vec4 hash43(vec3 p)
{
    vec4 p4 = fract(vec4(p.xyzx)  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}
vec3 random3(vec3 p3)
{
    vec4 v = hash43(p3);
    return (v.xyz - .5) * log(1.0-v.w) * 0.5;
}

// skew constants for 3d simplex functions
const float F3 =  0.3333333;
const float G3 =  0.1666667;

// 3d simplex noise
float simplex3d(vec3 p) {
     // 1. find current tetrahedron T and it's four vertices
     // s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices
     // x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices
     
     // calculate s and x
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     // calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     // x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     // 2. find four surflets and store them in d
     vec4 w, d;
     
     // calculate surflet weights
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     // w fades from 0.6 at the center of the surflet to 0.0 at the margin
     w = max(0.6 - w, 0.0);
     
     // calculate surflet components
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     // multiply d by w^4
     w *= w;
     w *= w;
     d *= w;
     
     // 3. return the sum of the four surflets
     return dot(d, vec4(52.0));
}

float simplex3d_fractal(vec3 m)
{
    float l = 2.0;
    float il = 1.0/l;
    float frequency = 1.0;
    float amplitude = 1.0;
    float result = 0.0f;
    for (int i = 0; i < 9; i++)
    {
        result += simplex3d(m*frequency)*amplitude;
        frequency *= l;
        amplitude *= il;
    }
    return result;
}

void main(void)
{
    vec2 p = gl_FragCoord.xy/resolution.x;
    vec3 p3 = vec3(p, time*0.025);
    
    float value;
    
    if (p.x <= 0.6) {
        value = simplex3d(p3*32.0);
    } else {
        value = simplex3d_fractal(p3*8.0+8.0);
    }
    
    value = 0.5 + 0.5*value;
    value *= smoothstep(0.0, 0.005, abs(0.6-p.x)); // hello, iq :)
    
    glFragColor = vec4(
            vec3(value),
            1.0);
    return;
}
