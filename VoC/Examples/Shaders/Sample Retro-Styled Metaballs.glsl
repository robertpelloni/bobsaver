#version 420

// original https://www.shadertoy.com/view/ts2SRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Retro-styled non-realistic metaballs with iteration glow.
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

const float EPSILON = .001;
const int MAX_ITER = 48;
const float STEP_BIAS = 1.1;

mat2 r2d (in float a) {
    float c = cos (radians (a));
    float s = sin (radians (a));
    return mat2 (vec2(c, s), vec2(-s, c));
}

float opCombine (in float d1, in float d2, in float r)
{
    float h = clamp (.5 + .5 * (d2 - d1) / r, .0, 1.);
    return mix (d2, d1, h) - r * h * (1. - h);
}

float sdSphere (in vec3 p, in float r) {
    return length (p) - r;
}

// using a slightly adapted implementation of iq's simplex noise from
// https://www.shadertoy.com/view/Msf3WH with hash(), noise() and fbm()
vec2 hash (in vec2 p)
{
    p = vec2 (dot (p, vec2 (127.1, 311.7)),
              dot (p, vec2 (269.5, 183.3)));

    return -1. + 2.*fract (sin (p)*43758.5453123);
}

float noise (in vec2 p)
{
    const float K1 = .366025404;
    const float K2 = .211324865;

    vec2 i = floor (p + (p.x + p.y)*K1);
    
    vec2 a = p - i + (i.x + i.y)*K2;
    vec2 o = step (a.yx, a.xy);    
    vec2 b = a - o + K2; 
    vec2 c = a - 1. + 2.*K2;

    vec3 h = max (.5 - vec3 (dot (a, a), dot (b, b), dot (c, c) ), .0);

    vec3 n = h*h*h*h*vec3 (dot (a, hash (i + .0)),
                           dot (b, hash (i + o)),
                           dot (c, hash (i + 1.)));

    return dot (n, vec3 (70.));
}

float fbm (in vec2 p, in int iters)
{
    mat2 rot = r2d (35.);
    float d = .0;
    float f = 1.;
    float fsum = .0;

    for (int i = 0; i < iters; ++i) {
        d += f*noise (p);
        p *= rot;
        fsum += f;
        f *= .5;
    }
    d /= fsum;

    return d;
}

float scene (in vec3 p) {
    float t = 2.*time;
    vec3 pBottom = p;
    pBottom.x += 3.*time;
    float bottom = pBottom.y + 1. + .25*fbm(pBottom.xz, 4);

    float t4 = 2. * time;
    float t5 = 2.5 * time;
    float t6 = 1.75 * time;
    float t7 = 2.5 * time;
    float r1 = .1 + .3 * (.5 + .5 * sin (2.*t4));
    float r2 = .1 + .25 * (.5 + .5 * sin (3.*t5));
    float r3 = .1 + .3 * (.5 + .5 * sin (4.*t6));
    float r4 = .1 + .25 * (.5 + .5 * sin (5.*t7));

    float t1 = 1.5 * time;
    float t2 = 2. * time;
    float t3 = 2.5 * time;
    vec3 offset1 = vec3 (-.1*cos(t1), .1, -.2*sin(t2));
    vec3 offset2 = vec3 (.2, .2*cos(t2), .3*sin(t3));
    vec3 offset3 = vec3 (-.2*cos(t3), -.2*sin(t3), .3);
    vec3 offset4 = vec3 (.1, -.4*cos(t2), .4*sin(t2));
    vec3 offset5 = vec3 (.4*cos(t1), -.2, .3*sin(t1));
    vec3 offset6 = vec3 (-.2*cos(t3), -.4, -.4*sin(t1));
    vec3 offset7 = vec3 (.3*sin(t2), -.6*cos(t2), .6);
    vec3 offset8 = vec3 (-.3, .5*sin(t3), -.4*cos(t1));

    float ball1 = sdSphere (p + offset1, r4);
    float ball2 = sdSphere (p + offset2, r2);
    float metaBalls = opCombine (ball1, ball2, r1);

    ball1 = sdSphere (p + offset3, r1);
    ball2 = sdSphere (p + offset4, r3);
    metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r2);

    ball1 = sdSphere (p + offset5, r3);
    ball2 = sdSphere (p + offset6, r2);
    metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r3);

    ball1 = sdSphere (p + offset7, r3);
    ball2 = sdSphere (p + offset8, r4);
    metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r4);

    vec3 pTop = p;
    float top = -(pTop.y - 3.);

    return min (metaBalls, min (bottom, top));
}

float raymarch (in vec3 ro, in vec3 rd, inout int iter) {
    float t = .0;
    float d = .0;
    for (int i = 0; i < MAX_ITER; ++i) {
        vec3 p = ro + d * rd;
        t = scene (p);
        if (abs (t) < EPSILON * (1. + .125*t)) break;
        d += t*STEP_BIAS;
        iter = i;
    }

    return d;
}

vec3 shade (in vec3 ro, in vec3 rd, in float d) {
    vec3 p = ro + d*rd;
    vec3 balls = p;
    balls.xz *= r2d (-95.*time);
    balls.zy *= r2d (63.*time);

    float floorPhase = cos (45.*p.x);
    float ballsPhase = cos (75.*balls.z);
    float floorMask = smoothstep (.01*d, .0025*d, (.5 + .5*floorPhase));
    float ballsMask = smoothstep (.01*d, .0025*d, (.5 + .5*ballsPhase));
    vec3 floorColor = mix (vec3 (.3, .3, 1.), vec3 (.0), 1. - floorMask);
    vec3 ballsColor = mix (vec3 (1., .3, .3), vec3 (.0), 1. - ballsMask);

    // don't do material assignment like this, it's a hack and I'm lazy
    bool isMetaBalls = (p.y > -.75 && p.y < 1.);

    float brightness = 5. / pow (.25*d*d, 1.75);
    ballsColor += vec3 (1., .2, .1)*brightness;
    floorColor += vec3 (.1, .2, 1.)*brightness;

    return isMetaBalls ? ballsColor : floorColor;
}

vec3 camera (in vec2 uv, in vec3 ro, in vec3 aim, in float zoom)
{
    vec3 camForward = normalize (vec3 (aim - ro));
    vec3 worldUp = vec3 (.0, 1., .0);
    vec3 camRight = normalize (cross (worldUp, camForward));
    vec3 camUp = normalize (cross (camForward, camRight));
    vec3 camCenter = ro + camForward * zoom;
        
    return normalize (camCenter + uv.x*camRight + uv.y*camUp - ro);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvRaw = uv;
    uv = uv*2. - 1.;
    uv.x *= resolution.x/resolution.y;

    float angle = radians (300. + 30.*time);
    float dist = 3.;
    vec3 ro = vec3 (dist*cos (angle), 2., dist*sin (angle));
    vec3 aim = vec3 (.0);
    float zoom = 2. + .5*cos (time);
    vec3 rd = camera (uv, ro, aim, zoom);

    int iter = 0;
    float d = raymarch (ro, rd, iter);
    float fog = 1. / (1. + d*d*.25);
    float glow = float (iter) / float (MAX_ITER);
    vec3 p = ro + d * rd;

    vec3 col = shade (ro, rd, d) + pow (glow, 1.05) * vec3 (1.);

    col *= fog;
    col = col / (.75 + col);
    col = .1 * col + .9*sqrt (col);
    col *= .8 + .2 * pow (16.*uvRaw.x*uvRaw.y*(1. - uvRaw.x)*(1. - uvRaw.y), .3);

    glFragColor = vec4 (col, 1.);
}

