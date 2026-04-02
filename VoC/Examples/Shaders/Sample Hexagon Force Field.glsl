#version 420

// original https://www.shadertoy.com/view/Wst3Rl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float HexDist(vec2 p) {
    p = abs(p);
    
    float c = dot(p, normalize(vec2(1,1.73)));
    c = max(c, p.x);
    
    return c;
}

vec4 HexCoords(vec2 uv) {
    vec2 r = vec2(1, 1.73);
    vec2 h = r*.5;
    
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;
    
    vec2 gv = dot(a, a) < dot(b,b) ? a : b;
    
    float x = atan(gv.x, gv.y);
    float y = .5-HexDist(gv);
    vec2 id = uv-gv;
    return vec4(x, y, id.x,id.y);
}

void main(void)
{
    float t = time;
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 uv1 = uv + vec2(0, sin(uv.x*5. +t)*.02);
    
    vec2 uv2 = .5*uv1 + .5*uv + vec2(sin(uv.y*5. + t)*.02, 0);
    float a = 1. + t*.05;
    float c = cos(a);
    float s = sin(a);
    uv2 *= mat2(c, -s, s, c);
    
    // Time varying pixel color
    vec3 col = vec3(0);
    col += smoothstep(.05, .0, HexCoords(uv1*5.).y) * vec3(.2, .2, 1.);
    col += smoothstep(.1, .0, HexCoords(uv2*20.).y) * vec3(.1, .1, .3);
    
    col *= dot(sin(uv*vec2(cos(uv.x*1.3), 7.)+t*2.), vec2(.7, .55974))*1.2+3.;
    

    // Output to screen
    glFragColor = vec4(col,1.);
}
