#version 420

// original https://www.shadertoy.com/view/dd3cWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sd_box( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, s, -s, c);
    return m * v;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) /resolution.yy;
    const float w = 0.002;
    float col = 0.;
    for (float i = .1; i < 10.; i += .1) {
        float s = sin(time + i * cos(time * .1)) * .15 + .15 + i * .001;
        uv = rotate(uv, time * (.005 + sin(time * .2) * 0.002) + i * .001);
        col = max(col, min(smoothstep(-w, w, sd_box(uv, vec2(s))), smoothstep(w, -w, sd_box(uv, vec2(s)))));
    }
    glFragColor = vec4(vec3(col),1.0);
}
