#version 420

// original https://www.shadertoy.com/view/3s2SR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Grid Slider - Passion's "World War Zed" gave me the idea for trying this
// collage-like thing. Passion's shader is https://www.shadertoy.com/view/3dBSz3
//
// Copyright 2019 Mirco Müller
//
// Author(s):
//   Mirco "MacSlow" Müller <macslow@gmail.com>
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License version 3, as published
// by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranties of
// MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////

mat2 r2d (float degree)
{
    float r = radians (degree);
    float c = cos (r);
    float s = sin (r);
    return mat2 (c,  s, -s,  c);
}

// hash(), noise3d() & fbm() are from iq or shane iirc
float hash (float f)
{
    return fract (sin (f) * 45785.5453);
}

float noise3d (vec3 p)
{
    vec3 u = floor (p);
    vec3 v = fract (p);
    
    v = v * v * (3. - 2. * v);

    float n = u.x + u.y * 57. + u.z * 113.;
    float a = hash (n);
    float b = hash (n + 1.);
    float c = hash (n + 57.);
    float d = hash (n + 58.);

    float e = hash (n + 113.);
    float f = hash (n + 114.);
    float g = hash (n + 170.);
    float h = hash (n + 171.);

    float result = mix (mix (mix (a, b, v.x),
                             mix (c, d, v.x),
                             v.y),
                        mix (mix (e, f, v.x),
                             mix (g, h, v.x),
                             v.y),
                        v.z);

    return result;
}

float fbm (vec3 p)
{
    mat2 m1 = r2d (1.1 * time);
    mat2 m2 = r2d (-1.2 * time);
    mat2 m3 = r2d (time);

    float result = .0;
    result = 0.5 * noise3d (p);
    p.xz *= m1 * 2.02;
    result += 0.25 * noise3d (p);
    p.xz *= m2 * 2.03;
    result += 0.125 * noise3d (p);
    p.xz *= m3 * 2.04;
    result += 0.0625 * noise3d (p);
    result /= 0.9375;

    return result;
}

float sdThing (in vec3 p, in int type, inout vec3 objectUVW) {
    float d = .0;
    if (type == 0) { // wavy ball
        float r = .5 + .1*(.5 + .5*cos (5.*time + 25.*p.y));
        d = length (p) - r;
    } else if (type == 1) { // turning cube
        p.xz *= r2d (25.*time);
        p.yz *= r2d (67.*time);
        d = length (max (vec3 (.0), abs (p) - vec3 (.3))) - .05;
    } else if (type == 2){ // spiky ball
        float x = .5 + .5*cos (5.*(time + 2.) + 17.*p.x);
        float y = .5 + .5*cos (5.*(time + 4.) + 17.*p.y);
        float z = .5 + .5*cos (5.*(time + 6.) + 17.*p.z);
        float r = .5 + .1*(x + y + z);
        d = length (p) - r;
    }

    objectUVW = p;

    return d;
}

float map (in vec3 p, in int type, inout vec3 objectUVW, inout int id) {
    float g = p.y + 2.;
    float w = p.z + 2.;
    vec3 s = p;
    vec3 t;
    float b = sdThing (p, type, t);
    float d = min (g, min (w, b));
    if (d == g || d == w) {
        objectUVW = s;
        id = 0;
    } else if (d == b) {
        objectUVW = t;
        id = 1;
    }
    return d;
}

float march (in vec3 ro, in vec3 rd, in int type, inout vec3 objectUVW, inout int id)
{
    float t = .0;
    float d = .0;
    vec3 p = vec3 (.0);
    for (int i = 0; i < 64; ++i) {
        p = ro + d*rd;
        t = map (p, type, objectUVW, id);
        if (abs (t) < .0001*(1. + .125*t)) break;
        d += t*.75;
    }
    return d;
}

vec3 normal (in vec3 p, in int type) {
    vec3 ignored1;
    int ignored2;
    float d = map (p, type, ignored1, ignored2);
    vec2 e = vec2 (.001, .0);
    return normalize (vec3 (map(p + e.xyy, type, ignored1, ignored2),
                            map(p + e.yxy, type, ignored1, ignored2),
                            map(p + e.yyx, type, ignored1, ignored2)) - d);
}

float shadow (in vec3 p, in vec3 n, in vec3 ldir, in float ldist, in int type) {
    vec3 ignored1;
    int ignored2;
    float d2w = march (p + .01*n, ldir, type, ignored1, ignored2);
    return ldist < d2w ? 1. : .5;
}

