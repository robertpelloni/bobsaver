#version 420

// original https://www.shadertoy.com/view/7t23RW

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
          ___                       ___           ___     
         /\__\          ___        /\  \         /\  \    
        /::|  |        /\  \      /::\  \       /::\  \   
       /:|:|  |        \:\  \    /:/\:\  \     /:/\:\  \  
      /:/|:|  |__      /::\__\  /:/  \:\  \   /::\~\:\  \ 
     /:/ |:| /\__\  __/:/\/__/ /:/__/ \:\__\ /:/\:\ \:\__\
     \/__|:|/:/  / /\/:/  /    \:\  \  \/__/ \:\~\:\ \/__/
         |:/:/  /  \::/__/      \:\  \        \:\ \:\__\  
         |::/  /    \:\__\       \:\  \        \:\ \/__/  
         /:/  /      \/__/        \:\__\        \:\__\    
         \/__/                     \/__/         \/__/    

    
    More typography and letter construction
    6/12/21 @byt3_m3chanic 
*/

#define R   resolution
#define M   mouse*resolution.xy
#define T   time
#define PI  3.14159265359
#define PI2 6.28318530718

#define MIN_DIST .001
#define MAX_DIST 90.

float hash21 (in vec2 p) {return fract(sin(dot(p.xy,vec2(12.9898,78.233)))*43758.5453123);}

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

void getMouse(inout vec3 ro, inout vec3 rd)
{
    //float x = M.xy == vec2(0) ? 0. : -(M.y/R.y * .25 - .125) * PI;
    //float y = M.xy == vec2(0) ? 0. : -(M.x/R.x * .25 - .125) * PI;
    float x=0;
    float y=0;
    if(x<-.25)x=-.25;
    mat2 rx = rot(x+.2);
    mat2 ry = rot(y);
    ro.yz *= rx;
    rd.yz *= rx;
    ro.xz *= ry;
    rd.xz *= ry;
}

float vmax(vec3 p) {return max(max(p.x,p.y),p.z);  }
float box(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}
//@iq
float box(vec3 p, vec3 b, in vec4 r )
{   r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec3 d = abs(p) - b+vec3(r.x,0,0);
    return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}
