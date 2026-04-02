#version 420

// original https://www.shadertoy.com/view/sdjSzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28
#define WAVES 20
float wave(vec2 uv, float a, float h, float c) {
    float s = sin(uv.x * h * TAU) * 0.5 + 0.5 + sin(time+uv.x*5.+c*1.2);
    s *= a;
    return abs(s - (uv.y - c));
}
float map(vec2 uv, out int id) {
    float d = 10000.;
    for(int i = 0; i < WAVES; i++) {
        float ipoke = float(i)*.01;
        float amp = 0.1 + ipoke;
        float per = 2. + ipoke;
        float offs = -.5+ipoke * 10.;
        float dd = wave(uv, amp, per, offs);
        if (dd < d) {
            id = i;
            d = dd;
        }
    }
    return d;
}
void main(void)
{
    float blocks = floor((sin(time)*.5+.5)*50.+5.);
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 cell = floor(uv * blocks)/blocks;
    int mat = -1;
    float w = map(cell, mat);
    float d = step(0.,w);
    vec3 baseCol = vec3(1,1,0);
    for (int i = 0; i < mat; i++){baseCol = baseCol.yzx;}
    vec3 col = vec3(d) * baseCol;
    glFragColor = vec4(col,1.0);
}
