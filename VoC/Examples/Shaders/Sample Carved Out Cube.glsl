#version 420

// original https://www.shadertoy.com/view/tdsSzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// It was meant to become a carved out tunnel. You can drag the ball around with
// the mouse (LMB pressed). Technically it has a cave structure in the cube. It
// is 'just' missing the corresponding camera-path to follow it ;)
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

const int MAX_ITER    = 64;
const float STEP_SIZE = .6;
const float EPSILON   = .001;
const float PI = 3.14159265359;

mat2 r2d (in float a)
{
    float c = cos(a);
    float s = sin (a);
    return mat2 (vec2 (c, s), vec2 (-s, c));
}

struct Result {
    float d;
    int id;
};

float sdSphere (in vec3 p, float r)
{
    return length (p) - r;
}

float sdBox (in vec3 p, in vec3 size, in float r)
{
  vec3 d = abs(p) - size;
  return min (max (d.x, max (d.y,d.z)), .0) + length (max (d, .0)) - r;
}

// PBR toolbox
float DistributionGGX (in vec3 N, in vec3 H, in float roughness)
{
    float a2     = roughness * roughness;
    float NdotH  = max (dot (N, H), .0);
    float NdotH2 = NdotH * NdotH;

    float nom    = a2;
    float denom  = (NdotH2 * (a2 - 1.) + 1.);
    denom        = PI * denom * denom;

    return nom / denom;
}

float GeometrySchlickGGX (in float NdotV, in float roughness)
{
    float nom   = NdotV;
    float denom = NdotV * (1. - roughness) + roughness;

    return nom / denom;
}

float GeometrySmith (in vec3 N, in vec3 V, in vec3 L, in float roughness)
{
    float NdotV = max (dot (N, V), .0);
    float NdotL = max (dot (N, L), .0);
    float ggx1 = GeometrySchlickGGX (NdotV, roughness);
    float ggx2 = GeometrySchlickGGX (NdotL, roughness);

    return ggx1 * ggx2;
}

vec3 fresnelSchlick (in float cosTheta, in vec3 F0, float roughness)
{
    return F0 + (max (F0, vec3(1. - roughness)) - F0) * pow (1. - cosTheta, 5.);
}

float opCombine (in float d1, in float d2, in float r)
{
    float h = clamp (.5 + .5 * (d2 - d1) / r, .0, 1.);
    return mix (d2, d1, h) - r * h * (1. - h);
}

float hashn (vec3 p, float t)
{
    p = fract (p*.3183099 + .1);
    p *= 17.;
    return max (fract (p.x*p.y*p.z*(p.x + p.y + p.z)), 1. - t); 
}

float noise (in vec3 x, in float t)
{
    vec3 p = floor (x);
    vec3 f = fract (x);
    f = f*f*(3. - 2.*f);
    
    return mix(mix(mix( hashn(p+vec3(0,0,0), t), 
                        hashn(p+vec3(1,0,0), t),f.x),
                   mix( hashn(p+vec3(0,1,0), t), 
                        hashn(p+vec3(1,1,0), t),f.x),f.y),
               mix(mix( hashn(p+vec3(0,0,1), t), 
                        hashn(p+vec3(1,0,1), t),f.x),
                   mix( hashn(p+vec3(0,1,1), t), 
                        hashn(p+vec3(1,1,1), t),f.x),f.y),f.z);
}

vec2 mapToScreen (in vec2 p)
{
    vec2 res = p;
    res = res * 2. - 1.;
    res.x *= resolution.x / resolution.y;
    
    return res;
}

float dd = .0;

// ray-marching stuff
Result scene (in vec3 p)
{
    float ground = p.y + 1.;

    vec3 sphereCenter = p;
    vec3 boxCenter = p;
    float offsetX = -2.;//-2. * (mouse*resolution.xy.x / resolution.x * 2. - 1.);
    float offsetY = -2.;//2. * (mouse*resolution.xy.y / resolution.y * 2. - 1.);
    sphereCenter -= vec3 (offsetX, .25, offsetY);
    boxCenter -= vec3 (.0, .0, 1.25);
    boxCenter.xz *= r2d (-time);

    float sphere = sdSphere (sphereCenter, .6);
    float box = sdBox (boxCenter, vec3 (.8), .15);

    float variation = 4. + 6.*(.5 + .5*cos (4.));
    vec3 structureCenter = boxCenter;
    structureCenter.xz *= r2d (1.25*time);
    structureCenter.yz *= r2d (.75*time);
    float f = 2. + 1.5*(.5 + .5*cos (2.5*time));
    float structure = noise (f*structureCenter, variation) - .65 + (sin (time) + 1.)*.05;
    float combined = opCombine (box, sphere, .25);
    float combinedAndCut = max (combined, structure);
    dd = combinedAndCut;

    Result res = Result (.0, 0);
    res.d = min (combinedAndCut, ground);
    res.id = (res.d == ground ) ? 1 : 2;
    return res;
}

Result raymarch (in vec3 ro, in vec3 rd)
{
    Result res = Result (.0, 0);

    for (int i = 0; i < MAX_ITER; i++)
    {
        vec3 p = ro + res.d * rd;
        Result tmp = scene (p);
        if (abs (tmp.d) < EPSILON*(1. + .125*tmp.d)) return res;
        res.d += tmp.d * STEP_SIZE;
        res.id = tmp.id;
    }

    return res;
}

