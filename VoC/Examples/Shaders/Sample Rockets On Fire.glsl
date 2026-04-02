#version 420

// original https://www.shadertoy.com/view/tdVyzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    Rockets on Fire

    Was working for inktober but its
    not where I want it - so just posting
    and moving on for now - but was fun
    to mix some things I've played with
    (grid/path/etc)

*/

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define PI          3.1415926
#define PI2         6.2831853

#define MINDIST     .001
#define MAXDIST     75.

#define PI          3.1415926
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
//http://mercury.sexy/hg_sdf/

// Maximum/minumum elements of a vector
float vmax(vec2 v) {    return max(v.x, v.y);                        }
float vmax(vec3 v) {    return max(max(v.x, v.y), v.z);                }

// Sign function that doesn't return 0
vec2 sgn(vec2 v)   {    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);    }

// Repeat space along one axis.
float pMod(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float fBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}
//@iq
float sdCyl( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdCone( vec3 p, vec2 c, float h ){
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}
float sdTriPrism( vec3 p, vec2 h ){
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }
float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash21( i + vec2(0.0,0.0) ), 
                     hash21( i + vec2(1.0,0.0) ), u.x),
                mix( hash21( i + vec2(0.0,1.0) ), 
                     hash21( i + vec2(1.0,1.0) ), u.x), u.y);
}
// cheap hight map
float height_map(vec2 p) {
    float height = noise(p * .34) * 4.;
    height = floor(height / 1.) * 1.5;
    return height;
}

vec3 getMouse(vec3 ro) {
    float x = 0.0; //M.xy == vec2(0) ? 0. : -(M.y/R.y * 1. - .5) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 0. : (M.x/R.x * 2. - 1.) * PI;
    ro.zy *=r2(x);
    ro.xz *=r2(y);
    return ro;   
}

// path functions 
vec2 path(in float z){ 
    vec2 p1 =vec2(2.13*sin(z * .15), 1.74*cos(z * .085));
    vec2 p2 =vec2(2.97*sin(z * .079), 1.23*sin(z * .127));
    return p1 - p2;
}

void fps( inout vec3 pos) {
    if ( pos.x- pos.y<0.) pos.yx = pos.xy;
    if ( pos.x- pos.z<0.) pos.zx = pos.xz;
    if ( pos.y- pos.z<0.) pos.zy = pos.yz;  
}

// globals and stuff
float glow,travelSpeed,uwave;
vec3 hp,iqd;
mat2 r90;

vec2 rocket(vec3 p) {
    p.xz*=r2(T*3.3);
    vec2 res=vec2(1000.,11.);

    float b = sdCyl(p,.25,1.);
    float c =sdCone(p-vec3(0,1.25,0),vec2(.5),.25);

    // Polar Repetion 
    float a = atan(p.z, p.x);
    float aNum = 5.;
    float ia = floor(a/PI2*aNum);
    ia = (ia + .5)/aNum*PI2;
    p.xz *= r2(ia);

    float d = sdTriPrism(p-vec3(.25,-.55,0),vec2(.75,.025));

    if(d<res.x) {
        res = vec2(d,12.);
        hp = p-vec3(0,.27,0);
    }
    if(c<res.x) {
        res = vec2(c,13.);
        hp = p-vec3(0,2.65,0);
    }
    if(b<res.x) {
        res = vec2(b,14.);
        hp = p-vec3(0,2.05,0);
    }

    return res;
}

#define SCALE      .75

vec2 map (in vec3 pos, float sg) {
     vec2 res = vec2(100.,-1.);
    pos.y +=2.75;
     vec2 qath = pos.xy - path(pos.z);
    vec3 q = vec3(qath,pos.z);
    vec3 dq = q;
    vec3 pq = q;
        
    uwave=sin(dq.z*.35);
    float rwave=sin((dq.z+4.26)*.35);
    
    pq.zy*=r2(270.*PI/180.);
    pq -=vec3(0,-4.27+travelSpeed,-5.85);

    vec2 rkt = rocket(pq+vec3(0,0,rwave-.15));
    if(rkt.x<res.x) {
        res =rkt;
    }

    dq.y+=uwave;
    
    vec3 r = dq;
    pMod(r.z,3.);
    
    vec3 rq = vec3(abs(dq.x),dq.y-3.5,dq.z);
    r = vec3(abs(r.x),r.y-3.5,r.z);
    
    float rf = fBox2(dq.xy-vec2(0,3. ),vec2(1.,.05));   
          rf = min( fBox(r-vec3(1.,-2.,0),vec3(.1,1.75,.1)), rf);
    
    if(rf<res.x)  {
       res =vec2(rf,1.);
       hp = q;
    }
    
    
    float rd = fBox2(rq.xy-vec2(.95,0),vec2(.1,.25));
    rd = min(fBox2(rq.xy-vec2(1.25,0),vec2(.5,.1)),rd);
    if(rd<res.x) {
       res =vec2(rd,2.);
       hp = rq;
    }

    
    const vec2 l = vec2(1./SCALE);            // dimension | length to height ratio.
    const vec2 s = l*2.;    
    float dd;
    vec2 p,
         ip,
         id = vec2(0),
         ct = vec2(0);
    const vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5),   vec2(.5, -.5), vec2(-.5));

    for(int i = 0; i<4; i++){                // @Shane
        ct = ps4[i]/2. -  ps4[0]/2.;        // Block center.
        p = q.xz - ct*s;                    // Local coordinates. 
        ip = floor(p/s) + .5;                // Local tile ID. 
        p -= (ip)*s;                         // New local position.           
        vec2 idi = (ip + ct)*s;                // Correct position & tile ID.
        
        float hs = hash21(idi);
        float pt = hs*1.15;    
        
        vec3 sz = vec3(l.x);        
 
        vec3 qz = vec3(p.x,q.y-pt-.5,p.y);        

          float c = length(qz)-(sz.x*.5);

        if(c<res.x) {
            if( idi.x<2. && idi.x>-2.){
                
            }else{
                res = vec2(c/.9, 4.); 
                
                iqd=vec3(idi.x,hs,idi.y);
        
            }  
        }
    }

    // floor
    float f1 = max(q.y,-dd);
    if(f1<res.x)  res =vec2(f1,1.);
    
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
            d += i<64? t.x*.25 : t.x*.75;
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

vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 cf = normalize(lp - ro),
         cr = normalize(cross(vec3(0,1,0),cf)),
         cu = normalize(cross(cf,cr)),
         c  = ro + cf *.85,
         i  = c + uv.x * cr + uv.y * cu,
         rd = i - ro;
    return rd;
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),.1 , 1.);
    float shadow = marcher(p + n * .01, l, 0., 128).x;
    if(shadow < length(p -  lpos)) dif *= .25;
    return dif;
}

//@Shane low cost AO
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

vec3 shp,sid;
//@iq https://iquilezles.org/www/articles/palettes
vec3 getHue(float t){ 
    vec3 c = vec3(.66, .3, .2),
         d = vec3(1.65, .75, .15);
    return .40+.35 *cos( PI2*(c*t+d) ); 
}
vec3 getStripes(vec2 uv){
    uv.y -= tan(radians(45.)) * uv.x;
    float sd = mod(floor(uv.y * 2.5), 2.);
    vec3 background = (sd<1.) ? vec3(1.) : vec3(0.);
    return background;
}

vec3 getWings(vec3 p){
    float sc = 5.;
    vec2 f=fract(p.xz*sc)-0.5,h=fract(p.xy*sc)-0.5;
    float ff = hash21(floor(p.xz))*hash21(floor(p.xy));
    vec3 k = f.x*f.y*h.y>0.? vec3(.0) : vec3(1.);
    vec3 c = p.y<-1.0 && p.y >-1.6 ? k : vec3(1);
    return p.y<-.9 && p.y >-1.0 ? vec3(1,0,0) : c;
}

vec3 getCone(vec3 p){
    vec3 h;
    h = p.y<-2.0 && p.y >-2.6 ? vec3(1,0,0) : vec3(1);
    h = p.y<-2.6 && p.y >-2.7 ? vec3(0,0,0) : h;
    h = p.y<-1.9 && p.y >-2.0 ? vec3(0,0,0) : h;
    return h;
}

vec3 getColor(float m, vec3 hp, vec3 rd) {
    vec3 h = vec3(.75);
    if(m==1.) h = vec3(.75);
    if(m==2.) h = getStripes(hp.xz);
    if(m==4.) h = getHue(hash21(sid.xz));
    if(m==11.)h = vec3(.4);
    if(m==12.)h = getWings(shp);
    if(m==13.)h = vec3(1.,0,0);
    if(m==14.)h = getCone(shp);
    return h;
}

void main(void) {
    // precal 
    travelSpeed = (T * 8.25);
    r90*=r2(90.*PI/180.);
    // pixel screen coordinates
    vec2 uv = (gl_FragCoord.xy - R.xy*0.5)/R.y;
    vec3 C = vec3(0.);
    vec3 FC = vec3(.1,.3,.4);

    float tm = travelSpeed;
    float zoom = .25;

    vec3 lp = vec3(0.,2.,tm);
    vec3 ro = vec3(0.,0.,zoom);
    ro = getMouse(ro);
   
    ro +=lp; 
     lp.xy += path(lp.z);
    ro.xy += path(ro.z);
    if(mod(T*.1,3.)<1.) ro.x += 6.5;

    // solve for Ray direction
    vec3 rd = camera(lp,ro,uv);
    
    vec2 t = marcher(ro,rd, 1., 256);
    //save id val before reflect
    shp=hp;
    sid=iqd;
    float d = t.x,
          m = t.y;
    
    // sky clouds using same height map
    float clouds = .0 - max(rd.y,0.0)*0.5; //@iq trick
    vec2 sv = 1.5*rd.xz/rd.y;
    clouds += 0.1*(-1.0+2.0*smoothstep(-0.1,0.1,height_map(sv*2.)));
    vec3 sky = mix( vec3(clouds), FC, exp(-10.0*max(rd.y,0.0)) ) * FC; 
    
    // if visible 
    if(d<MAXDIST){
        // step next point
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p,d);

        vec3 lpos  = vec3(.0,.0,-.3)+lp; 
             lpos.xy = path(lpos.z);
             lpos.y+=3.25;
             lpos.x+=.75*sin(T*.5);
        float dif = getDiff(p,n,lpos);
          float ao = calcAO(p, n);
        vec3 h = getColor(m,shp,rd);

        C += dif*h*ao;
        C = mix(FC,C ,  exp(-.0001*t.x*t.x*t.x)); 
                
    } else {
        C = mix(FC,C ,  exp(-.0001*t.x*t.x*t.x)); 
         C += sky;    
    }

    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
