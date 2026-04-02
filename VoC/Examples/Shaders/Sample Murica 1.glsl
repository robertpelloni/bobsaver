#version 420

// original https://www.shadertoy.com/view/XdySDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Juha Turunen (turunen@iki.fi)
// http://www.usflag.org/flag.specs.html

#define M_PI 3.14159
const vec4 oldGloryRed = vec4(191.0 / 255.0, 10.0 / 255.0, 48.0 / 255.0, 1.0);  // PMS 193C
const vec4 oldGloryBlue = vec4(0.0, 40.0 / 255.0, 104.0 / 255.0, 1.0);  // PMS 281C
const vec4 cosmeticDentistryWhite = vec4(1.0);

float smoothbump(float low, float high, float x, float eps)
{
    return smoothstep(low - eps, low + eps, x) - smoothstep(high - eps, high + eps, x);
}

vec4 stripes(in float y, float eps) {
    eps *= 20.0;
    float m = mod(y * 13.0, 2.0);
    float a = smoothstep(1.0 - eps, 1.0 + eps, m) - smoothstep(2.0 - eps, 2.0 + eps, m);
    return mix(oldGloryRed, cosmeticDentistryWhite, a);
}

float inTriangle(in vec2 p, in vec2 t0, in vec2 t1, in vec2 t2, in float eps) 
{
    vec2 v0 = t2 - t0;
    vec2 v1 = t1 - t0;
    vec2 v2 = p - t0;

    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d02 = dot(v0, v2);
    float d11 = dot(v1, v1);
    float d12 = dot(v1, v2);

    float d = d00 * d11 - d01 * d01;
    float u = (d11 * d02 - d01 * d12) / d;
    float v = (d00 * d12 - d01 * d02) / d;

    eps = 0.2;
    float uvStep = smoothstep(1.0 + eps, 1.0 - eps,  u + v);
    float uStep = u > 0.0 ? 1.0 : 0.0;
    float vStep = v > 0.0 ? 1.0 : 0.0;
    return min(uvStep, min(uStep, vStep));
}

float star(in vec2 p, in float radius, in float eps) {
    p.y = -p.y;
    mat2 transform = mat2(1.0);
    float thetaOffset = 0.5 * M_PI;
    float theta = M_PI * 2.0 / 5.0;
    mat2 rotate = mat2(cos(theta), sin(theta), -sin(theta), cos(theta));
    float tri = 0.0;
    vec2 p1 = vec2(cos(-theta + thetaOffset), sin(-theta + thetaOffset)) * radius;
    vec2 p2 = vec2(cos( theta + thetaOffset), sin( theta + thetaOffset)) * radius;
    for (int i = 0; i < 5; i++) {
        tri = max(tri, inTriangle(p, vec2(0.0), transform * p1, transform * p2, eps));
        transform = rotate * transform;
    }
    return tri;
}

vec4 starPattern(in vec2 p, in float eps)
{
    const float starHSpacing = 0.063;
    const float starVSpacing = 0.054;
    const float starRadius = 0.052 * 0.5;
    
    p -= vec2(starHSpacing, starVSpacing);
    vec2 pa = p;
    p.x = mod(p.x + 0.5 * starHSpacing, starHSpacing * 2.0) - 0.5 * starHSpacing;
    p.y = mod(p.y + 0.5 * starVSpacing, starVSpacing) - 0.5 * starVSpacing;
    float line = mod(pa.y + 0.5 * starVSpacing, 2.0 * starVSpacing) - 0.5 * starVSpacing;
    p.x -= line < starVSpacing * 0.5 ? 0.0 : starHSpacing;
    float c = star(p, starRadius, eps);
    
    if (pa.x < -starHSpacing * 0.5  || 
        pa.x > 10.5 * starHSpacing  ||
        pa.y < -starVSpacing * 0.5  ||
        pa.y > 8.5 * starVSpacing )
        c = 0.0;

    return vec4(cosmeticDentistryWhite.rgb, c);
}    

vec4 theUnion(in vec2 p, in float eps) {
    vec4 s = starPattern(p, eps);
    vec4 c = mix(oldGloryBlue, s, s.a);
    
    const float unionWidth = 0.76;
    float unionHeight = 0.5385;
    c.a = smoothstep(unionWidth + eps, unionWidth - eps, p.x);
    c.a *= smoothstep(unionHeight + eps, unionHeight - eps, p.y);
    return c;
}

void main(void)
{
    vec2 p = gl_FragCoord.xy;
    p.y = resolution.y - p.y;
    p /= resolution.xx;
    p *= 2.5;
    
    const vec2 amplitude = vec2(0.06, 0.05);
    p -= vec2(0.275 + cos(time + p.y * 3.0) * amplitude.x, 
              0.22 + sin(time + p.x * 5.0) * amplitude.y);

    float eps = dFdx(p).x * 0.5;
    
    vec4 stripesColor = stripes(p.y, eps); 
    vec4 unionColor = theUnion(p, eps);
    vec4 flagColor = vec4(mix(stripesColor.rgb, unionColor.rgb, unionColor.a), 1.0);

    flagColor.a = smoothbump(0.0, 1.9, p.x, eps);
    flagColor.a *= smoothbump(0.0 + eps, 1.0 - eps, p.y, eps);
    
    vec3 bgColor = vec3(0.25);
    vec3 outputColor = mix(bgColor, flagColor.rgb, flagColor.a);

    float vignette = pow(length((gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.xy), 3.0) * 3.0; 
    outputColor = mix(outputColor, vec3(0.0), vignette);
    glFragColor = vec4(outputColor, 1.0);
}