vec3 normal (in vec3 p)
{
    vec2 e = vec2(.0001, .0);
    float d = scene (p).d;
    vec3 n = vec3 (scene (p + e.xyy).d - d,
                   scene (p + e.yxy).d - d,
                   scene (p + e.yyx).d - d);
    return normalize(n);
}

float shadow (in vec3 ro, in vec3 rd)
{
    float result = 1.;
    float t = .1;
    for (int i = 0; i < MAX_ITER; i++) {
        float h = scene (ro + t * rd).d;
        if (h < 0.00001) return .0;
        result = min (result, 8. * h/t);
        t += h;
    }

    return result;
}

vec3 shadePBR (in vec3 ro, in vec3 rd, in float d, in int id)
{
    vec3 p = ro + d * rd;
    vec3 nor = normal (p);

    // "material" hard-coded for the moment
    float mask1 = .5 + .5 * cos (20.* p.x * p.z);
    float mask2 = 0.;
    float mask = (id == 1) ? mask1 : mask2;
    float f = fract (dd*2.);
    vec3 albedo1 = vec3 (1. - smoothstep (.025, .0125, f));
    vec3 albedo2 = vec3 (.05, .65, .05);
    vec3 albedo = (id == 1) ? albedo1 : albedo2;
    float metallic  = (id == 1) ? .1 : .9;
    float roughness = (id == 1) ? .9 : .1;
    float ao = 1.;

    // lights hard-coded as well atm
    vec3 lightColors[2];
    lightColors[0] = vec3 (.8, .8, .9) * 20.;
    lightColors[1] = vec3 (.9, .8, .8) * 20.;

    vec3 lightPositions[2];
    lightPositions[0] = p + vec3 (.5, .75, -1.5);
    lightPositions[1] = p + vec3 (-.3, .25, -.5);

    vec3 N = normalize (nor);
    vec3 V = normalize (ro - p);

    vec3 F0 = vec3 (0.04); 
    F0 = mix (F0, albedo, metallic);
    vec3 kD = vec3(.0);
                   
    // reflectance equation
    vec3 Lo = vec3 (.0);
    for(int i = 0; i < 2; ++i) 
    {
        // calculate per-light radiance
        vec3 L = normalize(lightPositions[i] - p);
        vec3 H = normalize(V + L);
        float distance    = length(lightPositions[i] - p);
        float attenuation = 1. / (distance * distance);
        vec3 radiance     = lightColors[i] * attenuation;
            
        // cook-torrance brdf
        float aDirect = .125 * pow (roughness + 1., 2.);
        float aIBL = .5 * roughness * roughness;
        float NDF = DistributionGGX(N, H, roughness);        
        float G   = GeometrySmith(N, V, L, roughness);      
        vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0, roughness);
            
        vec3 kS = F;
        kD = vec3(1.) - kS;
        kD *= 1. - metallic;      
            
        vec3 nominator    = NDF * G * F;
        float denominator = 4. * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
        vec3 specular     = nominator / max(denominator, .001);  

        // add to outgoing radiance Lo
        float NdotL = max(dot(N, L), 0.0);                
        Lo += (kD * albedo / PI + specular) * radiance * NdotL; 
        Lo *= shadow (p, L);
    }

    vec3 ambient = (kD * albedo) * ao;

    return ambient + Lo;
}

vec3 camera (in vec2 uv, in vec3 ro, in vec3 aim, in float zoom)
{
    vec3 camForward = normalize (vec3 (aim - ro));
    vec3 worldUp = vec3 (.0, 1., .0);
    vec3 camRight = normalize (cross (camForward, worldUp));
    vec3 camUp = normalize (cross (camRight, camForward));
    vec3 camCenter = normalize (ro + camForward * zoom);

    return normalize ((camCenter + uv.x*camRight + uv.y*camUp) - ro);
}

void main(void)
{
    // normalizing and aspect-correction
    vec2 uvRaw = gl_FragCoord.xy/resolution.xy;
    vec2 uv = uvRaw;
    uv = uv * 2. - 1.;
    uv.x *= resolution.x / resolution.y;

    // set up "camera", view origin (ro) and view direction (rd)
    vec3 ro = vec3 (0.0, 2.0, -5.0);
    vec3 aim = vec3 (0.0, 2.0, 0.0);
    float zoom = 1.;
    vec3 rd = camera (uv, ro, aim, zoom);

    // do the ray-march...
    Result res = raymarch (ro, rd);
    float fog = 1. / (1. + res.d * res.d * .1);
    vec3 c = shadePBR (ro, rd, res.d, res.id);

    // tonemapping, "gamma-correction", tint, vignette
    c *= fog;
    c = c / (1. + c);
    c = .2 * c + .8 * sqrt (c);
    c *= vec3 (.9, .8, .7);
    c *= .2 + .8*pow(16.*uvRaw.x*uvRaw.y*(1. - uvRaw.x)*(1. - uvRaw.y), .3);

    glFragColor = vec4(c, 1.);
}

