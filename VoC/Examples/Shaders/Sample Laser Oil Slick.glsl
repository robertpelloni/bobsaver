#version 420

// original https://www.shadertoy.com/view/tssyDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: Reva 20200402

// Some useful functions
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

//
// Description : GLSL 2D simplex noise function
//      Author : Ian McEwan, Ashima Arts
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License :
//  Copyright (C) 2011 Ashima Arts. All rights reserved.
//  Distributed under the MIT License. See LICENSE file.
//  https://github.com/ashima/webgl-noise
//
float snoise(vec2 v) {

    // Precompute values for skewed triangular grid
    const vec4 C = vec4(0.211324865405187,
                        // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,
                        // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,
                        // -1.0 + 2.0 * C.x
                        0.024390243902439);
                        // 1.0 / 41.0

    // First corner (x0)
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    // Other two corners (x1, x2)
    vec2 i1 = vec2(0.0);
    i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
    vec2 x1 = x0.xy + C.xx - i1;
    vec2 x2 = x0.xy + C.zz;

    // Do some permutations to avoid
    // truncation effects in permutation
    i = mod289(i);
    vec3 p = permute(
            permute( i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(
                        dot(x0,x0),
                        dot(x1,x1),
                        dot(x2,x2)
                        ), 0.0);

    m = m*m ;
    m = m*m ;

    // Gradients:
    //  41 pts uniformly over a line, mapped onto a diamond
    //  The ring size 17*17 = 289 is close to a multiple
    //      of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt(a0*a0 + h*h);
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);

    // Compute final noise value at P
    vec3 g = vec3(0.0);
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
    return 130.0 * dot(m, g);
}

#define OCTAVES 1
float fpm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = 0.6;
    float frequency = 2.0;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * fract(snoise(st+snoise(vec2(st.y+time*0.1,st.x))));
        st *= frequency;
        amplitude *= .5;
    }
    return value;
}

float pattern( in vec2 p, out vec2 q)
{
    q.x = fpm( p + vec2(0.240,0.670) );
    q.y = fpm( p + vec2(5.2,1.3) ) ;

    return fpm( p + q*1.5 );
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.y;
    //st -= vec2(0.5);
    vec3 color = vec3(0.0);
    
    vec2 q = vec2(1.0);
    float f = pattern(st*1.0,q);

    color = vec3(1.000,0.881,0.631);
    color = mix(color, vec3(0.243,0.646,0.945),f);
    color = mix(color, vec3(0.220,0.835,0.352),q.x*q.x);
    color = mix(color, vec3(0.830,0.626,0.835),q.y*q.y*2.0);
    color = mix(color, vec3(0.765,0.975,0.928), 0.5*smoothstep(0.368,0.844,abs(q.y)+abs(q.x)) );

    vec2 ex = vec2( 1.0 / resolution.x, 0.0 );
    vec2 ey = vec2( 0.0, 1.0 / resolution.y );
    vec3 nor = normalize( vec3( fpm(st+ex) - f, ex.x, fpm(st+ey) - f ) );
        
    vec3 lig = normalize( vec3(0.8,-0.5,-0.47) );
    float dif = clamp( 0.9+0.1*dot( nor, lig ), 0.0, 1.0 );

    vec3 bdrf;
    bdrf  = vec3(0.924,0.965,0.922)*(nor.y*0.5+0.5);
    bdrf += vec3(0.030,0.036,0.050)*dif;
    bdrf  = vec3(0.85,0.90,0.95)*(nor.y*0.5+0.5);
    bdrf += vec3(0.545,0.474,0.351)*dif;

    color *= bdrf;
    //color = color*color;
    color *= vec3(1.0,1.0,1.15);
    vec2 p = gl_FragCoord.xy/resolution.xy;
     color *= 0.5 + 0.5 * sqrt(40.0*p.x*p.y*(1.0-p.x)*(1.0-p.y));
    
    glFragColor = vec4(color,1.0);
}
