#version 420

// original https://www.shadertoy.com/view/tsycR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define PI          3.1415926
#define PI2         6.2831853

#define MINDIST     .001
#define MAXDIST     100.

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

/**
    ▪   ▐ ▄ ▄ •▄ ▄▄▄▄▄      ▄▄▄▄· ▄▄▄ .▄▄▄  
    ██ •█▌▐██▌▄▌▪•██  ▪     ▐█ ▀█▪▀▄.▀·▀▄ █·
    ▐█·▐█▐▐▌▐▀▀▄· ▐█.▪ ▄█▀▄ ▐█▀▀█▄▐▀▀▪▄▐▀▀▄ 
    ▐█▌██▐█▌▐█.█▌ ▐█▌·▐█▌.▐▌██▄▪▐█▐█▄▄▌▐█•█▌
    ▀▀▀▀▀ █▪·▀  ▀ ▀▀▀  ▀█▄▀▪·▀▀▀▀  ▀▀▀ .▀  ▀

    8 | Teeth

    Limiting myself to one or so hour and mostly
    from scratch except for some #defines and 
    helper functions. 

*/

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }
float hash31(vec3 p){  return fract(sin(dot(p, vec3(12.989, 78.233, 57.263)))*43758.5453); }

vec3 getMouse(vec3 ro) {
    float x = 0.0; //M.xy == vec2(0) ? .0 : -(M.y/R.y * .25 - .125) * PI;
    float y = 0.0; //M.xy == vec2(0) ? .0 :  (M.x/R.x * .5 - .25) * PI;

    ro.zy *=r2(x);
    ro.xz *=r2(y);
    return ro;   
}
//@iq extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

float sdBox( in vec2 p, in vec2 b, in vec4 r ){
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

vec3 id;
vec3 hp;
float size = 5.;
float speed = 5.;
vec2 map(vec3 p) {
    vec2 res = vec2(100.,-1.);
    
    float id=floor((p.z+5.)/10.);
    float hs = hash21(vec2(id,0.));
    float sw = .25+.25*sin(id+T*17.85);
    p.z-=T*speed;

    float d2 = p.y + .85;
    if(d2<res.x) res = vec2(d2,3.);
    p.z=mod(p.z+5.,10.)-5.;
    
    float c1 = max(length(p.xz)-1.75,-(length(p.xz)-1.65));
    float sc = opExtrusion(c1, p.y+.75, 1.25);
    float st = opExtrusion(c1, p.y-20.75, 18.25);
    sc=min(st,sc);
    if(sc<res.x) res = vec2(sc,2.);
    
    
    float c2 = length(p.xz)-1.55;
    float sf = opExtrusion(c2, p.y+.35+sw, 1.25);
    float sq = opExtrusion(c2, p.y-3.35-sw, 1.25);
    sf=min(sq,sf);
    if(sf<res.x) res = vec2(sf,2.);
    //@Shane
    p.xz*=r2(T*.5);
    // size of sphere
    const float size = 2.25;
    // amount of cells
    const float aNum = 12.;
    // circle radius
    const float rdx = .25;
    float a = atan(p.z, p.x);
    // Partitioning the angle into "aNum" cells.
    float ia = floor(a/PI2*aNum);
    ia = (ia + .5)/aNum*PI2;

    // Converting the radial centers to their positions.
    p.xz *= r2(ia);
    p.x -= rdx + size;

    p.xz *=r2(90.*PI/180.);
    
    float t = sdBox(p.xy-vec2(0,2.01 + sw),vec2(.4,.5),vec4(.45,.2,.45,.2));
    float sp = opExtrusion(t, p.z-1., .05);
    if(sp<res.x) res = vec2(sp,1.);

     
    float tl = sdBox(p.xy-vec2(0,1.-sw),vec2(.4,.5),vec4(.2,.45,.2,.45));
    float sd = opExtrusion(tl, p.z-1., .05);
    if(sd<res.x) res = vec2(sd,1.);

    return res;
}

vec2 marcher(vec3 ro, vec3 rd, float sg,  int maxstep){
    float d =  .0,
           m = -1.;
        int i = 0;
        for(i=0;i<maxstep;i++){
            vec3 p = ro + rd * d;
            vec2 t = map(p);
            if(abs(t.x)<d*MINDIST||d>MAXDIST)break;
            d += t.x*.75;
            m  = t.y;
        }
    return vec2(d,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t){
    float e = t*MINDIST;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e).x + 
                      h.yyx*map( p + h.yyx*e).x + 
                      h.yxy*map( p + h.yxy*e).x + 
                      h.xxx*map( p + h.xxx*e).x );
}

//camera setup
vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 f=normalize(lp-ro),//camera forward
         r=normalize(cross(vec3(0,1,0),f)),//camera right
         u=normalize(cross(f,r)),//camera up
         c=ro+f*.85,//zoom
         i=c+uv.x*r+uv.y*u,//screen coords
         rd=i-ro;//ray direction
    return rd;
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l), .1 , .9);
    
    float shadow = marcher(p + n * MINDIST, l, 0., 128).x;
    if(shadow < length(p -  lpos)) dif *= .3;
 
    return dif; 
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.16/5.; 
        float d = map(p + n*hr).x;
        occ += (hr - d)*sca;
        sca *= .7;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 FC = vec3(.02);
vec3 shp;

vec3 getStripes(vec2 uv){
    uv.y -= tan(radians(45.)) * uv.x;
    float sd = mod(floor(uv.y * 2.5), 2.);
    vec3 background = (sd<1.) ? vec3(1.) : vec3(0.);
    return background;
}

vec3 getColor(float m, vec3 p) {
    vec3 h = vec3(.5);
    if(m == 1.) h = vec3(2.1);
    if(m == 2.) h = vec3(1.,.5,.54);
       if(m == 3.) h = getStripes(p.xz-vec2(0,T*speed));
    return h;
}

void main(void) {
    // precal for 

    // pixel screen coordinates
    vec2 uv = (gl_FragCoord.xy - R.xy*0.5)/R.y;
    vec3 C = vec3(0.);

    vec3 lp = vec3(0.,.75,0.);
    vec3 ro = vec3(0.,1.5,5.25);

    ro = getMouse(ro);
    vec3 rd = camera(lp,ro,uv);
    
    vec2 t = marcher(ro,rd, 1., 256);
    shp = hp;
    float d = t.x,
          m = t.y;
    vec3 h;
    // if visible 
    if(d<MAXDIST){
        // step next point
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p,d);

        vec3 lpos  = vec3(5. ,2., -2.3); 
         vec3 lpos2 = vec3(0. ,1.4 , 4.3); 
        float dif = getDiff(p,n,lpos)*.25;
              dif+= getDiff(p,n,lpos2)*.15;
          float ao = calcAO(p, n);
        vec3 h = getColor(m,p);

        C += dif*h*ao;
        // bounce 
        if(m==3. || m==2.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p+n*.05,rr,0., 128);
            shp = hp;
            if(tr.x<MAXDIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                dif = getDiff(p,n,lpos)*.25;
                dif+= getDiff(p,n,lpos2)*.15;
                h = getColor(tr.y,p);

                C += (dif*h);
                C = mix( C, FC, 1.-exp(-0.000025*tr.x*tr.x*tr.x));
            }  
        }
    } 

    C = mix( C, FC, 1.-exp(-0.00025*t.x*t.x*t.x));
  
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
