#version 420

// original https://www.shadertoy.com/view/ttSSWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float v){
    return mat2(cos(v),-sin(v),sin(v),cos(v));
}
vec2 pmod(vec2 p,float c){
    p *= genRot(PI/c);
    float at = atan(p.y/p.x);
    at = mod(at,PI * 2./c);
    float r = length(p);
    p = vec2(r * cos(at),r * sin(at));
    p *= genRot(-PI/c);
    return p;
    
}
float map(vec3 p){
    vec3 q = (fract(p/4. + 0.5)-0.5) * 4.;
    vec3 s = p;
    s.z = (fract(s.z/4. + 0.5)-0.5) * 4.;
    p.x = p.x * sign(p.y);
    p.y = -abs(-p.y);
    float h =  - 2.5;
    float a = 1.;
    float T = 1.0;
    for(int i = 0; i < 8; i++){
        h += a * sin((p.x - time/4.)/T) * sin((p.z + time/4.)/T);
        a *= 0.5;
        T *= 2.0;
    }
    h = floor(h * 10.)/10.;
    float terrain = p.y - h;
    q.y += time * sign(p.x - 2.);
    float r = floor((0.4 + 0.2 * cos(q.y * PI))* 15.0) / 15.0;
    s.x -= time * sign(s.y);
    s.y = abs(s.y);
    float r2 = floor((0.4 + 0.2 * cos(s.x * PI)) * 15.) / 15.;
    float tower = length(s.yz - vec2(1.25 , 2.)) - r2;
    tower = min(tower,length(q.xz) - r);
    
    return min(terrain,tower);
}
vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}

vec4 trace(vec3 o,vec3 r){
    vec4 d;
    float t = 0.;
    for(int i = 0; i < 96; i++){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    vec3 p = o + r * t;
    vec3 n = getNormal(p);
    return vec4(n,t);
}
vec3 cam (){
 vec3 c = vec3(2.,0.,-2.5 + time * 3.);
    return c;
}
vec3 ray (vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(PI/8.);
    r.yz *= genRot(PI/16.);
    r.xy *= genRot(time/4.);
    return r;
}
vec3 getCol (vec3 o,vec3 r,vec4 d){
    float t = d.w;
    vec3 p = o + r * t;
    vec3 n = d.xyz;
    vec3 ccol;
    float at = atan(r.y/r.x) * 2.;
    ccol.x = sin(at + time);
    ccol.y = sin(at + time + PI * 2./3.);
    ccol.z = sin(at + time + PI * 4. /3.);
    ccol =  ccol / 2. + 0.5;
    vec3 bc = vec3(pow(1. - dot(r,n),2.));
    bc = min(fract(p.x + time * sign(p.x - 2.)),fract(p.z + time)) < 0.1 ? vec3(1.) : bc ;
    bc *= ccol;
    float fog = 1./(1. + t * t * 0.01);
    bc = mix(bc,vec3(1.),1. - fog);
    return bc;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y;
    vec3 o = cam();
    vec3 r = ray(uv,1. + 0.75 * sin(time *1.5));
    vec4 data = trace(o,r);
    vec3 c = getCol(o,r,data);
    glFragColor = vec4(c,1.0);
    
    
}
