#version 420

// original https://www.shadertoy.com/view/7dB3Wd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Twisty chocolate-bar torus - some version of eye-candy ;)
//
// Copyright 2021 Mirco Müller
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

// lower AA_SIZE to 2 or 1, if it runs too slow
const int AA_SIZE = 3;
const float PI = 3.14159265359;
const int MAX_ITER = 64;
const float STEP_BIAS = .75;
const float EPSILON = .0001;
const float MAX_DIST = 25.;

mat2 r2d (float rad)
{
    float c = cos (rad);
    float s = sin (rad);

    return mat2 (c, s, -s, c);
}

float sdBox2D (vec2 p, vec2 size, float r)
{
    vec2 q = abs(p) - size;
    return length(max(q,0.0)) + min(max(q.x, q.y),0.0) - r;
}

float sdTorus (vec3 p, vec3 q)
{
    float offset = q.x;
    float r1 = q.y;
    float r2 = q.z;

    float angle = atan (p.x, p.z);

    vec2 t = vec2 (length (p.xz) - r1, p.y);

    t *= r2d (3.*angle);
    t.y = abs (t.y) - offset;

    float r = r2*(1. + .5*(cos(3.*angle)));
    t *= r2d (time);
    float doubleRectProfile = sdBox2D (t, vec2 (.08, .03), r*.75);

    return doubleRectProfile;
}

float scene (vec3 p)
{
    float ground = p.y + 1.;

    float offset = .2;
    float r1 = 1.;
    float r2 = .1;
    float torus = sdTorus (p, vec3 (offset, r1, r2));

    float d = min (torus, ground); 

    return d;
}

float raymarch (vec3 ro, vec3 rd)
{
    float t = .0;
    float d = .0;
    vec3 p = vec3 (.0);
    int i = 0;

    for (; i < MAX_ITER; ++i) {
        p = ro + d*rd;
        t = scene (p);
        if (abs (t) < EPSILON*(1. - .125*t) || d > MAX_DIST) break;
        d += t*STEP_BIAS;
    }

    return d;
}

vec3 normal (vec3 p)
{
    vec2 e = vec2 (EPSILON, .0);
    float d = scene (p);
    return normalize (vec3 (scene (p + e.xyy),
                            scene (p + e.yxy),
                            scene (p + e.yyx)) - d);
}

vec3 camera (vec2 uv, vec3 ro, vec3 aim, float zoom)
{
    vec3 camForward = normalize (aim - ro);
    vec3 worldUp = vec3 (.0, 1., .0);
    vec3 camRight = normalize (cross (camForward, worldUp));
    vec3 camUp = normalize (cross (camRight, camForward));
    vec3 camCenter = normalize (camForward*zoom + ro);

    return normalize (camCenter + uv.x*camRight + uv.y*camUp - ro);
}

float shadow (vec3 p, vec3 n, vec3 lPos, vec3 lDir)
{
    float distToWorld = raymarch (p + .01*n, lDir);
    float distToLight = distance (p, lPos);

    return distToWorld < distToLight ? .3 : 1.;
}

float ao (vec3 p, vec3 n, float stepSize, int iterations, float intensity)
{
  float ao = .0; 
  float dist = .0; 

  for (int a = 1; a <= iterations; ++a) {
    dist = float (a)*stepSize;
    ao += max (.0, (dist - scene (p + n*dist))/dist);
  }

  return 1. - ao*intensity;
}

vec3 shade(vec3 ro, vec3 rd, float d, vec3 n)
{
    vec3 p = ro + d*rd;

    vec3 lPos1 = vec3 (4.*cos(time), 2., 4.*sin(.4*time));
    vec3 lDir1 = normalize (lPos1 - p);
    float lDist1 = distance (lPos1, p);
    float attn1 = 50. / (lDist1*lDist1);
    vec3 lColor1 = 5.*vec3 (1., .9, .3);

    vec3 lPos2 = vec3 (6.*cos(.3*time), 1., 6.*sin(time));
    vec3 lDir2 = normalize (lPos2 - p);
    float lDist2 = distance (lPos2, p);
    float attn2 = 60. / (lDist2*lDist2);
    vec3 lColor2 = 7.*vec3 (.2, .4, 1.);

    vec3 amb = vec3 (.1); 
    float diff1 = max (dot (n, lDir1), .0);
    float diff2 = max (dot (n, lDir2), .0);
    vec3 h1 = normalize (lDir1 - rd);
    vec3 h2 = normalize (lDir2 - rd);
    float spec1 = pow (max (dot (h1, n), .0), 40.);
    float spec2 = pow (max (dot (h2, n), .0), 40.);

    float s1 = shadow (p, n, lPos1, lDir1);
    float s2 = shadow (p, n, lPos2, lDir2);

    float ao = ao (p, n, .05, 12, .1);

    // don't do material assignment like this, this is a super lazy-ass hack!
    vec3 torusMaterial = 1.5*vec3(.2, .1, .05);
    bool isFloor = (p.y < -.5);
    float phase = cos (20.*(p.x + time));
    float mask = smoothstep (.005*d, .0025*d, .5 + .5*phase);
    vec3 floorMaterial = 1.5*mix (vec3(.9), vec3 (.1), mask);
    vec3 diffMaterial = isFloor ? floorMaterial : torusMaterial;

    return amb + ao*(attn1*s1*(diff1*diffMaterial*lColor1 + spec1) +
                     attn2*s2*(diff2*diffMaterial*lColor2 + spec2));
}

void main(void)
{
    float dist2cam = 7.;
    float azimuthAngle = 0.0;//((mouse.x*resolution.xy.x/resolution.x) * 2. - 1.) * 179.;
    float elevationAngle = 40.;// + ((mouse.y*resolution.xy.y/resolution.y) * 2. - 1.) * -30.;
    float x = dist2cam*cos (radians (azimuthAngle));
    float y = dist2cam*sin (radians (elevationAngle));
    float z = dist2cam*sin (radians (azimuthAngle));

    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv*2. - 1.;
    uv.x *= resolution.x/resolution.y;
    vec3 ro = vec3 (x, y, z);
    float fog = .0;
    float d = .0;
    vec3 aim = vec3 (.0);
    float zoom = 2.5;
    vec3 color = vec3 (.0);

    for (int x = 0; x < AA_SIZE; ++x) {
        for (int y = 0; y < AA_SIZE; ++y) {

            // anti-alias offset
            vec2 pixelOffset = vec2 (float (x), float (y))/float  (AA_SIZE);

            // normalize and aspect-correct UVs
            uv = (gl_FragCoord.xy/resolution.xy + pixelOffset/resolution.xy);
            uv = uv*2. - 1.;
            uv.x *= resolution.x/resolution.y;

            // create viewray
            vec3 rd = camera (uv, ro, aim, zoom);

            // primary/view ray
            d = raymarch (ro, rd);
            fog = 1. / (1. + d*d*.075);
            vec3 p = ro + d*rd;
            vec3 n = normal (p);
            vec3 ctmp = shade (ro, rd, d, n);
            ctmp *= fog;

            color += ctmp;
        }
    }
    color /= float (AA_SIZE*AA_SIZE);

    // distance-mist, vignette, tone-map, gamma-correct
    color = mix (color, vec3 (.2, .35, .7), pow (1. - 1./d, 90.));
    color *= 1. - .25*dot (uv, uv);
    color = color / (1. + color);
    color = .2*color + .8*sqrt (color);

    glFragColor = vec4(color, 1.);
}
