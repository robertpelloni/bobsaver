#version 420

// original https://www.shadertoy.com/view/3t2XDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// { 2d cell id, distance to border, distnace to center )
vec4 cell(vec2 p) {
    float dxe = min(distance(p.x,floor(p.x)),distance(p.x,ceil(p.x)));
    float dye = min(distance(p.y,floor(p.y)),distance(p.y,ceil(p.y)));
    return vec4(floor(p), min(dxe,dye),length(fract(p)-.5));
}

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 o = glFragColor;

    vec2 R = resolution.xy;
    vec2 uv = C/R.xy;
    float t = time+1e2;
    uv.x *= R.x/R.y;
    uv *= 4.;
    float s = 1.;

    for (float i = 1.;i <= 8.; ++ i) {
        vec4 hex = cell(uv);
        vec4 h = hash42(hex.xy);
        uv+= hex.z*h.xy+hex.w*fract(i+t*.1);// todo: find a way to make smooth transition to next cell
        uv *= 1.02;
        o = h * sqrt(hex.z * hex.w);
    }
    o = pow(1.-o,o-o+8.);

    glFragColor = o;
}

