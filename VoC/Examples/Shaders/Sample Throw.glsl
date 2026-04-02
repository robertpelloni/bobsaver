#version 420

// original https://www.shadertoy.com/view/wdVyzW

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
#define MAXDIST     125.

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

/**
    ▪   ▐ ▄ ▄ •▄ ▄▄▄▄▄      ▄▄▄▄· ▄▄▄ .▄▄▄  
    ██ •█▌▐██▌▄▌▪•██  ▪     ▐█ ▀█▪▀▄.▀·▀▄ █·
    ▐█·▐█▐▐▌▐▀▀▄· ▐█.▪ ▄█▀▄ ▐█▀▀█▄▐▀▀▪▄▐▀▀▄ 
    ▐█▌██▐█▌▐█.█▌ ▐█▌·▐█▌.▐▌██▄▪▐█▐█▄▄▌▐█•█▌
    ▀▀▀▀▀ █▪·▀  ▀ ▀▀▀  ▀█▄▀▪·▀▀▀▀  ▀▀▀ .▀  ▀

    9 | Throw

    Limiting myself to one or so hour and mostly
    from scratch except for some #defines and 
    helper functions. 

*/

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

vec3 getMouse(vec3 ro) {
    float x = -0.7; //0.0; //M.xy == vec2(0) ? -.7 : -(M.y/R.y * .5 - .15) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 1. :  (M.x/R.x * 1. - .5) * PI;

    ro.zy *=r2(x);
    ro.xz *=r2(y);
    return ro;   
}
//@iq
float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdCyl( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdCap( vec3 p, float h, float r ){
  p.x -= clamp( p.x, 0.0, h );
  return length( p ) - r;
}
//globals//
float glow;
vec3 id;
vec3 hp;

vec2 map(vec3 p, float sg){
    vec2 res = vec2(100.,-1.);
    p.z-=T*8.2;
    
    vec3 q = p;
    
    float sz = 3.,
          hf = sz/2.;
   
    q.x+=+hf;
    
    vec3 qid =floor((q+hf)/sz);
         q = vec3(
            mod(q.x+hf,sz)-hf,
            q.y,
            mod(q.z+hf,sz)-hf
         );
    
    float d = p.y+1.;
    hp = p;
    id = qid;
    d = max(d,-sdCyl(q-vec3(.0, -3.5,.0),.75,3.5));
    if(d<res.x) res = vec2(d,1.);
    
    float hsh = hash21(qid.xz);

    float sy = 1.5*sin(qid.x*.75+qid.z*1.2+T*5.1);
    q.y -= -1.5+ sy;
    float cy = 3. + 3. * sin(T*.5);
    float cs = 3. + 3. * cos(T*.5);
    vec3 offset = q+ vec3(0,cy,cs);
    d = length(q)-(.75-hsh);

    if(sg==1.) glow += (.00095)/(.000015+d*d);
     if(sg==2.) glow += (.000025)/(.0002+d*d);
    return res;
}

vec2 marcher(vec3 ro, vec3 rd, float sg,  int maxstep){
    float d =  .0,
           m = -1.;
        int i = 0;
        for(i=0;i<maxstep;i++){
            vec3 p = ro + rd * d;
            vec2 t = map(p, sg);
            if(abs(t.x)<d*MINDIST||d>MAXDIST)break;
            d += i>64? t.x * .25 : t.x*.55;
            m  = t.y;
        }
    return vec2(d,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 getNormal(vec3 p, float t){
    float e = t*MINDIST;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e, 0.).x + 
                      h.yyx*map( p + h.yyx*e, 0.).x + 
                      h.yxy*map( p + h.yxy*e, 0.).x + 
                      h.xxx*map( p + h.xxx*e, 0.).x );
}

//camera setup
vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 f=normalize(lp-ro),//camera forward
         r=normalize(cross(vec3(0,1,0),f)),//camera right
         u=normalize(cross(f,r)),//camera up
         c=ro+f*.75,//zoom
         i=c+uv.x*r+uv.y*u,//screen coords
         rd=i-ro;//ray direction
    return rd;
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l), .1 , .9);
    float shadow = marcher(p + n * MINDIST, l, 0., 92).x;
    if(shadow < length(p -  lpos)) dif *= .3;
    return dif; 
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.16/5.; 
        float d = map(p + n*hr, 0.).x;
        occ += (hr - d)*sca;
        sca *= .7;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

//@iqhttps://iquilezles.org/www/articles/palettes/palettes.htm
vec3 getHue(float t){ 
    vec3 c = vec3(.66, .27, .1),
         d = vec3(.25, .25, .95);
    return .35+.35 *cos( PI2*(c*t+d) ); 
}

vec3 FC = vec3(.72);
vec3 shp;

vec3 getCheck(vec3 p){
    float sc = .5;
    vec2 f=fract(p.xz*sc)-0.5,h=fract(p.xy*sc)-0.5;
    float ff = hash21(floor(p.xz))*hash21(floor(p.xy));
    return f.x*f.y*h.y>0.? vec3(.08) : getHue(ff*3.5);
}

vec3 getColor(float m, vec3 p, vec3 id) {
    float hsh = hash21(id.xz);
    vec3 h = .5 + .45*cos(PI2*hsh*.4 + vec3(0, 1, 2));
       if(m == 1.) h = getCheck(p);
    return h;
}

vec3 sid;
void main(void) {
    // precal for 

    // pixel screen coordinates
    vec2 uv = (gl_FragCoord.xy - R.xy*0.5)/R.y;
    vec3 C = vec3(0.);

    vec3 lp = vec3(0.,.5,0.);
    vec3 ro = vec3(0.,.5,3.25);

    ro = getMouse(ro);
    vec3 rd = camera(lp,ro,uv);
    
    vec2 t = marcher(ro,rd, 1., 192);
    shp = hp;
    sid = id;
    float d = t.x,
          m = t.y;
    vec3 h;
    // if visible 
    if(d<MAXDIST){
        // step next point
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p,d);

        vec3 lpos  = vec3(1. ,1.5, 3.3); 
         vec3 lpos2 = vec3(-.2 ,0.5 , 4.3); 
        float dif = getDiff(p,n,lpos)*.25;
              dif+= getDiff(p,n,lpos2)*.15;
          //float ao = calcAO(p, n);
        vec3 h = getColor(m,shp,sid);

        C += dif*h;
        // bounce 
        if(m==1.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p+n*.05,rr,2., 128);
            shp = hp;
            sid = id;
            if(tr.x<MAXDIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                dif = getDiff(p,n,lpos)*.25;
                dif+= getDiff(p,n,lpos2)*.15;
                h = getColor(tr.y,shp,sid);
            
                C += (dif*h);
            }  
        }
    } 

    
    C = mix( C, FC, 1.-exp(-0.000005*t.x*t.x*t.x));
      C += glow*.45; 
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
