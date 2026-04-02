#version 420

// original https://www.shadertoy.com/view/llcyDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(r,v,a) smoothstep(a/resolution.y,0.,abs(v-(r)))

const vec2 s = vec2(1, 1.7320508); // 1.7320508 = sqrt(3)

float calcHexDistance(vec2 p)
{
    p = abs(p);
    return max(dot(p, s * .5), p.x);
}

vec2 calcHexOffset(vec2 uv)
{
    vec4 hexCenter = round(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? offset.xy : offset.zw;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 hexInfo = calcHexOffset(uv * 3.);
    
    float a = cos(2. * (2. * length(uv) - time));
    float h = calcHexDistance(hexInfo);

    glFragColor.g = S(abs(sin(h * a * 10.)), 1., 12.) + .3 * S(h, .45, 20.) + .15
        + .3 * smoothstep(.25 + 12./resolution.y, .25, h);
}
