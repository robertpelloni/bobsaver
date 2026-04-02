#version 420

// original https://www.shadertoy.com/view/Wl2XW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}
vec2 pmod(vec2 p,float count){
    p *= genRot(PI/count);
    float at = atan(p.y/p.x);
    float r = length(p);
    at = mod(at,2. * PI / count);
    p = vec2(r * cos(at),r * sin(at));
    p *= genRot(-PI/count);
    return p;
}
float map(vec3 p){
    p = fract(p + 0.5)-0.5;
    vec3 q = p;
    float cube = min(length(q.xz + sin(q.y *2.*PI + time) * 0.1) - 0.05,length(q.yz - sin(q.x *2.*PI+ time) * 0.1 ) - 0.05);
    cube = min(cube,length(q.xy + sin(q.z *2.*PI + time) * 0.1 )- 0.05);
    //cube = min(cube,length(p)- 0.1);
    return cube;
}
vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}
vec4 trace(vec3 o,vec3 r){
    float t = 0.;
    vec3 p;
    for(int i = 0; i < 128; i++){
        p = o + r * t;
        float d = map(p);
        t += d * 0.75;
    }
    vec3 n = getNormal(p);
    return vec4(n,t);
}

vec3 cam(){
    vec3 c = vec3(.5,.5,-1.5 + time);
    return c;
}
vec3 ray(vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(PI/6.);
    r.yz *= genRot(PI/6.);
    return r;
}

vec3 getColor(vec3 o, vec3 r, vec4 d){
    vec3 n = d.xyz;
    float t = d.w;
    vec3 l = vec3(-1.);
    float s = dot(l,n);
    vec3 c;
    float fog = 1./(1. + t * t * 0.05);
    c = s < -0.8 ? vec3    (159,158,137)/255. : 
    (s > 0.8 ? vec3    (213,211,187)/255. : vec3(185,178,155)/255.);
    c = mix(vec3(55,15,8)/255.,c,fog);
    return c;
    
}

void main(void) {

    vec2 uv = ( gl_FragCoord.xy * 2. - resolution.xy) / resolution.y ;
    vec3 c = cam();
    vec3 r = ray(uv,1.5);
    vec4 d = trace(c,r);
    vec3 color = getColor(c,r,d);

    glFragColor = vec4( color, 1.0 );

}
