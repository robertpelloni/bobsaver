#version 420

// original https://www.shadertoy.com/view/XtBXW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 Strand(in vec2 glfc, in vec3 color, in float hoffset, in float hscale, in float vscale, in float timescale)
{
    float g = 0.06 * resolution.y;
    float twopi = 6.28318530718;
    float i = clamp(1.0 - abs(glfc.y - (sin(mod(glfc.x * hscale / 100.0 / resolution.x * 1000.0 + time * timescale + hoffset, twopi)) * resolution.y * 0.25 * vscale + resolution.y / 2.0)), 0.0, 1.0);
    i += clamp((g + 1.0 - abs(glfc.y - (sin(mod(glfc.x * hscale / 100.0 / resolution.x * 1000.0 + time * timescale + hoffset, twopi)) * resolution.y * 0.25 * vscale + resolution.y / 2.0))) / g, 0.0, 1.0) * 0.4 ;
    return vec3(i * color.r, i * color.g, i * color.b);
}

vec3 Muzzle(in vec2 glfc, in float timescale)
{
    float theta = atan(resolution.y / 2.0 - glfc.y, resolution.x - glfc.x);
    float len = 1.0 * resolution.y * (10.0 + sin(theta * 20.0 + float(int(time * 20.0)) * -35.0)) / 11.0;
    float d = max(-0.6, 1.0 - (sqrt(pow(resolution.x - glfc.x, 2.0) + pow(resolution.y / 2.0 - ((glfc.y - resolution.y / 2.0) * 4.0 + resolution.y / 2.0), 2.0)) / len));
    //d = d * (1.0 + sin(theta * 17.0 + time * 100.77) * 0.5);
    //d = d * (3.0 + sin(theta * 10.0 + time * 100.0)) / 4.0;
    //return vec3(d, d, d);
    return vec3(d * (1.0 + sin(theta * 10.0 + float(int(time * 20.0)) * 10.77) * 0.5), d * (1.0 + -cos(theta * 8.0 - float(int(time * 20.0)) * 8.77) * 0.5), d * (1.0 + -sin(theta * 6.0 - float(int(time * 20.0)) * 134.77) * 0.5));
}

void main(void)
{
    float timescale = 4.0;
    vec3 c = vec3(0, 0, 0);
    c += Strand(gl_FragCoord.xy, vec3(1.0, 0, 0), 0.234 + 1.0 + sin(time) * 5.0, 1.0, 0.16, 10.0 * timescale);
    c += Strand(gl_FragCoord.xy, vec3(0.0, 1.0, 0.0), 0.645 + 1.0 + sin(time) * 5.0, 1.5, 0.2, 8.3 * timescale);
    c += Strand(gl_FragCoord.xy, vec3(0.0, 0.0, 1.0), 1.735 + 1.0 + sin(time) * 5.0, 1.3, 0.19, 8.0 * timescale);
    c += Strand(gl_FragCoord.xy, vec3(1.0, 1.0, 0.0), 0.9245 + 1.0 + sin(time) * 5.0, 1.6, 0.14, 12.0 * timescale);
    c += Strand(gl_FragCoord.xy, vec3(0.0, 1.0, 1.0), 0.4234 + 1.0 + sin(time) * 5.0, 1.9, 0.23, 14.0 * timescale);
    c += Strand(gl_FragCoord.xy, vec3(1.0, 0.0, 1.0), 0.14525 + 1.0 + sin(time) * 5.0, 1.2, 0.18, 9.0 * timescale);
    c += clamp(Muzzle(gl_FragCoord.xy, timescale), 0.0, 1.0);
    glFragColor = vec4(c.r, c.g, c.b, 1.0);
}
