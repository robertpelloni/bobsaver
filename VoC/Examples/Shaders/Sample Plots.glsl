#version 420

// original https://www.shadertoy.com/view/WdGyWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 sRGB_OETF(vec3 c) {
    vec3 a = 1.055*pow(c, vec3(1.0/2.4)) - 0.055;
    vec3 b = 12.92*c;
    return mix(a, b, lessThanEqual(c, vec3(0.0031308)));
}

vec3 f(float x) {
    const float PI = radians(180.0);
    vec3 t = vec3(-1.0, 0.0, 1.0)/6.0 + 6.0*cos(PI*x) + time;
    return 0.5 + x*(1.0 - x)*sin(PI*t);
}

vec3 f(vec2 xy) {
    return f(xy.x) - xy.y;
}

vec3 sdf(vec2 xy, float px) {
    return f(xy)/px;
}

vec3 sdf(vec2 xy, vec2 px) {
    const vec2 e = vec2(1.0, 0.0);
    vec3 x = f(xy + e.xy*px) - f(xy - e.xy*px);
    vec3 y = f(xy + e.yx*px) - f(xy - e.yx*px);
    return f(xy)/sqrt(x*x + y*y)*(2.0*e.x);
}

vec3 sdf(vec2 xy) {
    vec3 d = f(xy);
    vec3 x = dFdx(d);
    vec3 y = dFdy(d);
    return d/sqrt(x*x + y*y);
}

void main(void) {
    vec2 px = 1.0/resolution.xy;
    vec2 uv = px*gl_FragCoord.xy;
    vec3 dist = mix(sdf(uv, px.y), sdf(uv, px), step(0.5, uv.x));
    vec3 plot = smoothstep(2.0, 0.0, abs(dist));
    float line = smoothstep(1.0, 0.0, abs(0.5 - uv.x)/px.x);
    glFragColor = vec4(sRGB_OETF(plot + line), 1.0);
}
