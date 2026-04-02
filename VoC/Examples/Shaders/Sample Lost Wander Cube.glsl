#version 420

// original https://www.shadertoy.com/view/Nst3RH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Cuboid Artifact." by Tater. https://shadertoy.com/view/Nd2SRw
// 2021-08-16 22:09:46

#define STEPS 128.0
#define MDIST 200.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pmod(p, x) (mod(p,x)-0.5*(x))
float glow = 0.0;

float box(vec3 p, vec3 s){
    vec3 d = abs(p)-s;
    return max(d.x,max(d.y,d.z));
}

float frame(vec3 p, vec3 s, float e){
    vec2 h = vec2(e,0);
    float a = box(p,s);
    float b = box(p,s*1.01-h.xxy);
    a = max(-b,a);
    b = box(p,s*1.01-h.xyx);
    a = max(-b,a);
    b = box(p,s*1.01-h.yxx);
    a = max(-b,a);
    return a;
}

float timeRemap (float t,float s1, float s2, float c){
    return 0.5*(s2-s1)*(t-asin(cos(t*pi)/sqrt(c*c+1.0))/pi)+s1*t;  
}

void mo(inout vec2 p){
  //p = abs(p)-d;
  if(p.y>p.x) p = p.yx;
}
vec3 kifs;
vec2 map(vec3 p){
    vec3 po2 = p;
    
    p.xz*=rot(time*0.8);
    p.xy*=rot(time*0.4);
    vec3 po = p;
    float t = time*0.7;
    t = timeRemap(t*1.3, 0.0, 2.3, 0.1);

    for(float i = 0.0; i< 9.0; i++){
        p = abs(p)-2.0*i*kifs;
        p.xz*=rot(pi/2.0);
        mo(p.xy);
        mo(p.zy);
        p.x-=sign(p.y)*sin(t);
       
    }
    
    //Inner Cubes
    p = pmod(p,2.2);
    vec2 a = vec2(box(p,vec3(0.5)),1.0);
    a.x = abs(a.x)-0.2;
    a.x = abs(a.x)-0.1;
    vec2 b = vec2(box(p,vec3(0.45)),2.0);
    
    a = (a.x<b.x)?a:b;
    
    p = po;
    p.xy*=rot(pi/4.0);
    
    //Boundry Cut Cube
    vec3 cube = vec3(4,4,4)*vec3(1.2+0.5*sin(t),1.2+0.5*cos(t),1.2+0.5*sin(t));
    a.x = max(box(p,cube),a.x);
    b.x = max(box(p,cube),b.x);
    glow+=0.01/(0.01+b.x*b.x);
    //Outer Frame
    b= vec2(frame(p,cube+0.15,0.45),3.0);
    a = (a.x<b.x)?a:b;
    
    //Repeating Poles
    vec3 po3 = po2;
    po3.xy*=rot(sin(t)*0.9);
    //po3.yz*=rot(sin(t)*0.4);
    po3.zx*=rot(sin(t+0.5)*0.9);
    po3+=sin(t)*3.0;
    
    
    
    po2.y-=time*20.0;
    po2=mod(po2,80.0)-40.0;
    po2.x+=sin(po3.y*0.05+time);
    b.x = length(po2.xz)-2.0-clamp(sin(po3.y*0.5-time*10.0),-0.2,0.2);
    b.x = min(b.x,length(po2.zy)-2.0-clamp(sin(po3.x*0.5),-0.2,0.2));
    b.x = min(b.x,length(po2.xy)-2.0-clamp(sin(po3.z*0.5),-0.2,0.2));
    b.y=4.0;
    a = (a.x<b.x)?a:b;
    
    return a;
}
vec3 norm(vec3 p){
    vec2 e= vec2(0.01,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    vec3 al;
    vec3 ro = vec3(0,2,-20);
    //ro.xz*=rot(time*0.4);
    vec3 lk = vec3(0,0,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = f*1.0+uv.x*r+uv.y*cross(f,r);
    
    vec3 p = ro;
    float dO;
    float shad = 0.0;
    vec2 d;
    float t = time*0.7;
    t = timeRemap(t*1.3, 0.0, 2.3, 0.1);
    kifs = abs(vec3(asin(sin(t*0.15)),0.2*asin(sin(t*0.22)),0.3*asin(sin(t*0.38))));
    for(float i = 0.0; i < STEPS; i++){
        d = map(p);
        dO += d.x*0.75;
        p = ro+rd*dO;
        if(abs(d.x)<0.001||i==STEPS-1.0 ){
            shad = i/STEPS;
            break;
        }
        if(dO>MDIST) break;
    }
    if(d.y==1.0) al = vec3(0.863,0.043,0.020);
    if(d.y==2.0) al = vec3(0.529,0.000,0.722);
    if(d.y==3.0) al = vec3(0.000,0.000,0.000);
    if(d.y==4.0) al = vec3(0.000,0.000,0.000);
    
    vec3 n = norm(p);
    float aor=dO/50.;
    float ao=exp2(-2.*pow(max(0.,1.-map(p+n*aor).x/aor),4.));
    al*=(.5*ao+0.5);
    col = vec3(pow(1.0-shad,2.))*al;
    

    vec3 ld = vec3(1,1,-1);
    vec3 h = normalize(ld-rd);
    float spec = pow(max(dot(reflect(-rd,n),rd),0.3),5.);
    float fres = pow(1. - max(dot(n, -rd),0.), 5.);
    float diff = max(dot(n, ld),0.);
    
    vec3 light = vec3(0.910,0.800,1.000);
    col*=clamp(diff,0.6,1.0)*light;
    if(d.y!=4.0)col+=spec*light*0.25;
    if(d.y!=3.0&&d.y!=4.0)col+=glow*0.105*
    mix(vec3(0.569,0.082,1.000),vec3(0.267,0.082,1.000),sin(length(p)*2.0)*0.5+0.5);
    col = mix(col,vec3(0.318,0.180,0.439)*(1.-length(uv)*0.6),clamp(dO/MDIST,0.0,1.0));
    
    col = pow(col,vec3(0.85));//Gamma correction
    glFragColor = vec4(col,1);
}
