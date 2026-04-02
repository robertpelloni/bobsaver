#version 420

// original https://www.shadertoy.com/view/MsVXRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cis(float a){
    return vec2(cos(a),sin(a));
}
vec2 cMul(vec2 a, vec2 b) {
    return vec2( a.x*b.x -  a.y*b.y,a.x*b.y + a.y * b.x);
}
vec2 cInverse(vec2 a) {
    return  vec2(a.x,-a.y)/dot(a,a);
}
vec2 M(vec2 z){
    vec2 c = 0.3250*cis(sin(time*3.)/2.+0.300);
    for (int i=0; i<17;i++){
        if( dot(z,z)>22.0 ) continue;
        z = cMul(z,z) + c;
    }
    return z;
}
vec3 domain(vec2 z){
    z = vec2(length(z)+.19,atan(z.y,z.x)/3.14);
    float p=exp2(ceil(-log2(1.-z.x)));
    return vec3(mod(z.y,2./p)*p<1.);
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy-0.5)*2.2;; 
    uv.x *= resolution.x/resolution.y;
    uv = cInverse(M(cInverse(uv)));
    glFragColor = vec4(domain(uv),1.0);
}
