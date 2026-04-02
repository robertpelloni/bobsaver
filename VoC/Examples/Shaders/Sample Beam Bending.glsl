#version 420

// original https://www.shadertoy.com/view/wdSXzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Beam bending - Just shader-writing practice of a random idea.
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

mat2 r2d (float deg) {
    float rad = radians (deg);
    float c = cos (rad);
    float s = sin (rad);
    return mat2 (c,s,-s,c);
}

float texNoise (vec2 p) {
    return 0.0;//texture (iChannel0, p).r;
}

float smin (float d1, float d2, float k) {
    float h = clamp (.5 + .5*(d2 - d1)/k, .0, 1.);
    return mix (d2, d1, h) - h*k*(1. - h);
}

float map (vec3 p, inout int id, inout vec3 pout) {
    float size = 3.;
    float offset = cos (.2*time);
    float offset2 = cos (time);
    float ground = p.y + size + offset2 + .75*texNoise (offset+.05*p.xz+.1*time);
    ground = min (ground, -p.y + size + offset2 + .75*texNoise (offset-.1*time+.075*p.xz + 1.));
    float wall = p.z + 3.*size;
    wall = min (wall, -p.z + 3.*size);
    wall = min (wall, p.x + 2.*size);
    wall = min (wall, -p.x + 2.*size);
    vec3 pbar = p;
    pbar.xz *= r2d (25.*cos (pbar.y + sin(3.*time)));
    pbar.xy *= r2d (9.*cos (pbar.y + sin(4.*time)));
    pbar.yz *= r2d (9.*sin (pbar.y + sin(2.*time)));

    pbar.x += .2*cos (pbar.y + 2.*time);
    pbar.z += -(.3*(cos(2.*time)))*sin (2.*pbar.y + 2.*time);
    float thickness = .5-.2*offset2*cos (2.*pbar.y+3.*time);
    vec3 s = vec3 (thickness, 3.5, thickness);
    float bar = length (max (vec3 (.0), abs (pbar) - s)) - .1;
    float d = min (wall, smin (ground, bar, 1.5));
    id = 1;
    pout = pbar;
    if (d == wall) {id = 2; pout = p;}
    return d;
}

float march (vec3 ro, vec3 rd, inout int id, inout vec3 pout)
{
    float t = .0;
    float d = .0;
    for (int i = 0; i< 64; ++i) {
        vec3 p = ro+d*rd;
        t = map (p, id, pout);
        if (abs (t) < .000000001*(1. + .125*t)) break;
        d += t*.5;
    }
    return d;
}

vec3 norm (vec3 p){
    int foo;
    vec3 bar;
    float d = map (p, foo, bar);
    vec2 e = vec2 (.01, .0);
    return normalize (vec3 (map (p+e.xyy, foo, bar),
                            map (p+e.yxy, foo, bar),
                            map (p+e.yyx, foo, bar))-d);
}

float sha (vec3 p, vec3 lp, vec3 n, vec3 ldir) {
    float d2l = distance (lp, p);
    int foo;
    vec3 bar;
    float d2w = march (p+.01*n, ldir, foo, bar);
    return d2l < d2w ? 1. : .1;
}

vec3 shade (vec3 ro, vec3 rd, float d, vec3 n, vec3 lp, vec3 lc, float li, int id, vec3 pout) {
    vec3 p = ro + d*rd;
    float ld = distance (p, lp); 
    vec3 ldir = normalize (lp - p);
    float att = 12. / (ld*ld);
    vec3 mat = vec3 (1., .0, .0);
    if (id == 1) mat = vec3 (.0);
    if (id == 2) mat = mix (vec3 (.0), vec3 (1.), smoothstep (.0, .5, sin (3.*p.y+5.*time)));
    float s = sha (p, lp, n, ldir);
    float diff = max (.0, dot (n, ldir));
    vec3 h = normalize (-rd + ldir);
    float shiny = 40.;
    float sp = pow (max (.0, dot (n, h)), shiny);
    vec3 am = vec3 (.05);
    return att*s*(am + diff*lc*li*mat + sp*vec3 (1.));
}

vec3 cam (vec2 uv, vec3 ro, vec3 aim, float z) {
    vec3 f = normalize (aim - ro);
    vec3 wu = vec3 (.0, 1., .0);
    vec3 r = normalize (cross (wu, f));
    vec3 u = normalize (cross (f, r));
    vec3 c = ro + f*z;
    return normalize(c + r*uv.x + u*uv.y - ro);
}

void main(void)
{
    vec2 uvRaw = gl_FragCoord.xy/resolution.xy;
    vec2 uv = uvRaw*2. - 1.;
    uv.x *= resolution.x/resolution.y;
    uv *= 1. + .25*length (uv);

    float dist = 3.;
    vec3 ro = vec3 (dist*cos (time), .0, dist*sin(time));
    vec3 rd = cam (uv, ro, vec3 (.0), 1.25);
    int id = 0;
    vec3 pout = vec3 (.0);
    float d = march (ro, rd, id, pout);
    vec3 p = ro + d*rd;
    vec3 n = norm (p);
    vec3 c = shade (ro, rd, d, n, vec3 (.0, .0, 2.), vec3 (.9, .85, .3), 2.,id, pout);
    c += shade (ro, rd, d, n, vec3 (2., 2., -2.), vec3 (.5, .5, .9), 2.,id, pout);

    if (id == 1) {
        ro = p + .01*n;
        rd = normalize (reflect (rd, n));
        d = march (ro, rd, id, pout);
        p = ro + d*rd;
        n = norm(p);
        vec3 rc = shade (ro, rd, d, n, vec3 (.0, .0, 2.), vec3 (.9, .85, .3), 2.,id, pout);
        rc += shade (ro, rd, d, n, vec3 (2., 2., -2.), vec3 (.3, .3, .9), 2.,id, pout);
        c += .3*rc;
    }
    c=c/(1.25+c*.5);
    c*=1.-.65*length(uvRaw*2.-1.);
    c*=mix(1.,.75,cos(500.*uvRaw.y));
    c=pow(c,vec3(1./2.2));

    glFragColor = vec4(c,1.);
}
