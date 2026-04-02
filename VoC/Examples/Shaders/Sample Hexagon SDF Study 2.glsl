#version 420

// original https://www.shadertoy.com/view/WsVyWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec2 s = vec2(1, 1.7320508); // 1.7320508 = sqrt(3)

vec3 hue( float c )
{
    return smoothstep(0.,1., abs(mod(c*6.+vec3(0,4,2), 6.)-3.)-1.);
}

float random(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// xy - offset from nearest hex center
// zw - unique ID of hexagon
vec4 calcHexInfo(vec2 uv)
{
    vec4 hexCenter = round(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? vec4(offset.xy, hexCenter.xy) : vec4(offset.zw, hexCenter.zw);
}

void main(void)
{
    
    vec2 uv = (4. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    const float tileAmount = 3.;
    vec4 hexInfo = calcHexInfo(uv * tileAmount);
//    glFragColor.rgb = vec3(pow(length(abs(hexInfo.x) + abs(hexInfo.y)) * 1.3, 4.0));
    
    glFragColor.rgb = vec3(pow(length(hexInfo.xy) * 2.0, 8.0));
    //glFragColor.rg = hexInfo.zw;
}
