#version 420

// original https://www.shadertoy.com/view/wtBXDm

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
    vec3 mc = vec3(3.5,3.5,1.5);
        float r = 0.9 + 0.4 * sin(p.z);
    p.xy *= genRot(p.z / 8. + sqrt(length(p.xy))/4. + time/32.);
//    p = (fract(p /mc + 0.5)-0.5)*mc;
    p.xy = pmod(p.xy,6.);
    p.xy -= vec2(1.73,0.) * r;
    
    p.xy += vec2(1.73,0.) * r;
    p = (fract(p /mc + 0.5)-0.5)*mc;

    float pil = length(p.xz - r * vec2(1.73,0.0)) - 0.1;
    pil = min(pil,length(vec2(p.x,abs(p.y)) - r * vec2(1.73,1.)) - 0.1);
    vec3 q = p;
    q.y = abs(q.y);
    pil = min(pil,length(q - vec3(1.73,1.,0.) * r) - 0.25);
    vec3 cp = abs(p - vec3(1.73,0.,0.) * r /2.);
    cp.xy *= genRot(abs(sin(time)*1.25));
    float cb = max(cp.x,max(cp.y,cp.z)) - 0.1;
    pil = min(pil,cb);
    return pil;
}
vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}
vec4 trace(vec3 o,vec3 r){
    vec4 data;
    float t = 0.;
    for(int i = 0; i < 128; i++){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    vec3 p = o + r  * t;
    vec3 n = getNormal(p);
    return vec4(n,t);
}    
vec3 getCol(vec3 o,vec3 r,vec4 d){
    float t = d.w;
    vec3 n = d.xyz;
    vec3 p = o + r * t;
    float fog = 1./(1. + t * t * 0.005);
    vec3 col = vec3(pow(1. - dot(n,r) * 0.75,2.));
    vec3 ccol ;
    float at = atan(p.y/p.x) * 2. + p.z;
    ccol.x = sin(at + time*2.);
    ccol.y = sin(at + time*2. + PI * 2./3.);
    ccol.z = sin(at + time*2. - PI * 2./3.);
    ccol= ccol/1.8 + 0.5;
    col *= ccol;
    col = mix(col,vec3(0.),1. - fog);
    return col;
}

vec3 cam(){
    vec3 c = vec3(0.,0.,-2.5 + time * 3.);
    return c;
}
vec3 ray(vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(PI/8.);
    r.yz *= genRot(PI/16.);
    r.xy *= genRot(time/4.);
    return r;
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y;
    uv.y += sign(uv.x) * sign(sin(time)) * sqrt(abs(sin(time))) * 0.5;
    uv.x += sign(uv.y) * sign(sin(time)) * sqrt(abs(sin(time))) * 0.5;
    vec3 o = cam();
    vec3 r = ray(uv,1.2 + 0.5 * sin(time * PI / 4.));
    vec4 d = trace(o,r);
    vec3 c = getCol(o,r,d);
    float vig = 1. - length(uv) * 0.05;

    c *= vig;
    // Time varying pixel color
    glFragColor = vec4(c,1.0);
}
