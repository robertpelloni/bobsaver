#version 420

// original https://www.shadertoy.com/view/lltBDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define numeratorDegree 20
#define denominatorDegree 20

vec4 pi = vec4(0,2,4,8)*atan(1.0);

vec2 cmul (vec2 a, vec2 b){return mat2(a, -a.y, a.x)*b;}
vec2 cinv(vec2 z){return vec2(z.x, -z.y)/dot(z, z);}
vec2 cdiv (vec2 a, vec2 b){return cmul(a, cinv(b));}

float shove(float x){return abs(x) < 0.2 ? x + 0.2*sign(x) : x;}

//bad random function that does what i want
vec4 rand(int n){
    vec4 r = sin(fract(vec4(762.314, 257.831, 856.374, 983.219)*float(n))
               + vec4(345.6, 508.3, 448.9, 633.5)*float(n));
    return vec4(shove(r.x), shove(r.y), shove(r.z), shove(r.w));//make it not stand still
    
}

vec3 color(vec2 p){
    return sqrt(sqrt(length(p)))*(0.5 + 0.5*sin(atan(p.y, p.x) + vec3(0, 0.333, 0.666)*pi.w));
}

vec2 f(vec2 z){
    vec2 result = vec2(1, 0);
    
    for(int i = 1; i <= numeratorDegree; i++){
        vec4 r = rand(i);
        vec2 p = r.xy + r.z*sin(r.w*time + pi.xy);
        result = cmul(result, z - p);
    }
    for(int i = 1; i <= denominatorDegree; i++){
        vec4 r = rand(-i);
        vec2 p = r.xy + r.z*sin(r.w*time + pi.xy);
        result = cdiv(result, z - p);
    }
    return result;
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    glFragColor.rgb = color(f(p));
}
