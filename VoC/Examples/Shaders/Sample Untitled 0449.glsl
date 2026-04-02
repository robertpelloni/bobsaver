#version 420

// original https://www.shadertoy.com/view/wtjXz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
float sTime(float scale){
    float a = floor(time * scale);
    float b = smoothstep(0.,1.,fract(time * scale));
    return a + b;
}
mat2 genRot(float v){
     return mat2(cos(v),-sin(v),sin(v),cos(v));
}
vec3 modC(vec3 p,vec3 b){
    p = (fract(p / b + 0.5)-0.5) * b;
    return p;
}

float maxEx(vec3 p){
    return max(p.x,max(p.y,p.z));
}

float map(vec3 p){
    //p.xy = abs(p.xy);
    float tmp = 2.;
    p.xy += tmp/2.;
    p = modC(p,vec3(tmp));
    vec3 q = p;
    float sp = length(p) - 0.4;
    sp = min(sp,length(p.yz) - 0.1);
    sp = min(sp,length(p.xz) - 0.1);
    sp = min(sp,length(p.xy) - 0.1);
    
    q.xy *= genRot(PI/4.);
    q.xz *= genRot(time);
    float cb = maxEx(abs(q)) - 0.5;
    cb = max(cb, -(max(abs(q.x),abs(q.y)) - 0.25));
    cb = max(cb, -(max(abs(q.x),abs(q.z)) - 0.25));
    cb = max(cb, -(max(abs(q.z),abs(q.y)) - 0.25));

    return mix(sp,cb,sin(fract(sTime(0.5)) * PI));
}
vec3 getNormal(vec3 p){
    vec3 x= dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}

vec4 trace(vec3 o,vec3 r){
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

vec3 ray(vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(PI / 12.);
    r.yz *= genRot(PI / 12.);

    r.xy *= genRot(cos(sTime(0.125) * PI) * 0.75 * PI);
    return r;
}
vec3 cam(){
    vec3 c = vec3(0.,0.,-2.5 + time * 4.);
    return c;
}

vec3 getColor(vec3 o,vec3 r,vec4 d){
    float t = d.w;
    vec3 n = d.xyz;
    float a = dot(r,n);
    vec3 bc = vec3(1. - a *0.75);
    vec3 cc;
    float at = atan(r.y/r.x) * 2.;
    cc.x = sin(sTime(1.) + at);
    cc.y = sin(sTime(1.) + at + PI  *2. / 3.);
    cc.z = sin(sTime(1.) + at + PI * 4. / 3.);
    cc = cc * 0.5 + 0.5;
    vec3 p = o + r * t;
    cc = fract((length(p.z) + time) / 2.) < 0.75 ? cc : vec3(1.);
    bc *= cc * 1.5;

    float fog = 1./(1. + t * t * 0.05);
    bc = mix(bc,vec3(0.),1.-fog);
    return vec3(bc);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.x;
    vec3 o = cam();
    vec3 r = ray(uv,1. * sin(time * 0.25));
    vec4 d = trace(o,r);
    // Time varying pixel color
    vec3 col = getColor(o,r,d);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
