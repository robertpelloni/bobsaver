#version 420

// original https://www.shadertoy.com/view/XtXXR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define REP  256
#define STEP 0.125

vec2 rot(vec2 p, float a) {
    return vec2(
        p.x * cos(a) - p.y * sin(a),
        p.x * sin(a) + p.y * cos(a));
}

vec3 toCol(float t) {
    vec3 col = vec3(0.0);
    col.r += 0.1;
    if(t < 0.3)  col.r += 1.5;
    if(t < 0.5)  col.g += 1.2;
    if(t < 0.7)  col.b += 1.0;
    return vec3(col);
}

float map(vec3 p) { return abs(cos(p.x * 0.9) + sin(p.y * 0.9) + cos(p.z * 0.9)); }

void main(void) {
    float time = time;
    vec2 uv   = -1.0 + 2.0 * (  gl_FragCoord.xy / resolution.xy );
    uv.x     *= resolution.x / resolution.y;
    vec3 dir  = normalize(vec3(uv, 0.5 + sin(time) * 0.2));
    dir.yz    = rot(dir.yz, time * 0.03);
    dir.xy    = rot(dir.xy, time * 0.05);
    vec3 pos  = vec3(time, 0, time * 5.0);
    float d   = 0.0;
    vec3 col  = vec3(0.0);
    for(int i = 0 ; i < REP; i++) {
        float temp = map(pos + dir * d);
        col += toCol(temp);
        d   += STEP;
    }
    col *= 0.007;
    col = pow(col, vec3(2.2));
    glFragColor = vec4(col, 1.0);
}
