#version 420

// original https://www.shadertoy.com/view/tlSXDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float t){
    return mat2(cos(t),-sin(t),sin(t),cos(t));
}
vec2 pmod (vec2 p, float c){
    p.xy *= genRot(PI/c);
    float at = atan(p.y/p.x);
    at = mod(at, 2. * PI /c);
    float r = length(p);
    p = vec2(r * cos(at),r * sin(at));
    p.xy *= genRot(-PI/c);
    return p;
    
}
float map(vec3 p){
    float r = 1.0 + 0.5 * sin(p.z * PI / 4.);
    vec3 c = vec3(6.,6.,2.);
    p = (fract(p / c + 0.5) - 0.5) * c;
    p.xy = pmod(p.xy , 6.);
     p.y = abs(p.y);
    float sp = length(p - vec3(1.73,1.0,0.) * r) - 0.5;
    sp = min(sp,length(p.xz - vec2(1.73,0.) * r) - 0.15);
    sp = min(sp,length(p.xy - vec2(1.73,1.) * r) - 0.15);
    return sp;
}

vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}

vec4 trace(vec3 o,vec3 r){
    vec4 data;
    float t;
    for(int i = 0; i < 64; i++){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    vec3 p = o + r * t;
    data.xyz = getNormal(p);
    data.w = t;
    return data;
}

vec3 cam(){
    vec3 c = vec3(3.,3.,-2.5 + time * 3.);
    return c;
}

vec3 ray(vec2 uv,float z) {
    vec3 r = normalize(vec3(uv,z));
    r.xy *= genRot(time);
    return r;
}

vec3 getColor(vec3 p,vec3 r,vec4 d){
    float t = d.w;
    vec3 n = d.xyz;
    vec3 bc = vec3(1. - dot(n,r));
    float fog = 1./(1. + t * t * 0.0125);
    vec3 ccol;
    float at = atan(r.y/r.x) * 2.;
    ccol.x = sin(at + time);
    ccol.y = sin(at + time + PI * 2. / 3.);
    ccol.z = sin(at + time + PI * 4. / 3.);
       ccol  = ccol/2. + 0.5;
    bc *= ccol;
    bc = mix(bc,vec3(.0),1. - fog);
    return vec3(bc);
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y;
    vec3 o = cam();
    vec3 r = ray(uv,1.5 * sin(time));
    // Time varying pixel color
    vec4 data = trace(o,r);
    vec3 col = getColor(o,r,data);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
