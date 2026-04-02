#version 420

// original https://www.shadertoy.com/view/MdtcRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 ln (vec2 v) {
    return vec2(log(length(v)), atan(v.x,v.y));
}
vec2 mul (vec2 a, vec2 b) {
    return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);
}
vec3 f (vec2 v) {
    //v = v/dot(v,v);//inverting space only flips fractal!
    for (int i = 0; i < 90; i++) {
        v = mul(ln(v),ln(v));
    }
    return abs(clamp(10.*v.xyy,-.1,1.));
}
void main(void)
{    
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.-1.;
    uv.x *= resolution.x/resolution.y;
    float t = 0.1*time;
    mat2 m = mat2(sin(t),cos(t),-cos(t),sin(t));
    float scale = 1000.*exp(-15.*(-cos(0.2*time)*0.5+0.5));
    vec2 v = scale*((m*uv))+vec2(0.,0.0);
    vec3 e = scale*vec3(1,1,0)/resolution.xyx;
    
    glFragColor = vec4((f(v)+f(v+e.xz)+f(v+e.zy))/3.,1.0);
}