float box( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float box( in vec2 p, in vec2 b, in vec4 r )
{
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}
mat2 r58;
// Letters from 2D to 3D extruded SDF's
float getN(vec2 uv)
{
    vec2 nv = uv-vec2(.0, .0);
    nv.yx*=r58;
    float letn = box(vec2(abs(uv.x)-.175,uv.y),vec2(.05,.3));
    letn = min(box(nv,vec2(.32,.05)),letn);
    return letn;
}
float getI(vec2 uv)
{
    uv.y=abs(uv.y);
    float leti = box(uv,vec2(.05,.3));
    leti = min(box(uv-vec2(.0, .25),vec2(.20,.05)),leti);
    return leti;
}
float getC(vec2 uv)
{
    float letc = box(uv-vec2(.05,0),vec2(.2,.25),vec4(0,0,.2,.2));
    letc=abs(letc)-.05;
    letc=max(letc,-box(uv-vec2(.65 , .0),vec2(.5,.5)));
    return letc;
}
float getE(vec2 uv)
{
    uv.y=abs(uv.y);
    float lete = box(uv-vec2(.0, .0),vec2(.05,.3));
    lete = min(box(uv-vec2(.1, .0),vec2(.10,.05)),lete);
    lete = min(box(uv-vec2(.125, .25),vec2(.15,.05)),lete);
    return lete;
}
//@iq
float opx(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

vec3 hitPoint,hit;

vec2 map (vec3 p) {
    vec2 res = vec2(100.,-1.);
    
    vec3 q = p;
    float pr = 1.;
    float pt = 1.;
    float oft;
    for(int i=0;i<4;i++)
    {

        oft = .35+.35*sin(float(i)*(1.25+.25*sin(T*.4))+T*.75);
        oft-=.25;
        float loutline,tz;
        if(i==0) {
        vec3 tmq = p+vec3(.8,-oft,0);
            tmq.yz*=rot(.2*sin(oft+T));
            tmq.zx*=rot(.2*sin(oft-T));
            tz=tmq.z;
            loutline=getN(tmq.xy);
            loutline=abs(loutline)-.015;
        }
        if(i==1) { 
            vec3 tmq = p+vec3(.25,-oft,0);
            tmq.xz*=rot(.2*sin(oft+T));
            tmq.xy*=rot(.2*sin(oft+T));
            tz=tmq.z;
            loutline=getI(tmq.xy); 
            loutline=abs(loutline)-.015;
        }
        if(i==2) {
            vec3 tmq = p-vec3(.3,oft,0);
            tmq.yz*=rot(.2*sin(oft+T));
            tz=tmq.z;
            loutline=getC(tmq.xy);
            loutline=abs(loutline)-.015;
        }
        if(i==3) {
            vec3 tmq = p-vec3(.7,oft,0);
            tmq.yz*=rot(.2*sin(oft+T));
            tmq.zx*=rot(.2*sin(oft-T));
            tz=tmq.z;
            loutline=getE(tmq.xy);
            loutline=abs(loutline)-.015;
        }

        pr = min(opx(loutline,tz,.125),pr);
    
    }
  
    if(pr<res.x){
        res = vec2(pr,2.);
        hit=p;
    } 
    vec3 nq=q-vec3(.25-(oft*.35),.5-(oft*.5),-1.15);
    nq.xz*=rot(.4*sin(oft));
    float smile = length(nq)-.75;
    if(smile<res.x) {
        hit=nq;
        res = vec2(smile,5.);
    }
    
    float wall = q.y+4.;
    float gnd = min(q.z+8.025,wall);
    if(gnd<res.x) {
        hit=vec3(1.-q.x,q.yz);
        res = vec2(gnd,4.);
    }
    return res;
}

vec2 marcher(vec3 ro, vec3 rd, int steps)
{
    float d = 0.;
    float m = 0.;
    vec3 p;
    for(int i=0;i<steps;i++)
    {
        p = ro + rd * d;
        vec2 ray = map(p);
        if(abs(ray.x)<MIN_DIST*d||d>MAX_DIST)break;
        d += i<32?ray.x*.75:ray.x;
        m  = ray.y;
    } 
    return vec2(d,m);
}

// Tetrahedron technique @Shane
vec3 normal(vec3 p, float t)
{
    const vec2 h = vec2(1.,-1.)*.5773;
    vec3 n = vec3(0);
    vec3[4] e4 = vec3[4](h.xyy, h.yyx, h.yxy, h.xxx);
    
    for(int i = min(0, frames); i<4; i++){
        n += e4[i]*map(p + e4[i]*t*MIN_DIST).x;
            if(n.x>1e8) break; // Fake non-existing conditional break.
    }
    return normalize(n);
}

//iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last, inout float d) {

    vec3 C = vec3(0);
    vec2 ray = marcher(ro,rd,164);
    
    hitPoint = hit;
    d = ray.x;
    float m = ray.y;
    float alpha = 0.;
    if(d<MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        
        vec3 lpos =  vec3(-1,3.5,3);
        vec3 l = normalize(lpos-p);

        vec3 h = vec3(.5);

        float diff = clamp(dot(n,l),0.,1.);
        float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.);
        fresnel = mix(.01, .7, fresnel);

        float shdw = 1.0;
        
        for( float t=.01; t < 12.; )
        {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 24.*h/t);
            t += h * .95;
            if( shdw<MIN_DIST || t>32. ) break;
        }
        diff = mix(diff,diff*shdw,.7);
        
        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.5 * pow(max(dot(view, ret), 0.), (m==2.||m==4.)?24.:64.);

        if(m==2.) {
            h = hsv2rgb(vec3(hitPoint.x*.15,1.,.5));
            C+=spec+(h*diff);
            C=mix(C,C+hsv2rgb(vec3(fresnel,1.,.5)),fresnel);
            ref = h-fresnel;
        }

        if(m==3.) {
            h = vec3(1.);
            h=mix(h,hsv2rgb(vec3(hitPoint.x*.15,1.,.5)),fresnel);
            C+=spec+(h*diff);
            
            ref = h-fresnel;
        }
        
        if(m==4.) {
            vec3 fl = hsv2rgb(vec3(.1*T+hitPoint.x*.013,1.,.5));
            hitPoint.x-=T*1.15;
            hitPoint.x+=.75*sin(p.x*0.83+T*1.15);
            vec3 f = fract(hitPoint*.25)-.5;
            h = (f.x*f.y*f.z>0.) ? fl:vec3(0.902,0.976,0.973);
            C+=spec+((h*diff)*.4);
            ref = vec3(1)*fresnel;
        }
     
        if(m==5.) {
            vec2 uv = hitPoint.xy*vec2(1.5,1.);
            vec2 vuv = hitPoint.xy;
            uv.x=abs(uv.x);
            h = vec3(1.000,0.867,0.000);
            float eye = length(uv-vec2(.3,.35))-.0125;
            eye=smoothstep(.081,.08,eye);
            
            float whites= length(uv-vec2(.3,.325))-.04;
            float lits = length(uv-vec2(.3,.335))-.05;
            whites=smoothstep(.11,.1,whites);
            lits=smoothstep(.11,.1,lits);
            
            float smile = length(vuv.xy-vec2(0,.05))-.325;
            float scut = smile;
            float tcut = length(vuv.xy-vec2(0,.275))-.6;
            smile = max(smile, -tcut);
            smile= smoothstep(.11,.1,smile);

            float teeth = length(vuv.xy-vec2(0,.125))-.3;
            teeth = max(teeth, -tcut);
            teeth= smoothstep(.11,.1,teeth);
            
            float tng = length(vuv.xy+vec2(0,.525))-.1;
            tng = max(tng, scut);
            tng= smoothstep(.11,.1,tng);
            h=mix(h,vec3(.05),lits);
            h=mix(h,vec3(.85),whites);
            h=mix(h,vec3(.05),eye+smile);
            h=mix(h,vec3(.85),teeth);
            h=mix(h,vec3(0.992,0.506,0.506),tng);
            
            C+=spec+(h*diff);
            ref = vec3(fresnel);
        }
        
        ro = p+n*MIN_DIST;
        rd = reflect(rd,n);
    } 
    
    return vec4(C,alpha);
}

void main(void)
{   
    r58 = rot(58.*PI/180.); 
    
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,.25,1.6);
    vec3 rd = normalize(vec3(uv,-1));

    getMouse(ro,rd);
    vec3 C = vec3(0);
    vec3 ref=vec3(0), fil=vec3(1);
    float d =0.;
    float numBounces = 3.;
    for(float i=0.; i<numBounces; i++) {
        vec4 pass = render(ro, rd, ref, i==numBounces-1., d);
        C += pass.rgb*fil;
        fil*=ref;
    }
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1.0);
}

//end
