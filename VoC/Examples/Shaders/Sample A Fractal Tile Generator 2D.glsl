#version 420

// original https://www.shadertoy.com/view/l3GSRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
 ----------------------------------------------------------------------------------------------------------------------------------------
 * Creates tiles with many different fractals by generating one fractal through a range of parameters for each tile randomly.
 * Some are repeated. But the variety overall is amazing, I think.
 * Even changing the ranges making them bigger or smaller affects the results in a way making it impossible to define ranges
 * that show all possible results in a short amount of time.
 * Change ranges, change values, play with them as much as possible. Find other palettes and please let me know if you find nices ones.
 * I think I'll have to also get back to 3D to play with these formulas more...
 * But first more transformations and operations can be added and parametrized, as well.
 
 #defines
 TILE_SIZE:    Make it bigger to show bigger more detailed tiles
 SPEED:        Changes the speed of the movement of the tiles
 ----------------------------------------------------------------------------------------------------------------------------------------
 */
#define TILE_SIZE 2.0
#define SPEED 1.0

// Source: https://iquilezles.org/articles/palettes/
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos( 6.28318*(c*t+d) );
}
// Source: https://www.shadertoy.com/view/XdGfRR
float hash12(vec2 p)
{
    uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
    uint n = (q.x ^ q.y) * 1597334673U;
    return float(n) * 2.328306437080797e-10;
}
// My own
void drawLine(inout vec3 col, in vec3 lineColor, in float pos, in float thickness, in float hardness){
    col = mix(col, lineColor, smoothstep(thickness, thickness * hardness, abs(pos)));
}
// Basic
void rotate(inout vec2 q, in float deg){
    float rad = radians(deg);
    q = mat2x2(cos(rad),sin(rad),-sin(rad),cos(rad)) * q;
}

vec3 palette(in float t){
    return (pow(palette(t, vec3(0.5),vec3(0.5),vec3(1.0),vec3(1.25, 1.425, 1.55)), vec3(1.2)));
}

const float split = 1.5;
const vec2 rangeCr = vec2(0.1, 1.0);
const vec2 rangeCl = vec2(0.5, 2.5);
const vec2 rangeCs = vec2(0.4, 2.0);
const vec2 rangeCa = vec2(0.1, 1.0);
const vec2 rangeCb = vec2(1.2, 1.9);
const vec2 rangeCm = vec2(0.5, 2.5);
const vec2 rangeCd = vec2(-5.0, 40.0);
const vec2 rangeCd2 = vec2(-5.0, 40.0);
const vec2 rangeCt = vec2(3.0, 13.0);
const vec2 rangeCz = vec2(0.0, 1.0);
const vec4 rangeCi = vec4(0.01, 1.0, 2.0, 3.0);
const vec4 rangeCj = vec4(0.1, 1.5, 2.0, 4.0);
void applyRange(inout float v, in vec2 r, in vec2 id){
    v = r.x + hash12(id * 13371.931 + 130223.82) * (r.y - r.x);
}
// Source: The basic idea for this certain type of fractal is from https://jbaker.graphics/writings/DEC.html, adjusted for 2D and parametrized
float de(vec2 q) {
  float cr,ca,cb,cs,cl,cm,cd,cd2,ct,cz;
    vec2 ci,cj;
    vec2 id = 234.0 + floor((q - split) / (2.0 * split));
    applyRange(cr, rangeCr, id);
    applyRange(cl, rangeCl, id);
    applyRange(cs, rangeCs, id);
    applyRange(ca, rangeCa, id);
    applyRange(cb, rangeCb, id);
    applyRange(cm, rangeCm, id);
    applyRange(cd, rangeCd, id);
    applyRange(cd2, rangeCd2, id);
    applyRange(ct, rangeCt, id);
    applyRange(cz, rangeCz, id);
    applyRange(ci.x, rangeCi.xy, id);
    applyRange(ci.y, rangeCi.zw, id);
    applyRange(cj.x, rangeCj.xy, id);
    applyRange(cj.y, rangeCj.zw, id);
    q = mod(q - split, 2.0 * split) - split;
    q = abs(q) - cl;
    if(q.x < q.y){
        q.xy = q.yx;
    }
    float s = cs;
    q -= ci;
    for(float i = 0.0; i < ct; i+= 1.0) {
        float r2 = 2.0 / clamp(dot(q, q), ca, cb);
        q = abs(q) * r2;
        rotate(q, cd);
        q -= cj;
        rotate(q.xy, cd2);
        if(cz > 0.5){
            q = abs(q.yx);
        }
        s *= r2;
    }
    return cm * length(q) / (s - cr);
}
vec3 render(in vec2 pa){
    float d = de(pa * 6.0 / TILE_SIZE);
    vec3 col = palette(d * 8.0);
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.02, abs(d)));
    float mm = 0.25 * TILE_SIZE;
    drawLine(col, vec3(0.1), min(mod(pa.y + mm, mm * 2.0), mod(pa.x + mm, mm * 2.0)), 0.03, 0.01);
    return col;
}
void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv -= time * SPEED * 0.1;
    uv.x *= resolution.x / resolution.y;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.0);
}
