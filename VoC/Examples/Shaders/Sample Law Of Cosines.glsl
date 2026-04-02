#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlcSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 18.02.2020
// Bielsko-Biała, Poland, UE, Earth, Sol, Milky Way, Local Group, Laniakea :)

// Plate of Pythagorean theorem generalisation.

// The triangle in the middle is "generator".
// Orange squares illustrates the law of cosines.
// Grey ones illustrates the law I do not know.

//--- program parameters ---//

#define ANIMATION_SPEED            0.7

//--- points depot ---//

vec2 t0[3];

vec2 s1[4];
vec2 s2[4];
vec2 s3[4];

//--- auxiliary functions ---//

float dSegment(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

    return length(pa - ba * h);
}

vec2 cross2(vec2 a, vec2 b)
{
  return vec2(b.y - a.y, a.x - b.x);
}

vec2 rotate(vec2 p, float angle)
{
    float ca = cos(angle);
    float sa = sin(angle);
    
    return p*mat2(ca, sa, -sa, ca);
}

bool isInsideTriangle(vec2 p, vec2 A, vec2 B, vec2 C)
{
    vec3 s = vec3
    (
        (p.x - A.x)*(C.y - A.y) - (C.x - A.x)*(p.y - A.y),
        (p.x - B.x)*(A.y - B.y) - (A.x - B.x)*(p.y - B.y),
        (p.x - C.x)*(B.y - C.y) - (B.x - C.x)*(p.y - C.y)
    );
    
    return all(greaterThan(s, vec3(0.0))) || all(lessThan(s, vec3(0.0)));
}

bool isInsideRectangle(vec2 p, vec2 A, vec2 B, vec2 C, vec2 D)
{
    return isInsideTriangle(p, A, B, C)
        || isInsideTriangle(p, A, C, D);
}

void generateSquares(vec2 v1, vec2 v2, vec2 v3, vec2 v4, vec2 v5, vec2 v6)
{
    s1[0] = v2;
    s1[1] = v1;
    s1[2] = v1 + cross2(v2, v1);
    s1[3] = s1[2] + (v2 - v1);

    s2[0] = v4;
    s2[1] = v3;
    s2[2] = v3 + cross2(v4, v3);
    s2[3] = s2[2] + (v4 - v3);

    s3[0] = v6;
    s3[1] = v5;
    s3[2] = v5 + cross2(v6, v5);
    s3[3] = s3[2] + (v6 - v5);
}

//--- final color procedure ---//

void main(void)
{
    
    //--- precalculations ---//
    
    float time        = ANIMATION_SPEED * time;
    float scale        = 22.0;
    float lwidth    = 0.05;
    float awidth    = 2.5*scale / resolution.y;
    float d            = 1e9;
  
    vec2 p = scale * (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 m = scale * (2.0*mouse*resolution.xy.xy    - resolution.xy) / resolution.y;

    vec3 color = vec3(1.0);

    
    //--- build and draw the source triangle ---//
    
    t0[0] = rotate(vec2(-3.0, 0.0), time);
    t0[1] = rotate(vec2(+3.0, 0.0), time);
    t0[2] = rotate(vec2(+3.0*cos(time), -abs(10.0*sin(time))), time);
    
    if (isInsideTriangle(p, t0[0], t0[1], t0[2])) color = vec3(1.0, 0.11, 0.05);
    color = mix(vec3(0.0), color, smoothstep(lwidth - awidth, lwidth + awidth, d));
    
    
    //--- set first 3 squares around source triangle ---//
                         
    s1[3] = t0[0]; s2[2] = t0[1]; s2[3] = t0[1]; s3[2] = t0[2]; s3[3] = t0[2]; s1[2] = t0[0];

    
    //--- build and draw consecutive squares ---//
    
    for (int i = 0; i < 4; i++)
    {
        generateSquares(s1[3], s2[2], s2[3], s3[2], s3[3], s1[2]);

        int  j = 5 - i;
        vec3 c = 0 == i % 2? vec3(1.0, 0.7, 0.4) : vec3(0.9);

        if (isInsideRectangle(p, s1[0], s1[1], s1[2], s1[3])) color = c;
        if (isInsideRectangle(p, s2[0], s2[1], s2[2], s2[3])) color = c;
        if (isInsideRectangle(p, s3[0], s3[1], s3[2], s3[3])) color = c;
        d = min(d, dSegment(p, s1[0], s1[1])); d = min(d, dSegment(p, s1[1], s1[2]));
        d = min(d, dSegment(p, s1[2], s1[3])); d = min(d, dSegment(p, s1[3], s1[0]));
        d = min(d, dSegment(p, s2[0], s2[1])); d = min(d, dSegment(p, s2[1], s2[2]));
        d = min(d, dSegment(p, s2[2], s2[3])); d = min(d, dSegment(p, s2[3], s2[0]));
        d = min(d, dSegment(p, s3[0], s3[1])); d = min(d, dSegment(p, s3[1], s3[2]));
        d = min(d, dSegment(p, s3[2], s3[3])); d = min(d, dSegment(p, s3[3], s3[0]));
        color = mix(vec3(0.0), color, smoothstep(lwidth - awidth, lwidth + awidth, d));
    }

    glFragColor = vec4(color, 1.0);
    
}
