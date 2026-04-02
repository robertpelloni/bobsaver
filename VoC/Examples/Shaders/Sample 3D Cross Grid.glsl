#version 420

// original https://www.shadertoy.com/view/Wd2GRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1416
#define MAX_DIST 10.0
#define EPS 0.0001
#define ITR 100.0
vec2 delta = vec2(.01,0);
vec3 lastCell = vec3(0);

vec2 rotate(vec2 v, float angle) {return cos(angle)*v+sin(angle)*vec2(v.y,-v.x);}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rand2(vec2 co){
    return fract(sin(vec2(dot(co.xy ,vec2(12.9898,78.233)),dot(co.yx,vec2(13.1898,73.231)))) * 43758.5453);
}

float rand3(vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233, 49.566))) * 43758.5453);
}

mat3 lookat(vec3 fw){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,vec3(0.0,1.0,0.0)));return mat3(rt,cross(rt,fw),fw);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float SDF(vec3 ro, vec3 rd) {
    float d =MAX_DIST;
    vec3 c = ro + .5;
    lastCell = floor(c);
    ro=fract(c)-.5;
    
    float t = time*.8 + length(lastCell)*.3;
    float p = fract(t);
    float r = p;//length(lastCell);
    r *= PI / 2.0;
    switch(int(mod(t,3.0))){
        case 0: ro.xy = rotate(ro.xy,r); break;
        case 1: ro.yz = rotate(ro.yz,r); break;
        case 2: ro.zx = rotate(ro.zx,r); break;
    }
    
    t= min(.1,length(ro.xy));
    d = min(d, length(ro)*.1);
    d = min(d, length(ro.xy)-t);
    d = min(d, length(ro.yz)-t);
    d = min(d, length(ro.zx)-t);
    d = max(d, length(ro)-.45);
    return d;
}

vec3 EstNormal(vec3 ro, vec3 rd) {
    float cx = SDF(ro+delta.xyy, rd)-SDF(ro-delta.xyy, rd);
    float cy = SDF(ro+delta.yxy, rd)-SDF(ro-delta.yxy, rd);
    float cz = SDF(ro+delta.yyx, rd)-SDF(ro-delta.yyx, rd);
    return normalize(vec3(cx,cy,cz));
}

vec3 scene(vec3 ro, vec3 rd, vec2 uv) {
    vec3 p = ro;
    float t;
    float d;
    float i = 0.0;
    float c = 1.0;
    vec3 pos;
    for(; i < ITR ; i++) {
        t += d = SDF(pos=ro+rd*t,rd);
        c = min(d,c);
        if(t > MAX_DIST || d < EPS) break;
    }
       vec3 cell = lastCell;
    vec3 normal = EstNormal(pos, rd);
    
    
    vec3 lightPos = ro + vec3(sin(time),cos(time),cos(time*.1))*100.0;
    vec3 lightDir = normalize(lightPos - pos);
    vec3 lightColor = hsv2rgb(vec3(time*.1,.5+.5*sin(time*.2),1));
    float lightDist = length(lightPos-pos)+length(ro-pos);
    float l = -dot(normal, lightDir);
    //float l = clamp(0.0,1.0,dot(reflect(rd,normal), normalize(lightPos)));
    
    vec3 color = hsv2rgb(vec3(rand3(cell),1,1));
    return color*(lightColor/lightDist + dot(normal,-rd)/t);
    //return fract(ro+rd*t)/d*.02;
}

void main(void)
{
    float tim=time;
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    tim*=0.5;
    vec3 ro=vec3(cos(tim),cos(tim*0.3)*0.5,cos(tim*0.7))*min(0.5+tim*0.1+cos(tim*0.4)*0.5,1.5);
    vec3 rd=lookat(-ro)*normalize(vec3((gl_FragCoord.xy-0.5*resolution.xy)/resolution.y,1.0));
    
    ro.yz *= .2;
    ro.yz += .5;
    ro.x += time*.5;
    
    vec3 color=scene(ro,rd,gl_FragCoord.xy);
    color=clamp(color,0.0,min(tim,1.0));
    glFragColor = vec4(color,1.0);
}
