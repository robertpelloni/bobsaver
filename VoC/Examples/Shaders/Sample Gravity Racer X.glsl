#version 420

// original https://www.shadertoy.com/view/wtSfDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Anti Gravity Racing Tribute | pjk
    My love of Wipeout and trying to learn
    how those demos work / tunnel - pathing

    @Shane https://www.shadertoy.com/view/MlXSWX
    he does a lot of good tunnel shaders / still need
    to work on undistoring things.. I think @gaz has
    good demos on that..

    Click to pan the camera around - basic 
    menger sponge with some mod's
    using tips and tricks from
    http://mercury.sexy/hg_sdf/

*/

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define PI          3.1415926

#define MINDIST     .001
#define MAXDIST     45.

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hash(a, b) fract(sin(a*1.2664745 + b*.9560333 + 3.) * 14958.5453)

#define PI          3.1415926
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
//http://mercury.sexy/hg_sdf/

// Sign function that doesn't return 0
float square (float x)     { return x*x;        }
vec2  square (vec2 x)     { return x*x;        }
vec3  square (vec3 x)     { return x*x;        }
float lengthSqr(vec3 x) { return dot(x, x); }

// Maximum/minumum elements of a vector
float vmax(vec2 v) {    return max(v.x, v.y);                        }
float vmax(vec3 v) {    return max(max(v.x, v.y), v.z);                }
float vmax(vec4 v) {    return max(max(v.x, v.y), max(v.z, v.w));    }
float vmin(vec2 v) {    return min(v.x, v.y);                        }
float vmin(vec3 v) {    return min(min(v.x, v.y), v.z);                }
float vmin(vec4 v) {    return min(min(v.x, v.y), min(v.z, v.w));    }

// Sign function that doesn't return 0
float sgn(float x) {     return (x<0.)?-1.:1.;                            }
vec2 sgn(vec2 v)   {    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);    }

// Repeat space along one axis.
float pMod(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

vec2 pMod(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

vec3 pMod(inout vec3 p, vec3 size) {
    vec3 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5, size) - size*0.5;
    return c;
}

// Repeat around the origin by a fixed angle.
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
    float s = sgn(p);
    p = abs(p)-dist;
    return s;
}

// @pjkarlik Modified to have angle passed in for post rotation
vec2 pMirrorOctant (inout vec2 p, vec2 dist, float r) {
    vec2 s = sgn(p);
    pMirror(p.x, dist.x);
    pMirror(p.y, dist.y);
    p*=r2(r);
    if (p.y > p.x) p.xy = p.yx;
    return s;
}

//@iq of hsv2rgb - updated
vec3 hsv2rgb( float h ) {
    vec3 c = vec3(h,1.,.5);
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}
vec3 getMouse(vec3 ro) {
    float x = 0.0;//M.xy == vec2(0) ? 0. : -(M.y/R.y * 1. - .5) * PI;
    float y = 0.0;//M.xy == vec2(0) ? 0. : (M.x/R.x * 1. - .5) * PI;
    ro.zy *=r2(x);
    ro.xz *=r2(y);
    return ro;   
}

// path functions 
vec2 path(in float z){ 
    vec2 p1 =vec2(2.3*sin(z * .15), 1.4*cos(z * .25));
    vec2 p2 =vec2(1.2*sin(z * .39), 2.1*sin(z * .15));
    return p1 - p2;
}

float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float fBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

vec2 fragtail(vec3 pos, float z) {
    float scale = 3.12;
    float twave = 1.5+1.5*sin(z*.5);
     vec3 cxz = vec3(3.4,2.75,2.+twave);
    float r = length(pos);
    float t = 0.0;
    float ss=.55;
    
    for (int i = 0;i<3;i++) {
        pos=abs(pos);
        
        if ( pos.x- pos.y<0.) pos.yx = pos.xy;
        if ( pos.x- pos.z<0.) pos.zx = pos.xz;
        if ( pos.y- pos.z<0.) pos.zy = pos.yz;
        pos.x=scale * pos.x-cxz.x*(scale-1.);
        pos.y=scale * pos.y-cxz.y*(scale-1.);
        pos.z=scale * pos.z;
        
        if (pos.z>0.5*cxz.z*(scale-1.)) pos.z-=cxz.z*(scale-1.);
        r = fBox2(pos.xy,vec2(scale));

        ss*=1./scale;
    }
    float rl = log2(ss*.255);
    return vec2(r*ss,rl);
}

