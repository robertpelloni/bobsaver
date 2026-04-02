#version 420

// original https://www.shadertoy.com/view/wty3WD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define saturate(v) (clamp(v, 0.0, 1.0))
#define PI 3.14159265357989

mat2 rotate(float angle)
{
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    float dist = length(uv);
    dist = length(uv);
    uv = vec2(atan(uv.y, uv.x), dist);
    uv = rotate(-PI * 0.51015) * uv;
    uv.x = pow(2.5 - dist, 3.0);
    uv = rotate(PI * 0.551) * uv;
    
    // zigzag
    uv.y += (0.0 == mod(floor(uv.x * 10.0), 2.0) ?
             (1.0 - fract(uv.x * 5.0)) :
             (fract(uv.x * 5.0))) * 0.5;
    
    // animation
    float time = time * 0.05;
    float animStep = smoothstep(0.48, 0.5, fract(time)) * (1.0 - smoothstep(0.98, 1.0, fract(time)));
    uv.x += animStep * 0.1;
    uv.y += cos(time * PI * 2.0) * 5.0;
    
    vec2 uvScale = vec2(5.0, 3.0);
    vec2 uvLocal = fract(uv * uvScale) - 0.5;
    vec2 uvID = floor(uv * uvScale);
    
    // color
    float type = mod(uvID.x + uvID.y, 2.0);
    float colorBlend = saturate(uvLocal.x + 0.5) * 0.5;
    float colorSmoothY = smoothstep(0.5, 0.48, abs(uvLocal.y));
    float line = smoothstep(0.0, 0.03, abs(uvLocal.x));
    type = (type == 0.0) ? line : 1.0 - line;
    
    vec3 colorType0From = vec3(0.9, 0.4, 0.6);
    vec3 colorType0To = vec3(1);
    vec3 colorType1From = vec3(1);
    vec3 colorType1To = vec3(0.95, 0.8, 1.0);
    vec3 colorType0 = mix(colorType0From, colorType0To, colorBlend);
    vec3 colorType1 = mix(colorType1From, colorType1To, colorBlend);
    
    float shadow = smoothstep(-0.5, 0.0, (uvLocal.y)) * smoothstep(-0.5, -0.4, (uvLocal.x));
    float whiteHole = saturate(1.3 - dist);
    
    glFragColor.rgb = mix(colorType0, colorType1, type);
    glFragColor.rgb = mix(glFragColor.rgb, colorType0, 1.0 - colorSmoothY);
    glFragColor.rgb = mix(glFragColor.rgb * shadow, vec3(1), whiteHole * whiteHole);
}
