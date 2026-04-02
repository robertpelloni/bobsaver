#version 420

// original https://www.shadertoy.com/view/7dfczS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 128
#define MIN_DIST 0.01
#define MAX_DIST 100.

struct PointLight {
    vec3 pos;
    vec3 colour;
};

// ------------------------------------------------------------------
// SDF utilities
//
// ----------------
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Thanks Inigo Quilez :)

float union_(float a, float b) {
    return min(a, b);
}

float intersection(float a, float b) {
    return max(a, b);
}

float smoothUnion(float a, float b, float smoothing) {
    float h = clamp(0.5 + 0.5 * (b-a)/smoothing, 0., 1.);
    return mix(b, a, h) - smoothing*h*(1.0-h);
}

float smoothIntersection(float a, float b, float smoothing) {
    float h = clamp(0.5 - 0.5 * (b-a)/smoothing, 0., 1.);
    return mix(b, a, h) + smoothing*h*(1.0-h);

}

vec3 repeat(vec3 pt, vec3 centre) {
    return mod(pt + 0.5*centre, centre) - 0.5*centre;
}

float sphereDist(vec3 pt, vec4 sphere) {
    return length(pt - sphere.xyz) - sphere.w;
}

float rand(vec3 n) { 
    return fract(sin(dot(n, vec3(12.9898, 4.1414, 9.1919))) * 43758.5453);
}

float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(i+vec3(0,0,0)), 
                        hash(i+vec3(1,0,0)),f.x),
                   mix( hash(i+vec3(0,1,0)), 
                        hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(i+vec3(0,0,1)), 
                        hash(i+vec3(1,0,1)),f.x),
                   mix( hash(i+vec3(0,1,1)), 
                        hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

float layeredNoise(vec3 q, float scales[5], int nScales) {
    float f = 0.;
    for (int i = 0; i < nScales; i++) {
        f += scales[i]*noise( q ); q = q*2.01;
    }
    return f;
}

const float noiseScales[5] = float[5](
  0.5000,
  0.2500,
  0.1250,
  0.0625,
  0.03125
);

// ------------------------------------------------------------------
// Ray marched smartie

float smartie(vec3 pt) {
    return smoothIntersection(
        sphereDist(pt, vec4(0, 0, 1, 1.2)),
        sphereDist(pt, vec4(0, 0, -1, 1.2)),
        0.11
    );
}

float bumpySmartie(vec3 pt) {
    vec3 noisy = pt + layeredNoise(pt * 10., noiseScales, 3) * 0.0025;
    return smartie(noisy);
}

const float INFINITY = 999999.;
vec2 sceneSdf(vec3 pt) {
    float closest = INFINITY;
    float closestColourSelector;
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 4; x++) {
            float colourSelector = rand(vec3(x, y, 5));
            vec3 offs = vec3(
                (rand(vec3(x, y, 0))-0.5) * 4.,
                (rand(vec3(x, y, 1))-0.5) * 5.,
                (rand(vec3(x, y, 2))-0.5) * 2.5
            );
            float isect = bumpySmartie(pt + offs);
            if (isect < closest) {
                closest = isect;
                closestColourSelector = colourSelector;
           }
        }
    }

    return vec2(closest, closestColourSelector);
}

vec3 normalAtScenePoint(vec3 pt) {
    vec2 isect = sceneSdf(pt);
    float distAtPt = isect.x;
    vec2 smallStep = vec2(0.0001, 0);
    return normalize(
        vec3(
            sceneSdf(pt + smallStep.xyy).x - sceneSdf(pt - smallStep.xyy).x,
            sceneSdf(pt + smallStep.yxy).x - sceneSdf(pt - smallStep.yxy).x,
            sceneSdf(pt + smallStep.yyx).x - sceneSdf(pt - smallStep.yyx).x
        )
    );
}

