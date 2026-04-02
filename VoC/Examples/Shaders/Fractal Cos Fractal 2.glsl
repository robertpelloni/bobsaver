#version 420

// original https://www.shadertoy.com/view/lsdcR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 expo (vec2 v) {
    return exp(v.x)*vec2(sin(v.y),cos(v.y));
}
vec2 coso (vec2 v) {
    return vec2 (cos(v.x)*cosh(v.y),-sin(v.x)*sinh(v.y));
}
vec2 sino (vec2 v) {
    return vec2 (cos(v.x)*sinh(v.y),sin(v.x)*cosh(v.y));
}
vec2 cosho (vec2 v) {
    return vec2(cosh(v.x)*cos(v.y), sinh(v.x)*sin(v.y));
}
vec2 sinho (vec2 v) {
    return vec2(sinh(v.x)*cos(v.y), sinh(v.x)*cos(v.y));
}
vec2 mul (vec2 a, vec2 b) {
    return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(.6+sin(0.1*time)*sin(0.1*time))*(gl_FragCoord.xy/resolution.xy*2.-1.);
    uv.x*=resolution.x/resolution.y;
    float b = 0.;
    float t = 0.5*time;
    mat2 m = mat2 (sin(t),cos(t),-cos(t),sin(t));
    vec2 v;
    uv = uv/dot(uv,uv);
    for (int x = -1; x < 2; x++)
        for (int y = -1; y < 2; y++) {
        v = uv+vec2(x,y)/resolution.xy;
        for (int i = 0; i < 10; i++ ) {
            v = sino(mul(coso(v),coso(v)));
            v = m*v;
            if (dot(v,v) > 1e5) {b += 1./9.; break;}
        }
        }
    glFragColor = vec4(dot(v,v),b,b,1.0);
}
