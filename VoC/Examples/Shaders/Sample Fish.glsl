#version 420

// original https://www.shadertoy.com/view/3s3cDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define S            smoothstep
#define PI          3.1415926
#define PI2         6.2831853
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

/**
    ▪   ▐ ▄ ▄ •▄ ▄▄▄▄▄      ▄▄▄▄· ▄▄▄ .▄▄▄  
    ██ •█▌▐██▌▄▌▪•██  ▪     ▐█ ▀█▪▀▄.▀·▀▄ █·
    ▐█·▐█▐▐▌▐▀▀▄· ▐█.▪ ▄█▀▄ ▐█▀▀█▄▐▀▀▪▄▐▀▀▄ 
    ▐█▌██▐█▌▐█.█▌ ▐█▌·▐█▌.▐▌██▄▪▐█▐█▄▄▌▐█•█▌
    ▀▀▀▀▀ █▪·▀  ▀ ▀▀▀  ▀█▄▀▪·▀▀▀▀  ▀▀▀ .▀  ▀

    1 | fish

    Limiting myself to one or so hour and mostly
    from scratch except for some #defines and 
    helper functions. 

    notes*
    I can't model - so stuck with this abstract
    approach. Fishy!

*/

#define min_dist    .001
#define max_dist    50.

// @iq 
// https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 getHue(float t){ 
    vec3 c = vec3(.15, .17, .8),
         d = vec3(.675,.25, .5),
         a = vec3(.45),
         b = vec3(.15);
    
    return a + b*cos( PI2*(c*t+d) ); 
}
// @iq
float sdTri( vec3 p, vec2 h ){
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

vec2 fish(vec3 p, float t) {
    vec2 res = vec2(1e5,0.);
    vec3 q = p + vec3(0);

    float d = sdTri(q.yxz-vec3(0,.25,0),vec2(.5,.015));
    if(d<res.x) res = vec2(d,1.);
    
    float n = length(q)-.25;
    if(n<res.x) res = vec2(n,2.);
    
    vec3 e = vec3(q.xy,abs(q.z));
    float k = length(e-vec3(.4,.125,.025))-.05;
    if(k<res.x) res = vec2(k,3.);
    
    q.xz*=r2(.35*sin(t+T*2.4));
    float f = sdTri(q.yxz-vec3(.0,-.5,0),vec2(.25,.015));
    if(f<res.x) res = vec2(f,1.);
    
    return res; 
}

vec2 qid;
vec2 map(vec3 p){
    vec2 res = vec2(1e5,0.);
    vec3 q = p + vec3(0);
    q.x -=T * .5;
    q.y += .5 * sin(q.x*.5+T*.75);
    vec2 id = vec2(
        floor((q.x - 1.)/2.),
        floor((q.z - 3.)/6.)
        );
    q.z = mod(q.z+3.,6.)-3.;
    q.x = mod(q.x+1.,2.)-1.;
    vec2 d = fish(q, id.x+id.y);
    if(d.x<res.x) {
        res = d;
        qid=id;
    }
    p.y -= .5 * sin(p.x*1.5+T*.5) + .5 * cos(p.z*.75+T*.4);
    float f= p.y+2.;
    if(f<res.x) res = vec2(f,4.);
 
    return res;
}

vec2 marcher(vec3 ro, vec3 rd, int maxsteps) {
    float d = 0.;
    float m = 0.;
    //vec3  m = vec3(0.);
    for(int i = 0;i<maxsteps;i++){
        vec2 t = map(ro+rd*d);
        if(abs(t.x)<min_dist*d||d>max_dist) break;
        d += t.x * .75;
        m  = t.y;
    }
    return vec2(d,m);
}

//@iq https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t){
    float e = .0002 *t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),.01 , 1.);
    float shadow = marcher(p + n * .008, l, 98).x;
    if(shadow < length(p -  lpos)) dif *= .2;
    return dif;
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.09/5.; 
        float d = map(p + n*hr ).x;
        occ += (hr - d)*sca;
        sca *= .9;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 cf = normalize(lp-ro),
         cr = normalize(cross(vec3(0,1,0),cf)),
         cu = normalize(cross(cf,cr)),
          c = ro + cf * .75,
          i = c + uv.x * cr + uv.y * cu,
         rd = i - ro;
    return rd;
}

vec2 sid;
vec3 getColor(float m, vec3 p) {
    vec3 h = vec3(.6);
    if(m == 4.) h = vec3(.13,.17,.195); 
    if(m == 3.) h = vec3(1.13); 
    if(m == 1.) h = getHue(sid.x+sid.y);
    return h;
}

void main(void) {
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy.xy-R.xy)/max(R.x,R.y);
    vec3 C = vec3(0),
        FC = vec3(.23,.27,.295);

    vec3 lp = vec3(0,0,0),
         ro = vec3(.75, -.25,2.5);
         ro.xz *= r2(.15*sin(T*.1));
    
    vec3 rd = camera(lp,ro,uv);

    vec2 t = marcher(ro,rd,128);
    sid = qid;
    if(t.x<max_dist){
    
        vec3 p= ro+rd*t.x;
        vec3 n = getNormal(p,t.x);
        vec3 lpos = vec3(.5,.5,2.35);
        float diff = getDiff(p, n, lpos);
        float ao = calcAO(p, n);
    
           vec3 h = getColor(t.y, p);
        C += h * diff * ao;
        
        if(t.y==2.){
            vec3 rr=reflect(rd,n);
            vec2 tr=marcher(p,rr,128);
            
            if(tr.x<max_dist){
                
                p= ro+rd*tr.x;
                n = getNormal(p,tr.x);
                diff = getDiff(p, n, lpos);
                ao = calcAO(p, n);
                h = getColor(tr.y, p);
                if(tr.y==2.) h = FC;
                C += h * diff * ao;    
            } 
        }
    }

    C = mix( C, FC, 1.-exp(-.00065*t.x*t.x*t.x));
        
    // for alignment - dev
    //if(uv.x>0. && uv.x<.001 || uv.y>0. && uv.y<.002) C += vec3(.2,.5,1.);

    glFragColor = vec4(C,1.0);
}
