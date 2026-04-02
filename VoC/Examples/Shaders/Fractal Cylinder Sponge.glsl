#version 420

// original https://www.shadertoy.com/view/XsfczB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int iter =100;
const float eps = 0.001, far = 30.;
const vec3[2] lDir = vec3[](normalize(vec3(1,2,1)), normalize(vec3(-1,1,-2)));
const vec3[2] lCol = vec3[](vec3(1,.8,.5), vec3(.6,.8,1)); 

float cylUnion(vec3 p){
    float xy = dot(p.xy,p.xy);
    float xz = dot(p.xz,p.xz);
    float yz = dot(p.yz,p.yz);
    return sqrt(min(xy,min(xz,yz))) - 1.;
}

float cylIntersection(vec3 p){
    float xy = dot(p.xy,p.xy);
    float xz = dot(p.xz,p.xz);
    float yz = dot(p.yz,p.yz);
    return sqrt(max(xy,max(xz,yz))) - 1.;
}

float DE(vec3 p){

    float d = cylIntersection(p);
    vec3 q = p;
    float s = 1.;
    for(int i = 0;i<5;i++){
        q *= 3.;
        s*=3.;
        float d2 = cylUnion(q) / s;
        d = max(d,-d2);
            q = mod(q+1. , 2.) - 1.;
        
    }
    return d;
}

vec2 march(vec3 ro, vec3 rd){
    float t=0. , d = far, it = 0.;
    for (int i=0;i<iter;i++){
         t += (d = DE(ro+t*rd));
        if(d<eps || t> far) break;
        it += 1.;
    }
    return vec2(t,it/float(iter));
}

float getShadow(vec3 p, vec3 n, int index){
    p +=  2. * eps * n;
    float t=0.,d=far;
    for(int i=0;i<50;i++){
        t += (d=DE(p + t*lDir[index]));
        if (d<eps || t>3.) break;
    }
    return t<=3. ? 0.1 : 1. ;
}

vec3 getRay(vec3 ro, vec3 look, vec2 uv){
    vec3 f = normalize(look - ro);
    vec3 r = normalize(vec3(f.z,0,-f.x));
    vec3 u = cross (f,r);
    return normalize(f + uv.x * r + uv.y * u);
}

vec3 getNorm(vec3 p){
    vec2 e = vec2(eps, 0);
    return normalize(vec3(DE(p+e.xyy)-DE(p-e.xyy),DE(p+e.yxy)-DE(p-e.yxy),DE(p+e.yyx)-DE(p-e.yyx)));
}

vec3 light(vec3 p, vec3 n){
    vec3 col = vec3(0);
    for(int i=0;i<2;i++){
        float diff = max(dot(n, (lDir[i])),0.);
        diff *= getShadow(p, n, i);
        col += diff * lCol[i];
    }
    return col * .7;
}

void main(void)
{
    float time = time * .4;
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    float s1 = sin(time), c1 = cos(time);
    float arg = 1.5*sin(time*.7894)*.5 + .5;
    float s2 = sin(arg), c2 = cos(arg);
    vec3 ro = vec3(0, .2, 1)*2.5;
    ro.yz = mat2(c2,-s2,s2,c2)*ro.yz;
    ro.xz = mat2(c1,s1,-s1,c1)*ro.xz;
    vec3 rd = getRay(ro, vec3(0.), uv);
    vec2 hit = march(ro, rd);
    vec3 p = ro + hit.x*rd;
    vec3 col = hit.x<far ? light(p, getNorm(p)) : vec3(.1*(1.-length(uv)));
    col += pow(hit.y,3.);
    glFragColor = vec4(sqrt(col),1.0);
}
