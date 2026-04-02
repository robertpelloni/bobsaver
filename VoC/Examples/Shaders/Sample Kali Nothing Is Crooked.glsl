#version 420

// original https://www.shadertoy.com/view/WtGyR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) 
{
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

float sq(vec2 p, float c) 
{
    return length(max(vec2(0.), abs(p) - c));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float tile = step(.5, fract(uv.x * 12. + floor(uv.y * 12.) * .5));
    uv += vec2(.02, .04);
    vec2 s = sign(uv-.5);
    vec2 p = fract(uv * vec2(24., 12.)) - .5;
    p*=1.5;
    p *= rot(radians(45.) * sign(fract(uv.x * 12. + floor(uv.y * 12.) *.5) -.5) * s.x * s.y);
    float black1 = step(sq(p + vec2(.1, .1), .1), .0);    
    float black2 = step(sq(p + vec2(-.1, -.1), .1), .0);    
    float white1 = step(sq(p + vec2(.1, -.1), .1), .0);
    float white2 = step(sq(p + vec2(-.1, .1), .1), .0);
    vec3 col = mix(vec3(.6, .7, 1.), vec3(.4, .5, .8), tile) + ( -black1 - black2 + white1 + white2 ) * step(fract(time * .1), .7);
    glFragColor = vec4(col, 1.0);
}
