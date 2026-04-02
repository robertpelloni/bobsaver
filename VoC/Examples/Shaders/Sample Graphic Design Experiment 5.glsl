#version 420

// original https://www.shadertoy.com/view/dsBXWR

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0005
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Tri(p,s,a) max(-dot(p,vec2(cos(-a),sin(-a))),max(dot(p,vec2(cos(a),sin(a))),max(abs(p).x-s.x,abs(p).y-s.y)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define SPEED 200.
#define ZERO (min(frames,0))
#define PI 3.141592653589793

#define FS 0.1 // font size
#define FGS FS/5. // font grid size

#define char_0 0
#define char_1 1
#define char_2 2
#define char_3 3
#define char_4 4
#define char_5 5
#define char_6 6
#define char_7 7
#define char_8 8
#define char_9 9

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

float getTime(float t, float duration){
    return clamp(t,0.0,duration)/duration;
}

// thx iq! https://iquilezles.org/articles/distfunctions2d/
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float char1(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(-FGS*2.,FGS*4.),vec2(FGS*3.,FGS));
    
    float d2 = B(p,vec2(FGS,FS));
    d = min(d,d2);

    d2 = B(p-vec2(0.,-FGS*4.),vec2(FS,FGS));
    d = min(d,d2);
    
    return d;
}

float char2(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(FGS*2.,FGS*4.),vec2(FGS*3.,FGS));
    
    float d2 = B(p-vec2(FGS*4.,FGS*2.),vec2(FGS,FGS*3.));
    d = min(d,d2);
    d2 = B(p-vec2(FGS*2.,0.),vec2(FGS*3.,FGS));
    d = min(d,d2);
    
    d2 = B(p-vec2(0.,-FGS*4.),vec2(FS,FGS));
    d = min(d,d2);
    
    p-=vec2(-FGS*2.,FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    p = prevP;
    p-=vec2(-FGS*2.,-FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);    
    
    return d;
}

float char3(vec2 p) {
    vec2 prevP = p;
    
    p.y = abs(p.y);
    float d = B(p-vec2(0.,FGS*4.),vec2(FS,FGS));
    
    p = prevP;
    p.x = abs(p.x);
    float d2 = B(p-vec2(FGS*4.,-FGS*2.),vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    p = prevP;
    d2 = B(p-vec2(FGS*2.,0.),vec2(FGS*3.,FGS));
    d = min(d,d2);
    

    p-=vec2(FGS*2.,FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);   

    return d;
}

float char4(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(0.,-FGS*2.),vec2(FS,FGS));
    
    float d2 = B(p-vec2(-FGS*2.,0.),vec2(FGS,FS));
    d = min(d,d2);
    
    d2 = B(p-vec2(FGS*2.,-FGS*2.),vec2(FGS,FGS*3.));
    d = min(d,d2);

    return d;
}

float char5(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(0.,FGS*4.),vec2(FS,FGS));
    
    float d2 = B(p,vec2(FS,FGS));
    d = min(d,d2);
    
    d2 = B(p-vec2(-FGS*4.,FGS*2.),vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    p = prevP;
    d2 = B(p-vec2(-FGS*2.,-FGS*4.),vec2(FGS*3.,FGS));
    d = min(d,d2);
    
    p-=vec2(FGS*2.,-FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    return d;
}

float char6(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(FGS*2.,FGS*4.),vec2(FGS*3.,FGS));
    
    float d2 = B(p,vec2(FS,FGS));
    d = min(d,d2);
    
    p-=vec2(-FGS*2.,FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    p = prevP;
    d2 = B(p-vec2(0.,-FGS*4.),vec2(FS,FGS));
    d = min(d,d2);
    
    p.x = abs(p.x);
    d2 = B(p-vec2(FGS*4.,-FGS*2.),vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    return d;
}

float char7(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p,vec2(FS,FGS));
    
    p*=Rot(radians(45.));
    float d2 = B(p,vec2(FGS,FS*1.2));
    d = min(d,d2);
    
    p = prevP;

    
    d2 = B(p-vec2(0., FGS*4.),vec2(FS,FGS));
    d = min(d,d2);
    
    return d;
}

float char8(vec2 p) {
    vec2 prevP = p;
    
    p.y = abs(p.y);
    float d = B(p-vec2(0., FGS*4.),vec2(FS,FGS));
    
    p = prevP;
    p*=Rot(radians(45.));
    float d2 = B(p,vec2(FGS,FS*1.2));
    d = min(d,d2);
    
    p = prevP;
    p*=Rot(radians(-45.));
    d2 = B(p,vec2(FGS,FS*1.2));
    d = min(d,d2);
    
    return d;
}

float char9(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(FGS*4.,FGS*2.),vec2(FGS,FGS*3.));
    
    p = prevP;
    float d2 = B(p-vec2(FGS*2.,FGS*4.),vec2(FGS*3.,FGS));
    d = min(d,d2);

    d2 = B(p-vec2(-FGS*2.,-FGS*4.),vec2(FGS*3.,FGS));
    d = min(d,d2);
    
    d2 = B(p,vec2(FS,FGS));
    d = min(d,d2);
    
    p-=vec2(-FGS*2.,FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    p =prevP;    
    p-=vec2(FGS*2.,-FGS*2.);
    p*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    return d;
}

float char0(vec2 p) {
    vec2 prevP = p;
    
    float d = B(p-vec2(-FGS*4.,0.),vec2(FGS,FS));
    
    float d2 = B(p-vec2(-FGS*2.,FGS*4.),vec2(FGS*3.,FGS));
    d = min(d,d2);

    d2 = B(p-vec2(0.0,-FGS*4.),vec2(FS,FGS));
    d = min(d,d2);
    
    p-=vec2(FGS*2.,FGS*2.);
    p*=Rot(radians(-45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    p =prevP;  
    d2 = B(p-vec2(FGS*4.,-FGS*2.),vec2(FGS,FGS*3.));
    d = min(d,d2);
    
    return d;
}

float checkChar(int targetChar, int achar){
    return 1.-abs(sign(float(targetChar) - float(achar)));
}

float charMask(vec2 p, float d){
    float a = radians(45.);
    p = abs(p)-0.08;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    return d;
}

float drawFont(vec2 p, int achar){
    float d = char0(p)*checkChar(char_0,achar);
    d += char1(p)*checkChar(char_1,achar);
    d += char2(p)*checkChar(char_2,achar);
    d += char3(p)*checkChar(char_3,achar);
    d += char4(p)*checkChar(char_4,achar);
    d += char5(p)*checkChar(char_5,achar);
    d += char6(p)*checkChar(char_6,achar);
    d += char7(p)*checkChar(char_7,achar);
    d += char8(p)*checkChar(char_8,achar);
    d += char9(p)*checkChar(char_9,achar);
    
    d = charMask(p,d);
    
    #ifdef OUTLINE
        return abs(d)-0.005;
    #endif
    
    return d;
}

float y2kItem0(vec2 p){
    vec2 prevP = p;
    float thick = 0.005;
    float size = 0.1;
    float d = abs(length(p)-size)-thick;
    p.x*=2.0;
    p.x = abs(p.x)-0.06;
    float d2 = length(p)-0.02;
    d = min(d,d2);
    p = prevP;
    d2 = abs(length(p)-0.08)-thick;
    d2 = max(p.y+0.03,d2);
    d = min(d,d2);
    
    return d;
}

float y2kItem1(vec2 p){
    vec2 prevP = p;
    float thick = 0.005;
    float size = 0.1;
    float d = abs(length(p)-size)-thick;
    p.x*=2.0;
    float d2 = abs(length(p)-size)-thick;
    d = min(d,d2);
    p = prevP;
    
    p.y*=2.0;
    d2 = abs(length(p)-size)-thick;
    d = min(d,d2);
    
    p = prevP;
    
    d2 = max(abs(p.x)-size,abs(p.y)-thick);
    d = min(d,d2);
    d2 = max(abs(p.y)-size,abs(p.x)-thick);
    d = min(d,d2);
    
    return d;
}

float y2kItem2_1(vec2 p){
    p.x*=2.;
    vec2 prevP = p;
    float size = 0.1;
    p.x*=1.5;
    float d = length(p)-size;
    p-=vec2(0.025,-0.01);
    p.x*=1.1;
    float mask = length(p)-(size);
    d = max(-mask,d);
    return d;
}

float y2kItem2_2(vec2 p){
    vec2 prevP = p;
    p-=vec2(-0.01,0.015);
    float d = y2kItem2_1(p);
    p = prevP;
    p+=vec2(-0.01,0.015);
    p*=-1.;
    float d2 = y2kItem2_1(p);
    d = min(d,d2);
    return d;
}

float y2kItem2(vec2 p){
    p*=Rot(radians(5.));
    vec2 prevP = p;
    p*=Rot(radians(45.));
    float d = y2kItem2_2(p);
    p = prevP;
    p*=Rot(radians(-45.));
    float d2 = y2kItem2_2(p);
    d = min(d,d2);
    return d;
}

float y2kItem3(vec2 p){
    p*=Rot(radians(20.*time));
    vec2 prevP = p;
    float thick = 0.005;
    float size = 0.1;
    p.x*=3.;
    float d = abs(length(p)-size)-thick;
    p = prevP;
   
    p.y*=3.;
    float d2 = abs(length(p)-size)-thick;
    d = min(d,d2);
    p = prevP;
    p*=Rot(radians(-45.));
    p.x*=3.;
    d2 = abs(length(p)-size)-thick;
    d = min(d,d2);
    p = prevP;
    p*=Rot(radians(45.));
    p.x*=3.;
    d2 = abs(length(p)-size)-thick;
    d = min(d,d2);
    
    return d;
}

float y2kItem4(vec2 p){
    vec2 prevP = p;
    float size = 0.1;
    
    float d = B(p,vec2(size));
    p = abs(p)-size;
    float d2 = length(p)-size;
    d = max(-d2,d);
    
    return d;
}

float y2kItem5_1(vec2 p){
    vec2 prevP = p;
    float size = 0.1;
    
    float d = B(p,vec2(size*2., size));
    float a = radians(-45.);
    p.x = abs(p.x)-0.2;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    
    return d;
}

float y2kItem5(vec2 p){
    vec2 prevP = p;
    float size = 0.1;

    float d = B(p,vec2(size*5.5, size));
    float a = radians(-20.);
    p.x-=0.5;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    a = radians(-20.);
    p.x+=0.5;
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    d = max(-y2kItem5_1(p-vec2(-0.25,0.13)),d);
    p-=vec2(0.25,-0.13);
    p.y*=-1.;
    d = max(-y2kItem5_1(p),d);
    
    p = prevP;
    
    p*=Rot(radians(45.));
    p.x = abs(p.x)-0.04;
    d = max(-(abs(p.x)-0.02),d);
    
    return abs(d)-0.005;
}

float y2kItem6(vec2 p, float dir){
    p*=2.;
    p.x+=time*0.2*dir;
    p.x = mod(p.x,0.4)-.2;
    p.x = abs(p.x)-0.1;
    p.x*=-1.;
    vec2 prevP = p;
    float d = B(p,vec2(0.05,0.01));
    p-=vec2(0.04,0.03);
    float d2 = B(p,vec2(0.01,0.02));
    d = min(d,d2);
    p = prevP;
    p-=vec2(-0.01,0.04);
    d2 = B(p,vec2(0.06,0.01));
    d = min(d,d2);
    p = prevP;
    p-=vec2(-0.08,0.0);
    d2 = B(p,vec2(0.01,0.05));
    d = min(d,d2);
    p = prevP;
    p-=vec2(0.01,-0.04);
    d2 = B(p,vec2(0.08,0.01));
    d = min(d,d2);
    p = prevP;
    p-=vec2(0.08,0.0);
    d2 = B(p,vec2(0.01,0.05));
    d = min(d,d2);
    
    return d;
}

float y2kItem7(vec2 p){
    vec2 prevP = p;
    p*=Rot(radians(time*-25.));
    p = DF(p,1.25);
    p -= vec2(0.032);
    p*=Rot( radians(45.));
    float d = B(p,vec2(0.02,0.05));
    p.x-=0.015;
    p.y-=0.02;
    p.y*=-1.;
    float d2 = Tri(p,vec2(0.04,0.03),radians(45.));
    d = min(d,d2);
    
    return abs(d)-0.005;
}

float y2kItem8(vec2 p){
    vec2 prevP = p;
    
    p.x+=time*0.05;
    p.x+=0.02;
    p.x = mod(p.x,0.04)-0.02;
    p.x+=0.02;
    p*=Rot(radians(-90.));
    float d = Tri(p,vec2(0.04,0.03),radians(45.));
    p = prevP;
    p.x+=time*0.05;
    p.x+=0.02;
    p.x = mod(p.x,0.04)-0.02;
    p.x+=0.02;
    p.x-=0.015;
    p*=Rot(radians(-90.));
    float d2 = Tri(p,vec2(0.04,0.03),radians(45.));
    d = max(-d2,d);
    
    p = prevP;
    d = max(abs(p.x)-0.06,d);
    float a = radians(-45.);
    p.x+=0.02;
    p.y=abs(p.y);
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    
    return d;
}

float y2kLine(vec2 p){
    vec2 prevP = p;
    
    p*=3.;
    p.x-=time*0.3;
    p.x = mod(p.x,2.2)-1.1;
    p.x-=0.45;
    p.x+=1.;
    float d = y2kItem5(p);
    p.x-=0.65;
    float d2 = y2kItem0(p);
    d = min(d,d2);
    p.x-=0.22;
    
    d2 = char0(p);
    d2 = charMask(p,d2);
    d = min(d,d2);
    p.x-=0.22;
    d2 = drawFont(p,int(mod(time*5.+3.,10.0)));
    d = min(d,d2);
    p.x-=0.22;
    d2 = drawFont(p,int(mod(time*6.+4.,10.0)));
    d = min(d,d2);
    p.x-=0.23;
    d2 = y2kItem7(p);
    d = min(d,d2);
    
    return d;
}

float y2kFractal(vec2 p){
    vec2 prevP = p;
    float d = 10.;
    for(float i = 0.; i<3.; i++){
        p*=Rot(radians(i*30.0+sin(i)*20.));
        p = abs(p)-0.2;
        p.y+=0.05;
        float d2 = y2kLine(p);
        d = min(d,d2);
    }
    
    p = prevP;
    d = max(abs(p.y)-0.42,d);
    
    return d;
}

float drawGraphic(vec2 p){
    vec2 prevP = p;
    float d = y2kFractal(p);
    p.y+=0.45;
    p.y*=-1.;
    float d2 = y2kItem6(p,1.);
    d = min(d,d2);
    p = prevP;
    p.y-=0.45;
    d2 = y2kItem6(p,-1.);
    d = min(d,d2);
    
    p = prevP;
    p.x=abs(p.x)-0.35;
    p*=1.8;
    d2 = y2kItem1(p);
    d = min(d,d2);
    
    p = prevP;
    p.x=abs(p.x)-0.72;
    p*=1.8;
    d2 = y2kItem0(p);
    d = min(d,d2);    
    
    p = prevP;
    p.y=abs(p.y)-0.31;
    p*=1.2;
    d2 = y2kItem2(p);
    d = min(d,d2);
    p.x=abs(p.x)-0.15;
    p*=2.5;
    d2 = y2kItem4(p);
    d = min(d,d2);
    
    p = prevP;
    p.x=abs(p.x)-0.58;
    p.y = abs(p.y)-0.3;
    p*=1.5;
    d2 = y2kItem3(p);
    d = min(d,d2);
    
    p = prevP;
    p.x=abs(p.x)-0.47;
    p.y = abs(p.y)-0.25;
    p*=Rot(radians(45.));
    p*=3.;
    d2 = y2kItem4(p);
    d = min(d,d2);
        
    p = prevP;
    p.x=abs(p.x)-0.69;
    p.y = abs(p.y)-0.37;
    p*=3.;
    d2 = y2kItem4(p);
    d = min(d,d2);
    
    p = prevP;
    p.x=abs(p.x)-0.23;
    d2 = y2kItem8(p);
    d = min(d,d2);
    
    p = prevP;
    d = max(abs(p.x)-0.842,d);
    return d;
}

float getRotAnimationValue(){
    float frame = mod(time,15.0);
    float time = frame;
    float val = 0.;
    float duration = 1.2;
    if(frame>=1. && frame<4.){
        time = getTime(time-1.,duration);
        val = cubicInOut(time)*90.;
    } else if(frame>=4. && frame<7.){
        time = getTime(time-4.,duration);
        val = 90.+cubicInOut(time)*90.;
    } else if(frame>=7. && frame<10.){
        time = getTime(time-7.,duration);
        val = 180.+cubicInOut(time)*90.;
    } else if(frame>=10. ){
        time = getTime(time-10.,duration);
        val = 270.+cubicInOut(time)*90.;
    }
    return val;
}

float getGlitchAnimationValue(){
    float frame = mod(time,15.0);
    float time = frame;
    float val = 0.;
    float duration = 1.6;
    if(frame>=1. && frame<4.){
        time = getTime(time-1.,duration);
        val = 1.0-cubicInOut(time)*1.0;
    } else if(frame>=4. && frame<7.){
        time = getTime(time-4.,duration);
        val = 1.0-cubicInOut(time)*1.0;
    } else if(frame>=7. && frame<10.){
        time = getTime(time-7.,duration);
        val = 1.0-cubicInOut(time)*1.0;
    } else if(frame>=10. ){
        time = getTime(time-10.,duration);
        val = 1.0-cubicInOut(time)*1.0;
    }
    return val;
}

vec3 boxAnim(vec3 p){
    float val = getRotAnimationValue();
    p.xz *= Rot(radians(val));
    
    return p;
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    
    p = boxAnim(p);
    float d = sdBox(p,vec3(0.211,0.12,0.211));
    
    return vec2(d,0);
}

vec2 RayMarch(vec3 ro, vec3 rd, float side, int stepnum) {
    vec2 dO = vec2(0.0);
    
    for(int i=0; i<stepnum; i++) {
        vec3 p = ro + rd*dO.x;
        vec2 dS = GetDist(p);
        dO.x += dS.x*side;
        dO.y = dS.y;
        
        if(dO.x>MAX_DIST || abs(dS.x)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    col = vec3(0.0);
    p = boxAnim(p);
    vec2 uv = p.xy;
    vec2 prevUV = uv;
    
    if(p.z>=0.){
        // back
        uv.x*=-1.;
        float d = drawGraphic(uv*4.);
        col = mix(col,vec3(1.),S(d,0.0));
    } else {
        // front
        float d = drawGraphic(uv*4.);
        col = mix(col,vec3(1.),S(d,0.0));
    }
    
    uv = p.yz;
    
    if(p.x>=0.){
        // right
        uv.y*=-1.;
        uv*=Rot(radians(90.));
        float d = drawGraphic(uv*4.);
        col = mix(col,vec3(1.),S(d,0.0));   
    } else {
        // left
        uv*=Rot(radians(90.));
        float d = drawGraphic(uv*4.);
        col = mix(col,vec3(1.),S(d,0.0)); 
    }
        
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec2 m =  mouse*resolution.xy.xy/resolution.xy;
    
    vec3 ro = vec3(0, 0, -0.45);
    
    /* // for debug
    if(mouse*resolution.xy.z>0.){
        ro.yz *= Rot(m.y*3.14+1.);
        ro.y = max(-0.9,ro.y);
        ro.xz *= Rot(-m.x*6.2831);
    }
    */
    
    vec3 rd = R(uv, ro, vec3(0,0.0,0), 1.0);
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
    }
    
    // gamma correction
    col = pow( col, vec3(0.9545) );   
    
    glFragColor = vec4(sqrt(col),1.0);
}