float glow,iqd,travelSpeed,carWave;
vec3 hp;
mat2 tax,tay;
// float sg = toggle | to record or not change specfic
// values like hitpoint or glow. this prevents it from
// distorting items or textures for extra passes like
// ao or shadow
vec2 map (in vec3 pos, float sg) {
    // map stuff
     vec3 p = pos-vec3(0.,0.,0);
     vec2 res = vec2(100.,-1.);
    float msize = 4.;
    
    // set path(s) vector(s)
     vec2 tun = p.xy - path(p.z);
    vec3 px = vec3(tun+vec2(0.,-.1),pos.z+travelSpeed+carWave);
    vec3 q = vec3(tun,p.z);
    vec3 s = q;
    vec3 r = vec3(abs(q.x),abs(q.y),q.z);

    // mods and vectors
    pModPolar(q.xy,6.);
    pModPolar(s.xy,3.);
    pMod(s.z,msize);
    vec3  qid = pMod(q,vec3(msize));
    float twave = .15+.15*sin(qid.z*.5);
    iqd=qid.z;
    // panels
    float d3 = fBox(s-vec3(.75,0,0),vec3(.001,.3,.75));
    if(d3<res.x) {
        //sg prevents hp from changing for ao
        if(sg>0.) hp = s;
        res = vec2(d3,3.);
    }
    
    // stuff
    vec3 qr = vec3(q.x,abs(q.y),abs(q.z));
    float d6 = fBox(qr-vec3(1.2,.25-twave,1.25),vec3(.05,.075,.45));
    if(d6<res.x) res = vec2(d6,4.);

    // fractal
    vec2 d1 = fragtail(q,qid.z);
    if(d1.x<res.x)  res = d1;

    // beams
    float d4 = length(r.xy-vec2(.52,.33))-.005+.015*sin(q.z*3.-T*3.5);
    if(d4<res.x && sg > 0.) res = vec2(d4,12.);

    // car
    vec3 ax = vec3(abs(px.x),px.yz);
    ax.xy*=tax;
    ax.zy*=tay;
    float d7 = fBox(ax-vec3(0.3,.0,-.5),vec3((fract(px.z-.245)*.4)-.09,.005,.25));
    d7 = min(fBox(px+vec3(0.,.22,.3),vec3((fract(px.z-.25)*.5)-.15,.0175,.15)),d7);
    if(d7<res.x && sg > 0.) res = vec2(d7,5.);
    
    //sg prevents glow from changing for ao
    if(sg>0.){
        glow += .0001/(.000025+d4*d4);
        glow += .000085/(.000025+d7*d7);
    }

     return res;
}

vec2 marcher(vec3 ro, vec3 rd, float sg, int maxstep){
    float d =  .0,
           m = -1.;
        float glowDist = 1e9;
        int i = 0;
        for(i=0;i<maxstep;i++){
            vec3 p = ro + rd * d;
            vec2 t = map(p, sg);
            if(abs(t.x)<d*MINDIST)break;
            d += t.x*.75;
            m  = t.y;
            if(d>MAXDIST)break;
        }
    return vec2(d,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t){
    float e = (MINDIST + .0001) *t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e, 0. ).x + 
                      h.yyx*map( p + h.yyx*e, 0. ).x + 
                      h.yxy*map( p + h.yxy*e, 0. ).x + 
                      h.xxx*map( p + h.xxx*e, 0. ).x );
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

vec3 get_stripes(vec2 uv){
    uv.y -= tan(radians(45.)) * uv.x;
    float sd = mod(floor(uv.y * 2.5), 2.);
    vec3 background = (sd<1.) ? vec3(1.) : vec3(0.);
    return background;
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    return clamp(dot(n,l),0. , 1.);  
}

//@Shane low cost AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.17/5.; 
        // map(pos/dont record hit point)
        float d = map(p + n*hr, 0.).x;
        occ += (hr - d)*sca;
        sca *= .9;
        // Deliberately redundant line 
        // that may or may not stop the 
        // compiler from unrolling.
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;
    // precal for ship
    tax=r2(-45.*PI/180.);
    tay=r2(8.*PI/180.);
    travelSpeed = (T * 2.25);
    carWave = sin(T*.3)+.75;
    //
    // pixel screen coordinates
    vec2 uv = (F.xy - R.xy*0.5)/R.y;
    vec3 C = vec3(0.);//default color
    vec3 FC = vec3(.8);//fade color
    // ray origin / look at point based on path
    float tm = travelSpeed;
    float md = mod(T*.1,2.);
    float zoom = md<1. ? .25 : -.25;
    vec3 lp = vec3(0.,0.,0.-tm);
    vec3 ro = vec3(0.,.01,zoom);
    ro = getMouse(ro);
    ro +=lp; 
     lp.xy += path(lp.z);
    ro.xy += path(ro.z);
    // solve for Ray direction
    vec3 rd = camera(lp,ro,uv);

    // trace scene (ro/rd/record hit point/steps)
    vec2 t = marcher(ro,rd,1.,192);
    float d = t.x,
          m = t.y;
    
    // if visible 
    if(d<45.){
        // step next point
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p,d);

        vec3 lpos  = vec3(.0,0,0)+lp; 
             lpos.xy = path(lpos.z);
        float dif = getDiff(p,n,lpos);
          float ao = calcAO(p, n);
        vec3 h = mix(hsv2rgb(iqd*.025),vec3(.95),get_stripes(normalize(hp.yz)*.28));
        
        if(m==3.) {
            hp.z+=T*.75;
            hp.y=abs(hp.y)-1.5;
            h = get_stripes(hp.yz*4.)*vec3(2.);
        }
        if(m==4.) h= vec3(.8,.7,.0);
        if(m==5.) h= vec3(.75);
        C += h*dif*ao;
    } 
   
    C = mix(FC,C,  exp(-.00045*t.x*t.x*t.x));
    C += glow*.3;   
    O = vec4(pow(C, vec3(0.4545)),1.0);

    glFragColor = O;
}
