#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ft2SWt

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Gallardo - xjorma/2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

#define NO_UNROLL min(frames, 0)

const int nbPoints = 150;
const int pointsPerTurn = 30;
const float turnDuration = 3.0;
const float finalAngle = 1.19;

const float PI = radians(180.0);

const float maxDist = 10000.0;

const vec3 lightDir = normalize(vec3(0.4, 1.f, 0.7)); 
const vec3 dominoSize = vec3(0.075, 0.4, 0.2);

float smoothsteplin(in float edge0, in float edge1, in float x)
{
    return clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
}

vec3 dominoColor(float v)
{
    vec3 col = vec3(sin(v * 0.43 + 2.85), sin(v * 0.63 + 1.28), sin(v * 0.81 + 4.71)) * 0.5 + 0.5;
    return col / max(col.x, max(col.y, col.z));
}

float floorIntersect(in vec3 ro, in vec3 rd)
{
    if (rd.y < -0.01)
    {
        return ro.y / -rd.y;
    }
    return maxDist;
}

// Hash from Dave Hoskins https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

int dotsMask( in float v )
{
    int mask[6] = int[](16, 68, 84, 325, 341, 455);
    return mask[int(hash11(v) * 6.0)];
}

// Box intersection by IQ https://www.iquilezles.org/www/articles/boxfunctions/boxfunctions.htm
vec2 boxIntersection( in vec3 ro, in vec3 rd, in vec3 rad, out vec3 oN ) 
{
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    
    if( tN > tF || tF < 0.0) return vec2(-1.0); // no intersection
    
    oN = -sign(rd)*step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);

    return vec2( tN, tF );
}

vec3 getSkyColor(in vec3 rd)
{
    vec3 blue = smoothstep(.2, 1., rd.y) * vec3(0, 0, .5);
    float nDotL = clamp(dot(rd, lightDir), 0., 1.);
    vec3 highlight = vec3(pow(nDotL, 100.) * 2.0);
    return vec3(blue + highlight);
}

