#version 420

// original https://www.shadertoy.com/view/WlSXWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;

mat2 genRot(float v){
    return mat2(cos(v),-sin(v),sin(v),cos(v));
}

vec2 pMod(vec2 p,float c){
    p *= genRot(PI / c);
    float at = atan(p.y/p.x);
    at = mod(at,2. * PI / c);
    float r = length(p);
    p = vec2(r * cos(at),r * sin(at));
    p *= genRot(-PI / c);
    return p;
}

float cube(vec3 a){
    a = abs(a);
    return max(a.x,max(a.y,a.z));
}

float map(vec3 p){
    vec3 q = p;
    //p.xy *= genRot(p.z * 0.1 * PI);
    p.xy = pMod(p.xy,12.);
    p.xy = (fract(p.xy / 1.5+ .5) - .5) * 1.5;
    p.z = fract(p.z + .5) - .5;
    vec3 r = p;
    float sp = cube(p - vec3(0.5,0.,0.)) - 0.05;
    
    float fi = length(p.xz - vec2(0.5,0.)) - 0.015+ 0.01 * floor(sin(p.y* 6. * PI + time));
    fi = min(fi,length(p.yz) - 0.015 + 0.01 * floor(sin(p.x* 6. * PI + time)));
    fi = min(fi,length(p.xy - vec2(0.5,0.)) - 0.015 + 0.01 * floor(sin(p.z* 6. * PI - time * 2.)));
    fi = max(fi,-(length(q.xy) - 0.5));
    sp = min(sp,fi);
    float con = length(q.xy) - (0.2 + 0.1 * cos(time)* sin(atan(q.y/q.x) * 2. + q.z * PI + time * 2.));
    float resl;
    resl = min(sp,con);
    return resl;
}
vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}

vec4 trace(vec3 o,vec3 r){
    vec3 p;
    float t = 0.;
    for(int i = 0;i< 128; i++){
        p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    vec3 n = getNormal(p);
    return vec4(n,t);
}

vec3 cam(){
    vec3 c = vec3(0.,0.,-1.5);
    c += vec3(cos(time/2.),sin(time/2.),time * PI / 4.);
    c.xy *= 1. + .5 * smoothstep(0.,1.,sin(time));
    return c;
}
vec3 ray(vec2 uv, float z){
    vec3 r = normalize(vec3(uv,z));
    r.yz *= genRot(-PI/3.);
    r.xy *= genRot(PI / 3.);
    r.xy *= genRot(time/2.);
    return r;
}

vec3 getColor(vec3 o,vec3 r,vec4 d){
    float t = d.w;
    vec3 n = d.xyz;
    float rim = 1. - dot(r,n);
    vec3 bc = vec3(rim);
    vec3 p = o + r * t;
    float at = atan(p.y/p.x) * 2.;
    vec3 cc;
    cc = cos(p);
    cc = cc * 0.5 + 0.5;
    cc = length(p.xy) < 0.4 ||
     (fract(p.z + 0.1) < 0.2 &&
     fract(length(p.xy)-time * 2. + at) < 0.4)
     ? cc : vec3(0.);
    bc += cc * 1.;
    float fog = 1./(1.+t*t*0.1);
    bc = mix(bc,vec3(0.),1.-fog);
    return vec3(bc);
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.x;
    vec3 o = cam();
    vec3 r = ray(uv,1.5);
    vec4 d = trace(o,r);
    // Time varying pixel color
    vec3 col = getColor(o,r,d);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
