#version 420

// original https://www.shadertoy.com/view/7ljSWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2x2 GetRotM(float angle) 
{
    return mat2x2(cos(angle), -sin(angle), +sin(angle), cos(angle));
}
float HexDist(vec2 p) 
{
    p = abs(p);
    float d = dot(normalize(vec2(1.0, 1.73205080757)), p); // sqrt(3)
    return max(d,p.x);;
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.0);
    uv = uv*(sin(time) + 4.) + vec2(time*2.);
    vec2 r = vec2(1.,1.73205080757); // sqrt(3)
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;
    vec2 gv;
    if (length(a) < length(b))
        gv = a;
    else
        gv = b;
    float squareD = 1.;
    for (int i = 0; i < 3; i++) 
    {
        vec2 p = GetRotM(float(i) * 1.0471975512) * gv; // pi/3
        squareD = min(max(abs(abs(p.x) - 0.5), 1. - abs(abs(p.y) - 1.0)), squareD);
    }
    float squareFlag = step(squareD, 0.1830127019); // 0.5 - 0.5 * sqrt(3) / (sqrt(3) + 1)
    float hexFlag = step(HexDist(gv), 0.3169872981); // 0.5 * sqrt(3) / (sqrt(3) + 1)
    float triFlag = (1. - squareFlag) * (1. - hexFlag);
    col.b = hexFlag;
    col.r = squareFlag;
    col.g = triFlag;
    glFragColor = vec4(col,1.0);
}
