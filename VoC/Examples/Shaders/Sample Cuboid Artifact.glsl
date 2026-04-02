#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/7djXRm

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Cuboid Artifact" by Tater. https://shadertoy.com/view/Nd2SRw
// 2021-05-02 10:25:29

#define STEPS 256.0
#define MDIST 250.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pmod(p, x) (mod(p,x)-0.5*(x))
float glow = 0.0;

//Geometry by Tater
//----------------------------------------------------------------

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

vec2 map(vec3 p){
    vec3 po2 = p;
    
    p.xz*=rot(time*0.8);
    p.xy*=rot(time*0.4);
    vec3 po = p;
    float t = time*0.7;
    
    t = timeRemap(t*1.3, 0., 2.3, 0.1);
    
    
    for(float i = 0.0; i< 9.0; i++){
        p = abs(p)-2.0*i*(vec3(0.35*asin(sin(t*0.15)),0.2*asin(sin(t*0.22)),0.3*asin(sin(t*0.38))));
        p.xz*=rot(pi/2.0);
        mo(p.xy);//credit to FMS_CAT for this technique, I still have no idea how he makes it look so good
        mo(p.zy);
    }
    
    //Inner Cubes
    p = pmod(p,2.2);
    vec2 a = vec2(box(p,vec3(0.5)),1.0);
    a.x = abs(a.x)-0.2;
    a.x = abs(a.x)-0.1;
    //Inner Inner glowy Cubes
    vec2 b = vec2(box(p,vec3(0.45)),2.0);
    glow+=0.01/(0.01+b.x*b.x);
    a = (a.x<b.x)?a:b;
    
    p = po;
    p.xy*=rot(pi/4.0);
    
    //Boundry Cut Cube
    vec3 cube = vec3(4,4,4)*vec3(1.2+0.5*sin(t),1.2+0.5*cos(t),1.2+0.5*sin(t));
    a.x = max(box(p,cube),a.x);
    //Outer Frame
    b= vec2(frame(p,cube+0.15,0.45),3.0);
    a = (a.x<b.x)?a:b;
    
    //Repeating Poles
    po2.y-=time*20.0;
    po2=mod(po2,80.0)-40.0;
    b.x = length(po2.xz)-2.0;
    b.x = min(b.x,length(po2.zy)-2.0);
    b.x = min(b.x,length(po2.xy)-2.0);
    b.y=4.0;
    a = (a.x<b.x)?a:b;
    
    return a;
}

//----------------------------------------------------------

#define ZERO (min(frames,0))
vec3 norm(vec3 p){
    
#if 0    
    vec2 e= vec2(0.01,0);

    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
#else    
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*0.001).x;
    }
    return normalize(n);
#endif  
}

//Lighting & modified tracing by Drake (me)
//----------------------------------------------------------------------------
vec3 tr(vec3 ro, vec3 rd)
{
    vec3 p = ro;
    float shad = 0.0;
    vec2 d = vec2(0);
    
    for(float i = 0.0; i < STEPS; i++){
        vec2 s = map(p);
        d.x += s.x*0.8;d.y=s.y;
        p = ro+rd*d.x;
        if(abs(s.x)<0.001||i==STEPS-1.0 ){
            shad = i/STEPS;
            break;
        }
        if(d.x>MDIST){ break;d.x=MDIST;d.y=0.;};
    }
    return vec3(d.x,d.y,shad);
}

vec3 lit(vec3 p, vec3 h, vec3 rd, vec3 al, vec3 n)
{
    vec3 fo = vec3(sin(time/10.)*0.5+0.5,cos(time/5.)*0.5+0.5,sin(time/5.)*0.5+0.5) * 0.1;
    vec3 col = fo;
    vec3 sss = vec3(0.5)*smoothstep(0.,1.,map(p+-rd*0.2).x/0.2);
    float fom = clamp(h.x/MDIST,0.0,1.0);
    float ffom =fom;
    float diffs = dot(n, -rd);
    float diff = max(diffs,0.);
    float fres = pow(1. - abs(diffs),4.);
    float spec = pow(max(dot(reflect(-rd,n),rd),0.2),20.)*2.;

    //this is a little bit wacky but works
    if(h.y==4.){spec = 0.;fres=0.;ffom=0.;diff=0.;}
    
    //Definitely not using SSS as intended, but hey, it looks good!
    col = mix(al * (fres + spec + diff/14.), diff * sss - h.z, ffom);
    col = mix(col,fo,pow(fom,3.));
    return col*3.;
}

//-------------------------------------------------------------------

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    vec3 al = vec3(0);
    //maybe a bit overkill to have a full camera 
    vec3 ro = vec3(0,2,-20);
    ro.xz*=rot(time*0.2);
    vec3 lk = vec3(0,0,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = f+uv.x*r+uv.y*cross(f,r);
    
    vec3 d = tr(ro,rd);
    vec3 p = ro+rd*d.x;

    if(d.y==1.0) al = vec3(0.945,0.027,0.027);
    if(d.y==2.0) al = vec3(0.741,0.059,1.000);
    if(d.y==3.0) al = vec3(0.000,0.000,0.000);
    if(d.y==4.0) al = vec3(0.839,0.812,0.780);
    
    //More lighting bits
    vec2 e = vec2(0.01,0);
    vec3 n = norm(p);
    vec3 od = d;
    vec3 op = p;
    col = lit(p,d,rd,al,n);    
    vec3 refld = reflect(rd,n);
    d = tr(p + n*0.01,refld);
    p = p+refld*d.x;
    n = norm(p);
    vec3 refl = lit(p,d,rd,al,n);
    if(d.y<4.&&d.y>0.&&od.y>0.&&od.y<4.) col = mix(col,refl,0.5);
    if(d.y>0.&&od.y<3.&&d.y<3.)col+=glow*0.03*vec3(0.741,0.059,1.000);    
    //----------------

       
    col = pow(col,vec3(0.75));//Gamma correction
    glFragColor = vec4(col,1.0);
}
