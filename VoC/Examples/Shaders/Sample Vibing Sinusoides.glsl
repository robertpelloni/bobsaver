#version 420

// original https://www.shadertoy.com/view/tldyDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define CT() abs(sin(time))

vec3 GlowingLine(in vec2 gl_FragCoord2, vec3 color, float hoffset, float voffset, float hscale, float vscale, float timescale)
{
    float glowRadius = 0.04 * resolution.y * (gl_FragCoord2.xy.x / resolution.x + 1.0) ;
    float glowIntensity = 1.0 * gl_FragCoord2.xy.x / resolution.x;
    float twopi = 2.0 * PI;
    float thickness = 1.5;
    float curve = thickness - abs(gl_FragCoord2.xy.y - (sin(mod(gl_FragCoord2.xy.x * hscale / 100.0 / resolution.x * 1000.0 + time * timescale + hoffset, twopi)) * resolution.y * 0.25 * vscale + voffset));
    float i = clamp(curve, 0.0, 1.0);

    i += clamp((glowRadius + curve) / glowRadius, 0.0, 1.0) * glowIntensity;
    return i * color;
}

vec3 rainbowGradient(float t) {
    vec3 c = 1.0 - pow(abs(vec3(t) - vec3(0.65, 0.5, 0.2)) * vec3(3.0, 3.0, 5.0), vec3(1.5, 1.3, 1.7));
    c.r = max(0.15 - (abs(t - 0.04) * 5.0) * (abs(t - 0.04) * 5.0), c.r);
    c.g = (t < 0.5) ? smoothstep(0.04, 0.45, t) : c.g;
    return clamp(c, 0.0, 1.0);
}

void main(void)
{
    vec2 st = vec2(gl_FragCoord.xy / resolution.xy);

    vec3 color = vec3(0.0039, 0.0039, 0.1922);

    color += GlowingLine(gl_FragCoord.xy, rainbowGradient(0.15  * CT()), 0.0 + 2.4, resolution.y / 2.0, abs(st.x - 1.0), abs(sin(time)) * st.x, 5.0);
    color += GlowingLine(gl_FragCoord.xy, rainbowGradient(0.1  * CT()), PI + 2.4, resolution.y / 2.0, abs(st.x - 1.0), abs(sin(time + PI)) * st.x, 5.0);
    color += GlowingLine(gl_FragCoord.xy, rainbowGradient(0.3  * CT()), PI + 2.4, resolution.y / 2.0, abs(st.x - 1.0), sin(time + PI * 0.5) * st.x, 5.0);
    color += GlowingLine(gl_FragCoord.xy, rainbowGradient(0.25 * CT()), PI + 2.4, resolution.y / 2.0, abs(st.x - 1.0), sin(time - PI * 0.5) * st.x, 5.0);
    
    glFragColor = vec4(color, 1.0);
}