vec3 shade (in vec3 ro,
            in vec3 rd,
            in float d,
            in vec3 n,
            in vec3 lc,
            in vec3 lp,
            in float lshiny,
            in int type,
            in vec3 objectUVW,
            in int id) {
    vec3 amb = vec3 (.05);
    vec3 p = ro + d*rd;
    vec3 ldir = normalize (lp - p);
    float ldist = distance (lp, p);
    float diff = max (.0, dot (n, ldir));
    float att = 4./(ldist*ldist);
    float li = 2.;
    vec3 mat = vec3 (.0);
    if (id == 1 && type == 0) { // wavy ball
        float m = smoothstep (.1, .2, .5 + .5*(cos (40.*objectUVW.x) * cos(40.*objectUVW.z)));
        mat = mix (vec3 (1.), vec3 (.0), m);
    }
    else if (id == 1 && type == 1) { // turning cube
        float m = smoothstep (.1, .2, .5 + .5*cos (20.*objectUVW.x));
        float n = smoothstep (.1, .2, .5 + .5*cos (20.*objectUVW.y));
        float o = smoothstep (.1, .2, .5 + .5*cos (20.*objectUVW.z));
        mat = mix (vec3 (.125, .0, .25), vec3 (1., 1., 0), m*n*o);
    }
    else if (id == 1 && type == 2) { // spiky ball
        float m = smoothstep (.2, .4, .5 + .5*cos (500.*objectUVW.x*objectUVW.y*objectUVW.z));
        mat = mix (vec3 (.125, .25, .5), vec3 (.5, .25, .125), m);
    }
    else
        mat = vec3 (.25);

    float s = shadow (p, n, ldir, ldist, type);
    vec3 h = normalize(-rd + ldir);
    float sp = pow (max (.0, dot (n, h)), lshiny);

    return amb + att*s*(diff*lc*li*mat + sp*vec3 (1.));
}

vec3 cam (in vec2 uv, in vec3 ro, in vec3 aim, in float zoom) {
    vec3 f = normalize (aim - ro);
    vec3 wu = vec3 (.0, 1., .0);
    vec3 r = normalize (cross (wu, f));
    vec3 u = normalize (cross (f, r));
    vec3 c = ro + f*zoom;
    return normalize (c + r*uv.x + u*uv.y - ro);
}

vec3 miniRaymarcher (in vec2 uv,
                     in vec3 lc,
                     in vec3 lp,
                     in float lshiny,
                     in int type,
                     in float offset,
                     in float aspect)
{
    uv = uv*2. - 1.;
    uv.x *= aspect;

    vec3 ro = vec3 (2.*cos(time + offset), .75, 1.);
    vec3 aim = vec3 (.0);
    float zoom = 2.;
    vec3 rd = cam (uv, ro, aim, zoom);
    vec3 objectUVW = vec3 (.0);
    int id = 0;
    float d = march (ro, rd, type, objectUVW, id);
    vec3 p = ro + d*rd;
    vec3 n = normal (p, type);
    vec3 col = shade (ro, rd, d, n, lc, lp, lshiny, type, objectUVW, id);
    col += shade (ro, rd, d, n, lc, lp + vec3 (-1., .0, .0), lshiny, type, objectUVW, id);
    col += shade (ro, rd, d, n, lc, lp + vec3 (1., .0, 1.), lshiny, type, objectUVW, id);

    col *= 1. - .25*length (uv);

    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy*2. - 1.;
    uv.x *= resolution.x/resolution.y;
    uv *= r2d (20.*cos (time));
    uv *= 1. + .25*length (vec2 (uv.x + .3*cos(2.*time + 8.*uv.y), uv.y));

    vec3 col = vec3 (.0);
    vec2 scale = 1.125*vec2 (1., 1.75);
    vec2 grid = fract (uv*scale);
    vec2 cell = floor (uv*scale);
    float aspect = scale.y/scale.x;

    uv.x += .5*(time+15.)*abs ((fbm (vec3 (cell.y + .75))));
    grid = fract (uv*scale);
    cell = floor (uv*scale);

    float d = length (grid*2. - 1.) - .02;
    float m = smoothstep (.01, .02, d);
    col = vec3 (1. - m);
    float r = fbm (vec3(cell+1., cell.x));
    float g = fbm (vec3(cell+2., cell.y));
    float b = fbm (vec3(cell.x, cell+3.));
    float x = fbm (vec3(cell+2., cell.x));
    float y = fbm (vec3(cell+4., cell.y));
    float z = fbm (vec3(cell.x, cell+2.));
    float shiny = 60.*fbm (vec3(cell, cell.x));
    float offset = cos (time + cell.x + cell.y);
    col = miniRaymarcher (grid,
                          vec3 (r, g, b),
                          vec3 (x, y, z),
                          shiny,
                          int(mod (floor(cell.x + cell.y),3.)),
                          offset,
                          aspect);

    col = col/(1. + col);
    col = pow (col, vec3 (1./2.2));
    col *= mix (1., .5, .5 + .5*cos (600.*uv.y));

    glFragColor = vec4 (col, 1.);
}