vec2 marchRay(vec3 ro, vec3 rd) {
    vec2 dist = vec2(-1., 0);
    for (int step = 0; step < MAX_STEPS; step++) {
        vec3 pt = ro + rd*dist.x;
        vec2 sceneDist = sceneSdf(pt);
        dist.x += sceneDist.x;
        dist.y = sceneDist.y;
        if (dist.x < MIN_DIST || dist.x > MAX_DIST) {
            break;
        }
    }
    if (dist.x > MAX_DIST) {
        dist.x = -1.;
    }
    return dist;
}

// ------------------------------------------------------------------
// Surface and illumination characteristics

const vec3 backgroundColor = vec3(0.2);
const vec3 ambientLight = vec3(0.1, 0.02, 0.02);
const PointLight light1 = PointLight(vec3(-5, -3, -2), vec3(0.9, 0.8, 0.7));
const PointLight light2 = PointLight(vec3(3, 5, 2), vec3(0.9, 0.8, 0.7));

const vec3 smartieColours[6] = vec3[6](
    vec3(0., 0.6, 0.95),  // blue
    vec3(.9, .45, .1),    // orange
    vec3(0.5, 0.9, 0.5),  // 
    vec3(0.9, 0.2, 0.),
    vec3(0.4, 0.2, 0.2),
    vec3(0.8, 0.8, 0.2)   // yellow
);
vec3 colourFromObjectIdent(float ident) {
    int index = int(floor(ident * float(smartieColours.length())));
    return smartieColours[index];
}

vec3 diffuseLight(vec3 pt, vec3 normal, PointLight light, vec3 colour) {
    vec3 lightDir = normalize(light.pos - pt);
    return max(dot(normal, lightDir), 0.) * colour;
}

vec3 diffuse(vec3 pt, vec3 normal, vec3 colour) {
    return diffuseLight(pt, normal, light1, colour) + diffuseLight(pt, normal, light2, colour);
}

vec3 specularLight(vec3 pt, vec3 normal, vec3 viewDir, PointLight light) {
    vec3 lightDir = normalize(light.pos - pt);
    vec3 r = reflect(-lightDir, normal);
    float rDotV = max(dot(r, viewDir), 0.);
    return 0.8 * pow(rDotV, 40.) * light.colour;
}

vec3 specular(vec3 pt, vec3 normal, vec3 viewDir) {
    return specularLight(pt, normal, viewDir, light1) + specularLight(pt, normal, viewDir, light2);
}

// ------------------------------------------------------------------
// Shader entry point

void main(void) {
    // Normalised device coordinates with aspect ratio: (-1, 1) x (-aspect, aspect)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    // Camera model - rotating around the look at point with time
    float camDist = 4.;
    float rotSpeed = 0.5;
    float zoom = 1.;
    vec3 ro = vec3(camDist * sin(time * rotSpeed), 1, -camDist * cos(time * rotSpeed));
    //ro = vec3(0, 0, camDist);
    vec3 lookAt = vec3(0.);

    // Camera -> image plane
    vec3 forward = normalize(lookAt - ro);
    vec3 right = cross(vec3(0., 1., 0.), forward);
    vec3 up = cross(forward, right);
    vec3 centre = ro + forward * zoom;

    // Shoot ray through pixel into scene
    vec3 pixelPos = centre + uv.x*right + uv.y*up;
    vec3 rd = normalize(pixelPos - ro);

    // Intersect with scene
    vec3 col = backgroundColor;
    vec2 isect = marchRay(ro, rd);
    float sceneMinDist = isect.x;
    if (sceneMinDist >= 0.) {
        // Pixel colour = diffuse surface colour + specular highlights + ambient colour
        vec3 isectPt = ro + rd*sceneMinDist;
        vec3 isectNormal = normalAtScenePoint(isectPt);

        vec3 colour = colourFromObjectIdent(isect.y);
        vec3 diffuseCol = diffuse(isectPt, isectNormal, colour);
        vec3 specCol = specular(isectPt, isectNormal, rd);
        col = diffuseCol + specCol + ambientLight;
    }
    glFragColor = vec4(col,1);
}
