#version 420

// original https://www.shadertoy.com/view/DsS3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define thc(a,b) tanh(a*cos(b))/tanh(a)

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    float a = atan(uv.y, uv.x);
    vec2 p = 0.5 * cos(a - 0.49 * time) * vec2(cos(0.5 * time), sin(0.3 * time));
    vec2 q = 0.5 * (cos(2. * a - 0.51 * time)) * vec2(cos(time), sin(time));
    
    float d1 = length(uv-q) / length(uv - p) + 1.;
    float d2 = length(uv - q) / length(uv) + 1.;
    
    vec2 uv2 = vec2(d1,d2) / (d1 + d2);
    uv2 = log(uv2 + 0.495);
    a = atan(uv2.y, uv2.x) + 4. * log(length(uv2)) + time;
    uv2 *= vec2(sin(a), cos(a));
    vec3 col = vec3(uv2.x, uv2.y, abs(uv2.x-uv2.y));
    col = exp(-24. * 0.5 * col);
    col *= 0.5 +0.5 * thc(4., a -10. * log(length(uv)));
    col += exp(-3.5 * length(uv))-exp(-8. * length(uv2));
    col = 0.5 * col + 0.5 * clamp(col,0.,1.);
    //col = clamp(col,0.,1.);
    col += vec3(0.9,0.6,0.45) * thc(4., exp(-10. * length(uv-uv2))) * abs(d1/d2-d2/d1);
    col -= 0.7 / cosh(4. * length(uv)) * vec3(0.4,0.58,1);
    
    glFragColor = vec4(col,1.0);
}
