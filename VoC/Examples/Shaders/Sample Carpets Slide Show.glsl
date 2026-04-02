#version 420

// original https://www.shadertoy.com/view/ftcXRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ---------- Jet colormap -----------------------------
// https://www.shadertoy.com/view/3tlGD4
// float u0 = 0.0;
const vec3 color0 = vec3(0.0, 0.0, 0.5625); // blue
const float u1 = 1.0/9.0;
const vec3 color1 = vec3(0.0, 0.0, 1.0); // blue
const float u2 = 23.0/63.0;
const vec3 color2 = vec3(0.0, 1.0, 1.0); // cyan
const float u3 = 13.0/21.0;
const vec3 color3 = vec3(1.0, 1.0, 0.0); // yellow
const float u4 = 47.0/63.0;
const vec3 color4 = vec3(1.0, 0.5, 0.0); // orange
const float u5 = 55.0/63.0;
const vec3 color5 = vec3(1.0, 0.0, 0.0); // red
// float u6 = 1.0;
const vec3 color6 = vec3(0.5, 0.0, 0.0); // red

// rescaling function
#define rescale(u, v, x) (x - u)/(v - u)

vec3 jetLinear(float t)
{
    return
        + mix(color0, color1, rescale(0.0, u1, t))
        + (mix(color1, color2, rescale(u1, u2, t)) - mix(color0, color1, rescale(0.0, u1, t))) * step(u1, t)
        + (mix(color2, color3, rescale(u2, u3, t)) - mix(color1, color2, rescale(u1, u2, t))) * step(u2, t)
        + (mix(color3, color4, rescale(u3, u4, t)) - mix(color2, color3, rescale(u2, u3, t))) * step(u3, t)
        + (mix(color4, color5, rescale(u4, u5, t)) - mix(color3, color4, rescale(u3, u4, t))) * step(u4, t)
        + (mix(color5, color6, rescale(u5, 1.0, t)) - mix(color4, color5, rescale(u4, u5, t))) * step(u5, t)
        ;
}
// end of colormap -------------------------------------------------

void main(void)
{
    float t = time / 20.0;
    vec2 pos = vec2(cos(t), sin(t)) * 5.0;
    
    // make height of picture equal to 100 "pixels"
    vec2 uv = trunc((gl_FragCoord.xy/resolution.y + pos) * 100.0);

    float n = trunc(time + 15.0);
    if (mod(n, 5.0) == 0.0) {
        n += 1.0;
    }
    // (x^2 + y^2) mod n mod 5
    // https://commons.wikimedia.org/wiki/File:Remainder-pattern1.png
    float val = mod(mod(dot(uv, uv), n), 5.0) / 5.0;
    
    vec3 col = jetLinear(val);

    glFragColor = vec4(col,1.0);
}

