#version 420

// original https://www.shadertoy.com/view/4dtfDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Gerstner Waves
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

//Changes:
//1: removed the incompatible inverse(.) call
//2: removed the S() and C() functions

//universal constants
const float pi = acos(-1.);
const vec2 c = vec2(1.,0.);
const int nwaves = 9;

float rand(vec2 a0)
{
    return fract(sin(dot(a0.xy ,vec2(12.9898,78.233)))*43758.5453);
}

struct wave
{
    float st;//qi
    float am;//ai
    vec2 di;//di
    float fr;//wi
    float sp;//phi
} waves[nwaves];

vec3 gerst(vec2 xy, float t)
{
    vec3 ret = vec3(xy, 0.);
    for(int i=0; i<nwaves; ++i)
    {
        float d = dot(waves[i].di, xy);
        ret += vec3(
            waves[i].st*waves[i].am*waves[i].di*cos(waves[i].fr*d+waves[i].sp*t),
            waves[i].am*sin(waves[i].fr*d+waves[i].sp*t)
        );
    }
    return ret;
}

vec3 normal(vec2 xy, float t)
{
    vec3 P = gerst(xy, t);
    
    vec3 ret = c.yyy;
    for(int i=0; i<nwaves; ++i)
    {
        ret += vec3(
            -waves[i].di*waves[i].fr*waves[i].am*cos(waves[i].fr*dot(waves[i].di,P.xy)+waves[i].sp*t),
            1.-waves[i].st*waves[i].fr*waves[i].am*sin(waves[i].fr*dot(waves[i].di,P.xy)+waves[i].sp*t)
        );
    }
    return ret;
}

void main(void)
{
    //setup gerstner waves
    for(int i=0; i<nwaves; ++i)
    {
        waves[i].st =  abs(.35*rand(vec2(float(i))));
        waves[i].am = .02+.005*rand(vec2(float(i+2)));
        waves[i].di = (1.e0+vec2(1.7e0*rand(vec2(i,i+1)), 2.e0*rand(vec2(i+1,i))));
        waves[i].fr = 6.+12.*rand(vec2(float(i+5)))+2.e-1*float(i);
        waves[i].sp = 55.e-1+52.e-1*rand(vec2(float(i+4)));
    }
    
    //raytrace and colorize
    vec2 uv = gl_FragCoord.xy/resolution.yy;
    vec3 o = c.yyx, r = 1.*c.xyy, u = 1.*c.yxy+c.yyx, d = normalize(cross(u,r)),
        ro = o+uv.x*r+uv.y*u;
    
    vec3 l = (c.yyx-3.*c.yxy),
        //p = inverse(mat3(d,c.xyy,c.yxy))*ro, //unportable!
        p = mat3(c.yxy, c.yyx, 1./d.z, -d.x/d.z, -d.y/d.z)*ro,
        n = normalize(normal(p.xy, time)),
        re = normalize(reflect(-l, n)), 
        v = normalize(p-ro);
    
    vec3 col = .2*c.yxx+.2*c.yyx*dot(l, n)+3.6e1*c.xxx*pow(dot(re,v), 4.);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
