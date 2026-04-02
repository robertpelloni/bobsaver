#version 420

// original https://www.shadertoy.com/view/sst3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 140.
#define MDIST 100.
#define pi 3.1415926535
#define pmod(p,x) (mod(p,x)-0.5*(x)) 
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
//#define elon(p,h) (p-clamp(p,-h,h))

//iq palette 
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos( 6.28318*(c*t+d) );
}
//iq segment
float seg(vec2 p, vec2 a, vec2 b){
    vec2 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h);
}
//iq extrude
float ext(vec3 p, float s, float h){
  vec2 b = vec2(s,abs(p.y)-h);
  return min(max(b.x,b.y),0.)+length(max(b,0.));
}
vec2 map(vec3 p){
    float t = time;
    //p.y-=t*8.-20.;
    vec3 po = p;
    vec2 a = vec2(1);
    float spd = 8.0;
    t*=spd;
    float dh = 0.28; //Disk Height

    float lscl = 1.0; //Leading Edge Scale
    float le = -mod(t * lscl,lscl); //Lead Edge
    float tscl = 5.; //Trailing Edge Scale
    float te = tscl - mod(t * tscl,tscl); //Trailing Edge
    float scl = 0.; //Final Scale for later
    float id = 0.;
    float npy = 0.;
    bool mid = false;
    
        //Transitional domain
        if(p.y > le && p.y < te){ 
            npy = mod(p.y-le,tscl);
            scl = mix(tscl,lscl,min(fract(t)*2.0,1.0));
            //Alternative where the transitional domain slows down before stopping on the stack
            //npy = mod(p.y-le,te-le);
            //scl = te-le;
            
            mid = true;
            id = floor(t);
        }
        //The stacked tower
        if(p.y<le){ 
            npy = mod(p.y-le,lscl);
            id = floor((p.y-le)/lscl)+floor(t);
            scl = lscl;
        }
        //The falling part
        if(p.y>te){ 
            npy = mod(p.y-te,tscl);           
            id = floor((p.y-te)/tscl)+floor(t)+1.0; 
            scl = tscl;
        }
        npy-=scl*0.5;
        p.y = npy;
    

    p.xz*=rot(id*0.1);
    vec3 p2 = p;
    
    float off = (sin(id*0.1)*0.5+0.5)*4.0+6.0;
    p2.x = abs(p2.x)-off;
    p2.xz*=rot(pi/4.);
    float c = length(p2.xz)-1.5;
    if(mod(id,7.0)<1.0){
        //if(mod(id,2.0)<1.0) p.xz*=rot(pi/2.);
        c = min(c,seg(p.xz,vec2(off,0),vec2(-off,0))-1.5);
    }
    a.x = min(a.x,ext(p2, c, dh));
    a.x-=0.15;
    
    //The most annoying domain artifact fixing
    if(!mid) a.x = min(a.x,max(-(abs(p.y)-scl*0.65),0.01));
    else {
        a.x = min(a.x,max(-(-po.y+le),0.1));
    }
    
    a.y = id;
    return a;
}
vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0.);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    vec3 ro = vec3(0,15,-35);
    ro.xz*=rot(time*pi/3.0*0.3);
    vec3 lk = vec3(0,-3,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = f*0.9+uv.x*r+uv.y*cross(f,r);
    float dO = 0.;
    vec2 d = vec2(0);
    vec3 p = vec3(0);
    bool hit = false;
    
    for(float i = 0.; i<STEPS; i++){
         p = ro+rd*dO;
         d = map(p);
         dO+=d.x*1.3; //Idk why this doesn't cause artifacts but whatever
         if(abs(d.x)<0.005){
             hit = true;
             break;
         }
         if(dO>MDIST){
             dO=MDIST;
             break;
         }
    }
    vec3 al = vec3(0);
    if(hit){
        vec3 e = vec3(0.5);
        al = pal(d.y*0.5+time*0.1,e,e,e*2.0,vec3(0,0.33,0.66));
        al*=1.5;
        vec3 n = norm(p);
        vec3 ld = normalize(vec3(0.,0.1,1));
        vec3 h = normalize(ld-rd);
        float spec = pow(max(dot(n,h),0.0),5.0);
        float fres = 1.-abs(dot(rd,n))*.98;
        float diff = dot(n, ld)*0.4+0.6;
        col=al*diff+pow(spec,2.0)*0.3*vec3(0.008,0.133,0.078);
        col*=1.2-fres;
    }
    col = sqrt(col);
    col = mix(col,vec3(0.016,0.102,0.204)*(0.7-dot(uv,uv)),pow(min(dO/68.,1.0),3.0));
    glFragColor = vec4(col,1.0);
}
