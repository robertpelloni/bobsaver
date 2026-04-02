#version 420

// original https://www.shadertoy.com/view/3ddfRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Infinity Box Loop
    fake zoom loop by using one map
    to make 4 copies of the room
    scale/zoom by fract(time)

    @pjkarlik

*/

// anyway.. enjoy..

#define R            resolution
#define T            time
#define M            mouse*resolution.xy

#define PI2            6.28318530718
#define PI            3.14159265358

#define MAX_DIST     25.
#define MIN_DIST    .001
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

// Book Of Shaders - timing functions
float linearstep(float begin, float end, float t) {
return clamp((t - begin) / (end - begin), 0.0, 1.0);}
float easeOutCubic(float t) {return (t = t - 1.0) * t * t + 1.0;}
float easeInCubic(float t) {return t * t * t;}
// standard hash
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }
//@iq https://iquilezles.org/www/articles/palettes
vec3 hue(float t){ 
    vec3 c = vec3(.85, .75, .5),
         d = vec3(.75, .5, .25),
         a = vec3(.65),
         b = vec3(.45);
    return a + b*cos(T*.1+PI*(c*t+d) ); 
}
//@iq sdf
float sdBox( vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

//@pjkarlik
void getMouse( inout vec3 p ) {
    float x = 0.0;// == vec2(0) ? 0. : -(M.y/R.y * .5 - .25) * PI;
    float y = 0.0;// == vec2(0) ? 0. : (M.x/R.x * 1.5 - .75) * PI;
    p.zy *=r2(x);
    p.xz *=r2(y);   
}

// global vars and constants
vec3 shp;
vec2 sid,sip,bid;
float ga1,ga2,t1,t2,sc1,sc2,ps1,ps2;
mat2 r90,r180,r270;

vec2 makeRoom(vec3 p) {
    vec2 res = vec2(1000.,0.);
    
    float box = sdBox(p,vec3(3.,3.,1.));
    //stuff//

    float sphere = min(
        length(p-vec3(-1.95,0,1.5))-.5,
        length(p-vec3(1.95,-2.,2.75))-.25
    );
    sphere = min(
        length(length(p-vec3(-1.95,-.5,-2.25)))-.75,
        sphere
    );
    if(sphere<res.x) res = vec2(sphere,5.);
    
    float boxes = min(
        sdBox(p-vec3(1.95,0,1.25),vec3(.35)),
        sdBox(p-vec3(1.95,-2.,-1.5),vec3(.5))
    );
    if(boxes<res.x) res = vec2(boxes,3.);

    float fm = max(
         sdBox(p-vec3(.25,-1.3,.35),vec3(.175,.175,.175)),
        -sdBox(p-vec3(.25,-1.3,.35),vec3(.145,.195,.145))
    );
    fm=max(fm,-sdBox(p-vec3(.25,-1.3,.35),vec3(.195,.145,.145)));
    if(fm<res.x) res = vec2(fm,4.);
    //stuff//
    
    float cut = sdBox(p-vec3(0,0.,.0),vec3(1.5,1.5,2.));
    //cut = min(sdBox(p-vec3(0,-1.,0.),vec3(.9,1.,.9)),cut);
    box = max( box,-cut );
    if(box<res.x) res = vec2(box,2.);
    
    return res;
}

vec2 map(vec3 p){
    vec2 res = vec2(1000.,0.);
    vec3 p2 = p;

    // base movment
    p2.zy *= r90;
    p2 *= sc1;
    
    vec3 p3 = p2;
    p3.zy *= r270;
    p3 *= .3345;
    
    vec3 p4 = p3;
    p4.zy *= r270;
    p4 *= .3345;
    // so make 3 boxes - and move them 
    // one full scale and 1/4 rotation
    // fract time so it repeats.

    
    vec2 box1 = makeRoom(p2);
    if(box1.x<res.x) res = box1;
 
    vec2 box4 = makeRoom(p3);
    if(box4.x<res.x) res = box4;
    
    vec2 box0 = makeRoom(p4);
    if(box0.x<res.x) res = box0;
    
    // move step 1
    p2.zy *= r180;
    p2 *= 3.;

    vec2 box2 = makeRoom(p2);
    if(box2.x<res.x) res = vec2(box2.x*.65,box2.y);
    
    // move step 1
    p2.zy *= r180;
    p2 *= 3.;

    vec2 box3 = makeRoom(p2);
    if(box3.x<res.x) res = vec2(box3.x*.45,box3.y);

    
    return res;
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 getNormal(vec3 p, float t){
    float e = MIN_DIST *t;
    vec2 h = vec2(1.,-1.)*.5773502;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec2 marcher(vec3 ro, vec3 rd, int maxsteps) {
    float d = 0.;
    float m = -1.;
    for(int i=0;i<maxsteps;i++){
        vec2 t = map(ro + rd * d);
        if(abs(t.x)<d*MIN_DIST||d>MAX_DIST) break;
        d += i<64 ? i<32 ? t.x*.125 : t.x*.25 : t.x *.65;
        m  = t.y;
    }
    return vec2(d,m);
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),.01 , 1.);
   // float shadow = marcher(p + n * .01, l, 128).x;
  //  if(shadow < length(p -  lpos)) dif *= .25;
    return dif;
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.16/8.; 
        float d = map(p + n* hr).x;
        occ += (hr - d)*sca;
        sca *= .8;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 cf = normalize(lp - ro),
         cr = normalize(cross(vec3(0,1,0),cf)),
         cu = normalize(cross(cf,cr)),
         c  = ro + cf *.85,
         i  = c + uv.x * cr + uv.y * cu,
         rd = i - ro;
    return rd;
}

vec3 thp;
vec2 tip;
float thsh;

vec3 getColor(float m) {
    vec3 h=vec3(.75);
    if(m==2.) h = hue((13.25)*PI);
    if(m==3.) h = hue((76.25)*PI);
    if(m==4.) h = hue((63.25)*PI);
    if(m==5.) h = hue((123.25)*PI);
    return h;
}

void main(void) {
    // precal and timing
    float tm = fract(T*.32);
    t1 = linearstep(0., 1., tm);

    sc1 = 1.5-(t1);
    ps1 = 1.3*t1;
    float art = (90.*(1.-t1));
    r90 =  r2(art*PI/180.);
    r180 = r2(90.*PI/180.);
    r270 = r2(270.*PI/180.);
    // Normalized coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    vec3 C = vec3(0.),
        FC = hue((13.25)*PI);
    
    vec3 lp = vec3(0.,0.,0.),
         ro = vec3(1.25,1.2,2.25);
    //getMouse(ro);    

    vec3 rd = camera(lp,ro,uv);
    vec2 t = marcher(ro,rd, 223);

    if(t.x<MAX_DIST){
        vec3 p = ro + rd * t.x;
        vec3 n = getNormal(p, t.x);
        vec3 lpos = vec3(.0,1.5,2.25);
        float diff = getDiff(p, n, lpos);
        float ao = calcAO(p, n);
          vec3 h = getColor(t.y);
        
        C+= diff * ao * h;
        
        // right now reflectiosn kill things
        // so use at own risk

        if(t.y!=2.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p,rr, 223);

            tip = sip;
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                diff = getDiff(p,n,lpos);
                h = min(getColor(tr.y),FC);
                C+=abs(diff * h)*.5;
            }
        }
    
    }
 
    C = mix( C, FC, 1.-exp(-.0005*t.x*t.x*t.x));

    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
