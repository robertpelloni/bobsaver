#version 420

// original https://www.shadertoy.com/view/NlXSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pi 3.1415926535
#define STEPS 96.0
#define MDIST 50.0
#define aspect (resolution.y/resolution.x)

float rand1(float a){
    return fract(sin(dot(vec2(a),vec2(43.234,21.4343)))*94544.3434343)-0.5;
}
//cylinder from iq
float cyl( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 bezier4p(vec2 p1, vec2 p2, vec2 p3, vec2 p4, float t){
    vec2 p = pow(1.0-t,3.0)*p1+
           3.0*pow(1.0-t,2.0)*t*p2+ 
           3.0*(1.0-t)*t*t*p3+
           pow(t,3.0)*p4;  
    return p;
}
float box(vec3 p, vec3 b){
    vec3 d = abs(p)-b;
    return max(d.x,max(d.y,d.z));
}
float pipe(vec3 p){
    float a = 0.0;
    a = cyl(p+vec3(0,9,0),1.0,10.0);
    a = min(a,cyl(p-vec3(0,1,0),1.2,0.2));
    a = max(-(length(p.xz)-0.9),a);
    a-=0.02;
    return a;
}
vec2 aspectize(vec2 a){
    a.x*=aspect;
    a.y/=aspect;
    return a;
}
vec2 map(vec3 p){//oops this became a huge mess, oh well

    vec3 po = p;
    float t = time;
    
    vec2 a = vec2(0);
    vec2 b = vec2(1);
    
    float ps = 0.5; //Pipe Smooth Time
    float prt = 3.0;//Pipe Repeat Time
    
    vec2 pipe1Pos = vec2(0);
    vec2 pipe2Pos = vec2(0);
    float cycleInt = floor(t/prt+1.0);
    
    //Pipe Up/Down Movement
    pipe1Pos.y = 10.0-5.0*smoothstep(0.0,ps,mod(t,prt))*smoothstep(prt,prt-ps,mod(t,prt));
    //Side to Side randomize
    float sideScale = 13.0;
    
    pipe1Pos.x+=rand1(cycleInt)*sideScale;
    pipe2Pos.x+=rand1(cycleInt*1.01)*sideScale;
    
    pipe2Pos.y = pipe1Pos.y;
    
    
    float pipe1Rot = floor((rand1(cycleInt*1.02)+0.5)*4.0);
    float pipe2Rot = floor((rand1(cycleInt*1.03)+0.5)*4.0);
    
    if(pipe1Rot==pipe2Rot){
        pipe1Pos.x = abs(pipe1Pos.x)-sideScale*0.5-1.5;
        pipe2Pos.x = -abs(pipe2Pos.x)+sideScale*0.5+1.5;
    }
    
    if(pipe1Rot==1.0||pipe1Rot==3.0){
        pipe1Pos.x*=aspect;
        pipe1Pos.y/=aspect;
    }
    
    p.xy*=rot((pi/2.0)*pipe1Rot);
    p.xy+=pipe1Pos;
    a.x = pipe(p);
    
    p = po;
    
    if(pipe2Rot==1.0||pipe2Rot==3.0){
        pipe2Pos.x*=aspect;
        pipe2Pos.y/=aspect;
    }
    
    p.xy*=rot((pi/2.0)*pipe2Rot);
    p.xy+=pipe2Pos;
    
    b = vec2(pipe(p),0.0);
    
    a=(a.x<b.x)?a:b;    
    
    float pathDisp = 8.0; //Try increasing this :)
    vec2 p1 = pipe1Pos*rot(3.0*(pi/2.0)*pipe1Rot);
    vec2 p2 = (pipe1Pos+vec2(0,-pathDisp))*rot(3.0*(pi/2.0)*pipe1Rot);
    vec2 p3 = pipe2Pos*rot(3.0*(pi/2.0)*pipe2Rot);
    vec2 p4 = (pipe2Pos+vec2(0,-pathDisp))*rot(3.0*(pi/2.0)*pipe2Rot);
    
    float loops =16.0;
    for(float i = 0.0; i <loops; i ++){
        float tp = min(-prt*0.5+fract(t/prt)*prt+i/loops,1.1);
        vec2 boxp = bezier4p(p1,p2,p4,p3,tp);
        p = po;
        p+=vec3(boxp,0);
        p.xy*=rot(t+(i/16.0)*13.0);
        p.xz*=rot(t+(i/16.0)*13.0);
        p = abs(p)-vec3(0.45,0.45,0.0);
        b = vec2(box(p,vec3(0.15)),1.0);
        if(fract(t/prt)*3.0>ps) a=(a.x<b.x)?a:b;
    }
    
    return a;
}

vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col =vec3(0);
    
    vec3 ro = vec3(0,0,-30);
    vec3 rd = normalize(vec3(uv,3.0));
    
    vec3 p;
    vec2 d;
    float dO, shad;
    bool hit = false;
    
    for(float i = 0.0; i < STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x;
        
        if(abs(d.x)<0.01){
            shad = i/STEPS;
            hit = true;
            break;
        }
        if(dO>MDIST){
            p = ro+rd*MDIST;
            break;
        }
    }
    if(hit){
    vec3 n = norm(p);
    vec3 ld = vec3(-0.5,0.5,-1);
    vec3 h = normalize(ld-rd);
    float spec = pow(max(dot(n,h),0.0),30.0);
    float fres = pow(1. - max(dot(n, -rd),0.), 5.);
    float diff = max(dot(n, ld),0.);
    
    
    vec3 al;
    if(d.y == 0.0) al = vec3(0.035,0.757,0.216);
    if(d.y == 1.0) al = vec3(0.792,0.247,0.255);
    col = vec3(diff*0.5);
    col += spec*0.5;
    col+=fres*0.2;
    col+=(1.0-shad)*0.5;
    col*=al;
    
    }
    
    //vec3 sky = mix(vec3(0.180,0.616,1.000),vec3(0.278,0.235,0.843),clamp(-p.y*0.1+0.4,0.0,1.0));
    
    if(!hit)col = vec3(0.302,0.545,1.000)*(1.0-0.5*length(uv*uv));
    col*=clamp(sin(uv.y*resolution.y+time),0.8,1.0);
    glFragColor = vec4(col,1.0);
}
