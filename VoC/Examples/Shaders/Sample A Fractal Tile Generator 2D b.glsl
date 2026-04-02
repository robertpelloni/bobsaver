#version 420

// original https://www.shadertoy.com/view/l3KSRy

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
#define TILE_SIZE 1.0
#define SPEED 2.0

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
const vec2 rangeCr = vec2(0.1, 1.2);
const vec2 rangeCl = vec2(0.3, 2.5);
const vec2 rangeCs = vec2(0.2, 2.2);
const vec2 rangeCa = vec2(0.1, 1.4);
const vec2 rangeCb = vec2(1.0, 2.1);
const vec2 rangeCm = vec2(0.25, 2.5);
const vec2 rangeCd = vec2(-25.0, 80.0);
const vec2 rangeCd2 = vec2(-25.0, 80.0);
const vec2 rangeCt = vec2(3.0, 11.0);
const vec2 rangeCz = vec2(0.0, 1.0);
const vec4 rangeCi = vec4(0.1, 2.0, 1.0, 4.0);
const vec4 rangeCj = vec4(0.1, 2.5, 1.0, 5.0);
void applyRange(inout float v, in vec2 r, in vec2 id){

    v = r.x + hash12(id * 133991.931 + 13023.82) * (r.y - r.x);
}
// Source: The basic idea for this certain type of fractal is from https://jbaker.graphics/writings/DEC.html, adjusted for 2D and parametrized
float de(vec2 q) {
  float cr,ca,cb,cs,cl,cm,cd,cd2,ct,cz;
    vec2 ci,cj;
    vec2 id = 234.0 + floor((q - split) / (2.0 * split));
    applyRange(cr, rangeCr, id + 117.971);
    applyRange(cl, rangeCl, id + 251.233);
    applyRange(cs, rangeCs, id + 928.323);
    applyRange(ca, rangeCa, id + 339.111);
    applyRange(cb, rangeCb, id + 1212.12);
    applyRange(cm, rangeCm, id + 2120.99);
    applyRange(cd, rangeCd, id + 1823.82);
    applyRange(cd2, rangeCd2, id + 3293.12);
    applyRange(ct, rangeCt, id + 4192.17);
    applyRange(cz, rangeCz, id + 5192.29);
    applyRange(ci.x, rangeCi.xy, id + 1233.12);
    applyRange(ci.y, rangeCi.zw, id + 9372.81);
    applyRange(cj.x, rangeCj.xy, id + 7683.33);
    applyRange(cj.y, rangeCj.zw, id + 6932.55);
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
            q = -abs(q.yx);
        }
        r2 *= 1.25;
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
    uv.x *= resolution.x / resolution.y;   
    rotate(uv, time * 4.0);uv += time * SPEED * 0.2;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.0);
}
