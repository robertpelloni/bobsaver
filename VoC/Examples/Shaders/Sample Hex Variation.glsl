#version 420

// original https://www.shadertoy.com/view/ftfGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
@lsdlive
CC-BY-NC-SA

William Kolmyjec's "Hex Variation" 1978.
Loop on 4 seconds.

Original artwork (1978): http://recodeproject.com/artwork/v3n4hex-variation

*/

#define AA 5.
#define pi 3.141592
#define time (mod(time, 4.))

// https://lospec.com/palette-list/1bit-monitor-glow
vec3 col1 = vec3(.133, .137, .137);
vec3 col2 = vec3(.941, .965, .941);

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float rand(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// inspired by Pixel Spirit Deck: https://patriciogonzalezvivo.github.io/PixelSpiritDeck/
// + https://www.shadertoy.com/view/tsSXRz
float stroke(float d, float width) {
    return 1. - smoothstep(0., AA / resolution.x, abs(d) - width * .5);
}

float circle(vec2 p, float radius) {
  return length(p) - radius;
}

// Hex Grid helper from: https://www.shadertoy.com/view/7dX3Dj
vec4 hexGrid(vec2 uv, out vec2 id)
{
    uv *= mat2(1.1547, 0., -.5773503, 1.);
    vec2 f = fract(uv);
    float triid = 1.;
    if((f.x + f.y) > 1.) {
        f = 1. - f;
         triid = -1.;
    }
    vec2 co = step(f.yx, f) * step(1. - f.x - f.y, max(f.x, f.y));
    id = floor(uv) + (triid < 0. ? 1. - co : co);
    co = (f - co) * triid * mat2(.866026, 0., .5, 1.);
    uv = abs(co);
    //id*=inverse(mat2(1.1547,0.0,-0.5773503,1.0)); // optional unskew IDs
    return vec4(.5 - max(uv.y, abs(dot(vec2(.866026, .5),uv))), length(co),co);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    float t1 = fract(time * .125);
    
    const vec2 s = vec2(1.732, 1);
    
    uv += t1 * s;
    
    float scale = 8.;
    vec2 id = vec2(0);
    vec4 p = hexGrid(uv * scale, id);
    uv = p.zw;
    id = fract(id * 1. / scale);
    
    float r = rand(id);
    if(r > 0. && r <= .33)
        uv *= r2d(pi / 3. * 0.);
    else if( r > .33 && r <= .66)
        uv *= r2d(pi / 3. * 1.);
    else
        uv *= r2d(pi / 3. * 2.);
    
    uv.x = abs(uv.x);
    float sdf = circle(uv-vec2(s.x * 1. / 3., 0), s.x * 1. / 6.);
    
    float size = .05;
    float mask = stroke(sdf, size);
    mask += stroke(uv.x, size);
    
    mask = clamp(mask, 0., 1.);
    vec3 col = mix(col1, col2, mask);
    
    // hex grid outlines
    //col.r += p.x < .01 || p.y < .01 ? 1. : 0.;
    
    glFragColor = vec4(col, 1.);
}
