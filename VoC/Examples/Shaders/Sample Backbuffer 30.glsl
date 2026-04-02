#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;
// Mitchell Netravali Reconstruction Filter {
// cubic B-spline: 
#define MNB 1.0
#define MNC 0.0

// recommended
//#define MNB 0.333333333333
//#define MNC 0.333333333333

// Catmull-Rom spline
//#define MNB 0.0
//#define MNC 0.5
// }

float MNweights(float x)
{
    float ax = abs(x);
    return (ax < 1.0) ?
        ((12.0 - 9.0 * MNB - 6.0 * MNC) * ax * ax * ax +
         (-18.0 + 12.0 * MNB + 6.0 * MNC) * ax * ax + (6.0 - 2.0 * MNB)) / 6.0
    : ((ax >= 1.0) && (ax < 2.0)) ?
        ((-MNB - 6.0 * MNC) * ax * ax * ax + (6.0 * MNB + 30.0 * MNC) * ax * ax + 
         (-12.0 * MNB - 48.0 * MNC) * ax + (8.0 * MNB + 24.0 * MNC)) / 6.0
    : 0.0;
}

vec4 texture2D_bicubic(sampler2D tex, vec2 uv)
{
    vec2 px = (1.0 / resolution);
    vec2 f = fract(uv / px);
    vec2 texel = (uv / px - f + 0.5) * px;
    vec4 weights = vec4(MNweights(1.0 + f.x),
                MNweights(f.x),
                MNweights(1.0 - f.x),
                MNweights(2.0 - f.x));
    vec4 t1 = 
        texture2D(tex, texel + vec2(-px.x, -px.y)) * weights.x +
        texture2D(tex, texel + vec2(0.0, -px.y)) * weights.y +
        texture2D(tex, texel + vec2(px.x, -px.y)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, -px.y)) * weights.w;
    vec4 t2 = 
        texture2D(tex, texel + vec2(-px.x, 0.0)) * weights.x +
        texture2D(tex, texel) /* + vec2(0.0) */ * weights.y +
        texture2D(tex, texel + vec2(px.x, 0.0)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, 0.0)) * weights.w;
    vec4 t3 = 
        texture2D(tex, texel + vec2(-px.x, px.y)) * weights.x +
        texture2D(tex, texel + vec2(0.0, px.y)) * weights.y +
        texture2D(tex, texel + vec2(px.x, px.y)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, px.y)) * weights.w;
    vec4 t4 = 
        texture2D(tex, texel + vec2(-px.x, 2.0 * px.y)) * weights.x +
        texture2D(tex, texel + vec2(0.0, 2.0 * px.y)) * weights.y +
        texture2D(tex, texel + vec2(px.x, 2.0 * px.y)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, 2.0 * px.y)) * weights.w;
    
    return MNweights(1.0 + f.y) * t1 +
        MNweights(f.y) * t2 +
        MNweights(1.0 - f.y) * t3 +
        MNweights(2.0 - f.y) * t4;
}
void main( void ) {
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel = 2./resolution;
    vec4 me = texture2D(backbuffer, position);

    vec2 rnd = vec2(mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0),
                    mod(fract(sin(dot(position + time * 0.001, vec2(24.9898,44.233))) * 27458.5453), 1.0));
    vec2 nudge = vec2(12.0 + 10.0 * cos(time * 0.03775),
                      12.0 + 10.0 * cos(time * 0.02246));
    vec2 rate = -0.005 + 0.02 * (0.5 + 0.5 * cos(nudge * (position.yx - 0.5) + 0.5 + time * vec2(0.137, 0.262)));

    float mradius = 0.007;//0.07 * (-0.03 + length(zoomcenter - mouse));
    if (length(position-mouse) < mradius) {
        me.r = 0.5+0.5*sin(time * 1.234542);
        me.g = 0.5+0.5*sin(3.0 + time * 1.64242);
        me.b = 0.5+0.5*sin(4.0 + time * 1.444242);
    } else {
        rate *= 6.0 * abs(vec2(0.5, 0.5) - mouse);
        rate += 0.5 * rate.yx;
        vec2 mult = 1.0 - rate;
        vec2 jitter = vec2(1.1 / resolution.x,
                           1.1 / resolution.y);
        vec2 offset = (rate * mouse) - (jitter * 0.5);
        vec4 source = texture2D_bicubic(backbuffer, position * mult + offset + jitter * rnd);
        
        me = me * 0.05 + source * 0.95;
    }
    glFragColor = me;
}