float rayTrace(in vec3 ro, in vec3 rd, out vec3 normal, out vec3 color)
{
    float t = time;
    float fltime = floor(t / turnDuration);
    float frtime = fract(t / turnDuration);
    float globalscale = 1.0 / (pow(0.5, 1.0 + frtime) * 2.0);
    int domino = int(floor(float(pointsPerTurn) * frtime));
    
    float dist = floorIntersect(ro, rd);
    if(dist < maxDist)
    {
        normal = vec3(0,1,0);
        color = vec3(0.5);
    }
    
    int hitDominoIte = -1;
    vec3 hitDominoNormal;
    mat4 hitDominoMatrix;
    float hitDominoScale;

    for(int i = domino + NO_UNROLL; i < nbPoints + domino; i++)
    {
        float turn = float(i) / float(pointsPerTurn);
        float theta = 2.0 * PI * turn;
        float phi = smoothsteplin((float(i) - 3.6) / float(pointsPerTurn), (float(i) + 1.0 + 0.5) / float(pointsPerTurn), frtime + 2.0) * finalAngle;
        float fadeScale = smoothsteplin(float(i) - 4.0, float(i) + 1.0, frtime * float(pointsPerTurn) + (float(nbPoints) - 5.0));
        float scale = pow(0.5, 1.0 + turn) * 2.0 * globalscale;
        vec3 pos = vec3(cos(theta), 0, sin(theta)) * scale;
        vec3 dir = vec3(-sin(theta) * cos(phi), -sin(phi), cos(theta) * cos(phi));
        vec3 up = vec3(-sin(theta) * sin(phi), cos(phi), cos(theta) * sin(phi));
        
        vec3 size = dominoSize * scale * fadeScale * 0.5;
        
        
        vec3 x = dir;
        vec3 y = up;
        vec3 z = cross(x, y);
        mat4 r = mat4(
        x.x,        y.x,        z.x,         0,
        x.y,        y.y,        z.y,         0,
        x.z,        y.z,        z.z,         0,
        size.x,        -size.y,    0,           1.0 );

        mat4 t = mat4(
        1.0,        0.0,        0.0,         0.0,
        0.0,        1.0,        0.0,         0.0,
        0.0,        0.0,        1.0,         0.0,
        -pos.x,    -pos.y,    -pos.z,     1.0 );
        
        mat4 tr = r * t;
        
        vec3 n;
        vec2 bi = boxIntersection( (tr * vec4(ro, 1)).xyz , (tr * vec4(rd, 0)).xyz, size, n);
        if(bi.x > 0.0 && bi.x < dist)
        {
            dist = bi.x;
            hitDominoIte = i;
            hitDominoNormal = n;
            hitDominoMatrix = tr;
            hitDominoScale = scale;
        }
    }
    if(hitDominoIte >= 0)
    {
        float dominoId = float(hitDominoIte) + fltime * float(pointsPerTurn);
        color =  dominoColor(dominoId);
        normal = (inverse(hitDominoMatrix) * vec4(hitDominoNormal, 0)).xyz;
        // Dots
        int msk;
        vec2 p = (hitDominoMatrix * vec4((ro + dist * rd), 1)).zy / hitDominoScale;
        if(p.y < 0.0)
        {
            msk = dotsMask(dominoId);
            p.y += dominoSize.y * 0.25;
        }
        else
        {
            msk = dotsMask(dominoId + 1.0);
            p.y -= dominoSize.y * 0.25;
        }
        for(int k = 0; k < 3; k++)
        {
            for(int l = 0; l < 3; l++)
            {
                float m = float(msk & (1 << (k * 3 + l)));
                color *= max(1.0 - m, smoothstep(0.015, 0.016, distance(p, vec2(float(k - 1) * 0.050, float(l - 1) * 0.050))));
            }
        }
    }
    return dist;
}

vec3 render(in vec3 ro, in vec3 rd)
{
    vec3 n, c;
    float d = rayTrace(ro, rd, n, c);
    
    if(d < maxDist)
    {
        vec3 pos = ro + d * rd;
        // Shadow
        vec3 sc, sn;
        float sd = rayTrace(pos + lightDir * 0.00001, lightDir, sn, sc);
        float sh = 1.0;
        if(sd < maxDist)
        {
            sh = 0.0;
        }
        // Reflection
        vec3 refdir = reflect(rd, n);
        vec3 rc, rn;
        float rd = rayTrace(pos + refdir * 0.00001, refdir, rn, rc);
        vec3 refcol = getSkyColor(refdir);
        if(rd < maxDist)
        {
            refcol = rc * (max(0.0, dot(rn, lightDir)));
        }
        return c * (max(0.0, dot(n, lightDir)) * sh + 0.5) + refcol * 0.5;
    }
    return vec3(0);
}

mat3 setCamera( in vec3 ro, in vec3 ta )
{
    vec3 cw = normalize(ta-ro);
    vec3 up = vec3(0, 1, 0);
    vec3 cu = normalize( cross(cw,up) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 vignette(vec3 color, vec2 q, float v)
{
    color *= 0.3 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), v);
    return color;
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;

    // camera        
    float theta    = radians(0.0); //radians(360.) * (mouse*resolution.xy.x/resolution.x-0.5); // + time*.2;
    float phi    = radians(-20.0); //radians(70.) * (mouse*resolution.xy.y/resolution.y-0.5) - radians(60.);
    vec3 ro = 0.45 * vec3( sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));
    vec3 ta = vec3( 0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta );
    vec3 rd =  ca*normalize(vec3(p,1.5));        
    vec3 col = render(ro ,rd);  
    col = pow(col, vec3(1. / 2.2));
    col = vignette(col, gl_FragCoord.xy / resolution.xy, 0.6);
    glFragColor = vec4(col, 1);
}
