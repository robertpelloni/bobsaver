#version 420

// original https://www.shadertoy.com/view/XldBD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Two-dimensional Spirals
 * 
 * Copyright (C) 2018  Alexander Kraus <nr4@z10.info>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const float pi = acos(-1.);
const vec3 c = vec3(1.,0.,-1.);

// hash function
float r(vec2 a0)
{
    return fract(sin(dot(a0.xy ,vec2(12.9898,78.233)))*43758.5453);
}

// distance to spiral
float dspiral(vec2 x, float a, float d)
{
    float p = atan(x.y, x.x),
        n = floor((abs(length(x)-a*p)+d*p)/(2.*pi*a));
    p += (n*2.+1.)*pi;
    return -abs(length(x)-a*p)+d*p;
}

#define A resolution.y
#define B 3./Y
#define S(v) smoothstep(-1.5/A,1.5/A,v)
void main(void)
{
    float a = .125, aa = .5*a; // tile size
    vec2 uv = gl_FragCoord.xy/A+.5,
        x = mod(uv, a)-aa, y = uv-x; // we want many spirals

    //random number of edges and random rotation
    float p = (-7.5+15.*r(y))*time,
        k = cos(p), s = sin(p), k2 = cos(p-pi), s2 = sin(p-pi),
        d = dspiral(mat2(k,s,-s,k)*x, 5.e-3*(.75+.5*r(y+1.)), 4.e-4*(.75+.5*r(y+2.)));
    
    //set random colors
    vec3 col = .5 + .5*cos(p+uv.xyx+vec3(0.,2.,4.));
    glFragColor = vec4(col*mix(S(d),1.,.5)+S(-abs(d)),1.);
    
    //add borders
    vec2 v = smoothstep(-aa,-aa+1.5/A,x)*smoothstep(aa,aa-1.5/A,x);
    glFragColor *= v.x*v.y;
}
