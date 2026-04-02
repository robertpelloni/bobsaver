#version 420

#define S(a, b, t) smoothstep(a, b, t)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DistLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot(pa, ba)/dot(ba, ba), 0., 1.);
    return length(pa - ba*t);
}

float N21(vec2 p) {
    p = fract(p*vec2(233.34, 851.73));
    p += dot(p, p+23.45);
    return fract(p.x*p.y);
}

vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(p+n));
}

vec2 GetPos(vec2 id) {
    vec2 n = N22(id)*time;
    
    return sin(n)*.4;
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy -.5 * resolution.xy) / resolution.y;
    
    //float d = DistLine(uv, vec2(0), vec2(1));
    float m = 0.;
    
    uv *= 5.;
    
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    
    vec2 p = GetPos(id);
    
    float d = length(gv-p);
    m = S(.1, .07, d);
    vec3 col = vec3(m);

    
    
    //col.rg = id *.2;
    if (gv.x >.48|| gv.y>.48) col = vec3(0.,1.,0.);
    glFragColor = vec4(col, 1.0);

}
