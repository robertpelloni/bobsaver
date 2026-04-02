#version 420

// original https://www.shadertoy.com/view/stcBR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159
#define thc(a,b) tanh(a*cos(b))/tanh(a)

float getS(vec2 uv) {
    float r = 0.8 * log(length(uv));
    float a = atan(uv.x, uv.y);
    
    float k = 4.;//100. * exp(-time);
    float s = 0.5 + 0.5 * thc(30., 
    3. * a + cos(3. * a - 3. * r + time) * 0.5 * pi * cos(1. * a 
    + (k-1.) * r - time) + k * 3. * r -  time);
    return s;
}

float h21(vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 pal(in float t, in vec3 d) {
    return 0.5 + 0.5 * cos(2. * pi * (0.5 * t + d));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
  
    float a = atan(uv.x, uv.y);
    float r = length(uv);
    float s = getS(uv);
    float v = 8. * a + time;
    float s2 = getS(uv * 40. + 0.02 * vec2(cos(v), sin(v)));
    float s3 = 0.5 * s + s2 * exp(-2. * r);
    
    vec3 col = vec3(0.5 * s + s2 * exp(-2. * r));
    col = pal(s3 * 1.5, vec3(1,0.25,0)/3.);
    col += 1.2/ cosh((7.5 + 2.5 * thc(4., s3 * pi * 0.5 + 8. * r - 1.5 * time)) * r);
    col *= exp(-0.5 * r);
    glFragColor = vec4(col,1.0);
}
