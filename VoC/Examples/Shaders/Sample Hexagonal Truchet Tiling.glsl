#version 420

// original https://www.shadertoy.com/view/7sycWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hash functions from https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

float HexDist(vec2 p)
{

    p = abs(p);
    
    float c = dot(p, normalize(vec2(1., 1.73)));
    c = max(c, p.x);
    
    return c;
}

mat2 Rot(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec4 HexCoord(vec2 uv)
{
    vec2 r = vec2(1., 1.73);
    vec2 h = r*.5;
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;

    vec2 gv;
    if(length(a)<length(b))
        gv = a;
    else
        gv = b;
    
    float x = 0.;
    float y = 0.5 - HexDist(gv);
    vec2 id = uv-gv;
    return vec4(gv.x, gv.y, id.x, id.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0.);
    
    uv *= 20.;
    uv += 200.+time;
    
    vec4 hex = HexCoord(uv);
    float randID = hash12(hex.zw);
    float randTile = floor(randID*3.);
    
    hex.xy *= Rot(randTile*1.0466);
    
    float centerLine = smoothstep(0.12, 0.015, abs(-0.0001+hex.y*.9));
    
    float circle = smoothstep(0.41, 0.3, length(abs(hex.xy)-vec2(0., 0.56)));
    
    circle = circle - smoothstep(0.26, 0.15, length(abs(hex.xy)-vec2(0., 0.56)));
    
    col = vec3(max(circle, centerLine));
    col *= hash31(randTile+654.4);
    
    glFragColor = vec4(col,1.0);
}
