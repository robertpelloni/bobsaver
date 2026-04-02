#version 420

// original https://www.shadertoy.com/view/Xs3SWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

vec2 cInverse(vec2 a) { return    vec2(a.x,-a.y)/dot(a,a); }
vec2 cMul(vec2 a, vec2 b) {    return vec2( a.x*b.x -  a.y*b.y,a.x*b.y + a.y * b.x); }
vec2 cDiv(vec2 a, vec2 b) {    return cMul( a,cInverse(b)); }
vec2 cExp(vec2 z) {    return vec2(exp(z.x) * cos(z.y), exp(z.x) * sin(z.y)); }
vec2 cLog(vec2 a) {    float b =  atan(a.y,a.x); if (b>0.0) b-=2.0*PI;return vec2(log(length(a)),b);}

void main(void)
{
    vec2 z = (gl_FragCoord.xy - resolution.xy/2.)/resolution.y;
    float r1 = 0.1, r2 = 1.0,
        scale = log(r2/r1),angle = atan(scale/(2.0*PI));
    // Droste transform here
    z = cLog(z);
    z.y -= time/2.;
    z = cDiv(z, cExp(vec2(0,angle))*cos(angle)); // Twist!
    z.x = mod(z.x-time,scale);
    z = cExp(z)*r1;
    // Drawing time.
    z = sin(z*25.)*3.;
    glFragColor = vec4(z.x*z.y);
}
