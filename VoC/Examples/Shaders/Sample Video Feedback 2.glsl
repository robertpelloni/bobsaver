#version 420

//this is neat! and now, it's smooth

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec4 texture2D_bicubic(sampler2D tex, vec2 uv);

void main( void ) {
float tim=time*0.01;
mat2 rmx=mat2(cos(tim),sin(tim),-sin(tim),cos(tim))*(1.0+sin(time*0.3)*0.01);

    vec2 px  = gl_FragCoord.xy;
    vec2 uv = px/resolution;
    uv=(uv-0.5)*rmx+0.5;
    vec4 ocol = texture2D_bicubic(backbuffer, uv);
    vec2 cursor = mouse*resolution;
    vec3 col=ocol.gbr*0.995;
    col.b+=clamp(1.0-length(px-cursor)*0.1,0.0,1.0);
    glFragColor = vec4( col, 1.0 );

}

#define MNB 1.0
#define MNC 0.0

float MNweights(float x)
{
    float ax = abs(x);
    return (ax < 1.0) ?
        (((12.0 - 9.0 * MNB - 6.0 * MNC) * ax + (-18.0 + 12.0 * MNB +
        6.0 * MNC)) * ax * ax + (6.0 - 2.0 * MNB)) / 6.0
    : ((ax >= 1.0) && (ax < 2.0)) ?
        ((((-MNB - 6.0 * MNC) * ax + (6.0 * MNB + 30.0 * MNC)) * ax + 
        (-12.0 * MNB - 48.0 * MNC)) * ax + (8.0 * MNB + 24.0 * MNC)) / 6.0
    : 0.0;
}

vec4 texture2D_bicubic(sampler2D tex, vec2 uv)
{
    vec2 fix = uv-vec2(0.5)/resolution; //remove diagonal offset
    vec2 px = (1.0 / resolution);
    vec2 f = fract(fix / px);
    vec2 texel = (fix / px - f + 0.5) * px;
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
