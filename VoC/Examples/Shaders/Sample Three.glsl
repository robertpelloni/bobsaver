#version 420

// original https://neort.io/art/c34m91s3p9f8s59bdtm0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float n = 3.0;
const float PI = acos(-1.0);

// function===============================================================================
vec2 rot(vec2 pos, float r)
{
    mat2 m = mat2(cos(r), sin(r), -sin(r), cos(r));
    return m * pos + 0.5;
}

// primitive==============================================================================
float box(vec2 pos, vec2 size)
{
    vec2 leftbottom = vec2(0.5) - size;
    vec2 uv = step(leftbottom, pos);
    uv *= step(leftbottom, 1.0 - pos);
    return uv.x* uv.y;
}

float makeThree(vec2 pos, float r)
{
    float d = 1e10;
    float d1 = 0.0;
    float d2 = 0.0;
    float d3 = 0.0;
    
    vec2 rotate = rot(pos, r);
    pos.xy = rotate;
    d1 = box(vec2(pos.x + 0.3, pos.y), vec2(0.1, 0.55)) * (1.0 - box(vec2(pos.x + 0.3, pos.y), vec2(0.07, 0.47)));
    d2 = box(vec2(pos.x, pos.y), vec2(0.1, 0.5)) * (1.0 - box(vec2(pos.x, pos.y), vec2(0.07, 0.47)));
    d3 = box(vec2(pos.x - 0.3, pos.y), vec2(0.1, 0.55)) * (1.0 - box(vec2(pos.x - 0.3, pos.y), vec2(0.07, 0.47)));
    
    d = d1 + d2 + d3;
    return d;
}

float wave(vec2 pos)
{
    float d = 0.0;
    pos = vec2(pos.x + (resolution.x) / 2.0, pos.y - (resolution.y) / 2.0) + 0.5;
    d = length((floor(pos * n) + 0.5) / n);
    return 1.0 - (sin(d / 0.8 + time*1.5));
}

// map====================================================================================
float map(vec2 pos, float r)
{
    return makeThree(pos, r);
}

float map2(vec2 pos)
{
    return wave(pos);
}

//main====================================================================================
void main(void) 
{
    vec2 pos = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float mask = float(map2(pos));
    
    pos += 0.5;
    
    vec2 mulPos = pos * n;
    pos = fract(pos * n);
    
    float switchNum = mod(floor(mulPos.x) + floor(mulPos.y), 2.0) + 1.0;
    
    float three = float(map(pos - 0.5, PI / switchNum));
    vec3 mainCol = vec3(1.0, 1.0, 0.22);
    
    
    vec3 endCol = vec3(mask * three * mainCol);

    glFragColor = vec4(endCol, 1.0);
}
