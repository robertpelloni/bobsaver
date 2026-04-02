#version 420

// original https://www.shadertoy.com/view/XtGGzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 points [100];
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    for (int y = 0;y < 100; y++) {
        points[y] = ((vec2(sin(float(y)+(float(y)/100.)*time), cos(float(y)+(float(y)/100.)*time))*(float(y)/100.))+1.)/2.;
    }
    vec2 closest = points[0];
    float j = 0.;
    for (int i = 1; i < 100; i++) {
        if (distance(points[i],uv)<distance(closest,uv)) {
            closest = points[i];
            j = float(i);
        }
    }
    glFragColor = vec4(hsv2rgb(vec3(j/100., 1, 1)),1);
}
