#version 420

// original https://www.shadertoy.com/view/3st3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;

float random (vec2 st,float t) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123 + t);
}

mat2 genRot(float v){
    return mat2(cos(v),-sin(v),sin(v),cos(v));
}

vec3 modC(vec3 p,vec3 c){
    return (fract((p + 0.5) / c) * c) -0.5;
}

vec2 pmod(vec2 p,float c){
    p *= genRot(PI / c);
    float at = atan(p.y/p.x);
    at = mod(at,2. * PI / c);
    float r = length(p);
    p = vec2(r * cos(at),r * sin(at));
    p *= genRot(-PI / c);
    return p;
    
}

float map(vec3 p){
    p.xy *= genRot(time);
    p.xy *= genRot(p.z / 4.);
    p.z = fract((p.z + 0.5) / 1.) * 1. - 0.5;
    
    p.xy = pmod(p.xy,8.);
    p.xy = fract((p.xy + 0.5) / 2.) * 2. - 0.5;
    float sp = length(p - vec3(1.,0.,0.)) - 0.25;
    //p.xy *= genRot(time);
    sp = min(sp,length(p.xy) - 0.05);
    sp = min(sp,length(p.xz) - 0.05);
    float result = sp;
    return result;
}

vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}

vec4 trace(vec3 c,vec3 r){
    float t = 0.;
    for(int i = 0; i < 128; i++){
        vec3 p = c + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    vec3 p = c + r * t;
    vec3 n = getNormal(p);
    return vec4(n,t);
}

vec3 cam () {
    vec3 c = vec3(0.25 ,0.25,-1.5);
    c.xy *= genRot(time / 2.);
    c.z += time;
    return c;
}

vec3 ray (vec2 uv,float t){
    vec3 r = normalize(vec3(uv,t));
    r.xy *= genRot(time / 2.);
    r.xz *= genRot(time / 2.);
    r.yz *= genRot(time / 2.);
    return r;
}

vec3 getColor(vec3 p,vec3 r,vec4 d){
    float t = d.w;
    vec3 n = d.xyz;
    float fog = 1./(1. + t * t * 0.05);
    vec3 bc = vec3(1. - dot(n,r));
    vec3 cc;
    float at = atan(r.y/r.x) * 2. + time;
    vec3 pos = p + r * t;
    cc.x = sin(at);
    cc.y = sin(at + 2. / 3. * PI);
    cc.z = sin(at - 2. / 3. * PI);
    cc = cc * 0.5 + 0.5;
    cc = fract(pos.z + time) > 0.1 ? cc : vec3(1.);
    bc *= cc;
    bc *= fog;
    return (bc);
}

void main(void) {

    vec2 uv = ( gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    vec2 uvN = (floor(uv * genRot(time) * 5.) / 5.);
    float x = random(uvN , time);
    uv.y += x;
    vec3 o = cam();
    vec3 r = ray(uv,1.5 * sin(time /2.));
    
    vec4 d = trace(o,r);

    vec3 col = x < 0.75 ? getColor(o,r,d): vec3(1.);
    //vec3 col = x < 0.75 ? vec3(0.) : vec3(1.);

    glFragColor = vec4(col, 1.0 );

}
