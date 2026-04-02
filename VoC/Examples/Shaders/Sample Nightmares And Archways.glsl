#version 420

// original https://www.shadertoy.com/view/ttBBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    Haunted Archways | pjk
    Motion Camera & Timing experiments
    Endless drifting with a pully based
    camera motion/tracking system. Feels
    very amusment park / haunted house.

*/

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define S            smoothstep
#define PI          3.1415926
#define PI2         6.2831853

#define MINDIST     .001
#define MAXDIST     115.
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

// Helper functions
// http://mercury.sexy/hg_sdf/

#define PI          3.1415926
#define PI2         6.2831853
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
// Sign function that doesn't return 0
float sgn(float x) {
    return (x<0.)?-1.:1.;
}
vec2 sgn(vec2 v) {
    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}

// Maximum/minumum elements of a vector
float vmax(vec2 v) {
    return max(v.x, v.y);
}
float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

// Repeat space along one axis.
float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}
// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
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

// Modified to have angle passed in for post rotation
vec2 pMirrorOctant (inout vec2 p, vec2 dist, float r) {
    vec2 s = sgn(p);
    pMirror(p.x, dist.x);
    pMirror(p.y, dist.y);
    p*=r2(r);
    if (p.y > p.x)
        p.xy = p.yx;
    return s;
}
// The "Chamfer" flavour makes a 45-degree chamfered edge (the diagonal of a square of size <r>):
float fOpUnionChamfer(float a, float b, float r) {
    return min(min(a, b), (a - r + b)*sqrt(0.5));
}
// Intersection has to deal with what is normally the inside of the resulting object
// when using union, which we normally don't care about too much. Thus, intersection
// implementations sometimes differ from union implementations.
float fOpIntersectionChamfer(float a, float b, float r) {
    return max(max(a, b), (a + r + b)*sqrt(0.5));
}
// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float fOpUnionStairs(float a, float b, float r, float n) {
    float s = r/n;
    float u = b-r;
    return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2. * s)) - s)));
}
float fOpDifferenceStairs(float a, float b, float r, float n) {
    return -fOpUnionStairs(-a, b, r, n);
}

// Cylinder standing upright on the xz plane
float fCyl(vec3 p, float r, float height) {
    float d = length(p.xy) - r;
    d = max(d, abs(p.z) - height);
    return d;
}
// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}
// Same as above, but in two dimensions (an endless box)
float fBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}
float fCone(vec3 p, float radius, float height) {
    vec2 q = vec2(length(p.xz), p.y);
    vec2 tip = q - vec2(0., height);
    vec2 mantleDir = normalize(vec2(height, radius));
    float mantle = dot(tip, mantleDir);
    float d = max(mantle, -q.y);
    float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
    // distance to tip
    if ((q.y > height) && (projected < 0.)) {
        d = max(d, length(tip));
    }
    // distance to base ring
    if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
        d = max(d, length(q - vec2(radius, 0.)));
    }
    return d;
}
// Book Of Shaders - timing functions
float linearstep(float begin, float end, float t) {
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

float easeOutCubic(float t) {
    return (t = t - 1.0) * t * t + 1.0;
}

float easeInCubic(float t) {
    return t * t * t;
}

// --------- 2d noise & clouds -----
vec3 noised( in vec2 x ){
    vec2 f = fract(x);
    vec2 u = f*f*(3.0-2.0*f);
    ivec2 p = ivec2(floor(x));
    float a = 0.0;//texelFetch( iChannel1, (p+ivec2(0,0))&255, 0 ).x;
    float b = 0.0;//texelFetch( iChannel1, (p+ivec2(1,0))&255, 0 ).x;
    float c = 0.0;//texelFetch( iChannel1, (p+ivec2(0,1))&255, 0 ).x;
    float d = 0.0;//texelFetch( iChannel1, (p+ivec2(1,1))&255, 0 ).x;
    return vec3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
                6.0*f*(1.0-f)*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}
float cloudy( vec2 p, int freq ) {    
    float h = -1.,w = 1.6, m = 0.35;
    for (int i = 0; i < freq; i++) {
        h += w * noised((p * m)).x;
        w *= 0.5;
        m *= 2.0;
    }
    return h;
}

// --------- global vars -----------

float zoom = 20.5;
float glow = 0.;
float speed = 7.;
float oct = 3.;
float ga1,ga2,ga3,ga4,ga5,ga6;

// --------- map functions ---------
vec2 map(vec3 p, float sol) {
    vec2 res = vec2(MAXDIST,-1.);

    float maptime = T;
    vec3 q = p-vec3(0,0, maptime * speed );

    q.y -= sin((q.z*.2)+maptime*3.25);
    float f = q.y-.05;
    if(f<res.x) res = vec2(f,1.);
    
    float xd= pMod1(q.z,25.);
    float yd= pMod1(q.x,25.);
    vec3 qd = q;

    float dzl = pMod1(qd.z,25.);

    pMirrorOctant(q.zx,vec2(5., 4.475),(ga4-ga2*.75)+(ga6-ga5*.75)); 
    vec3 rr = q;
      q.x = - abs(q.x)+2.;
    float id= pMod1(q.z,2.);
   
    float wall = fBox(q,vec3(.25,5.,5.));

    float roof = fBox(q-vec3(2.75,4.5,0.),vec3(3.,.1,5.));
    vec3 q2 = q;
    q2.z = abs(q2.z)+.6;

    float window = fBox(q2-vec3(0,.99,0),vec3(.4,1.,1.));
    window=min(fCyl(q2.zyx-vec3(0,1.99,0.),1.,.4),window);

    
    wall = min(fBox(q2-vec3(-.3,2.5,1.6),vec3(.1,2.5,.05)),wall);

    float lits = length(q2-vec3(-.6,4.25,1.6))-.05;

    if (lits<res.x && sol==1.) {
        res = vec2(lits,6.);
        glow += .0025/(.000005+lits*lits);
    }
    rr.xz-=.25+.25*sin(rr.y*2.1);
    float cone = fCone(rr+vec3(3.5,0,.0),.75-ga1,9.);
    if(cone<res.x) res = vec2(cone,4.);
        
    float tip = fBox(q2-vec3(0,5.,0),vec3(.08,.25,.8));
    tip=min(fCyl(q2.zyx-vec3(0,4.65,0.),1.3,.08),tip);
    roof = min(tip,roof);
    
    float mainwall = fOpDifferenceStairs(wall,window,.25,3.);
    float building = fOpUnionStairs(mainwall,roof,.25,3.);

    if(building<res.x) res = vec2(building,2.);
    
    return res;
}

// ---------------------------------

vec2 marcher(vec3 ro, vec3 rd, int maxstep, float sol){
    float d =  .0,
           m = -1.;
        int i = 0;
        for(i=0;i<maxstep;i++){
            vec3 p = ro + rd * d;
            vec2 t = map(p, sol);
            if(abs(t.x)<MINDIST)break;
            d += t.x*.85;
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
    return normalize( h.xyy*map( p + h.xyy*e ,0.).x + 
                      h.yyx*map( p + h.yyx*e ,0.).x + 
                      h.yxy*map( p + h.yxy*e ,0.).x + 
                      h.xxx*map( p + h.xxx*e ,0.).x );
}

//camera setup
vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 f=normalize(lp-ro),//camera forward
         r=normalize(cross(vec3(0,1,0),f)),//camera right
         u=normalize(cross(f,r)),//camera up
         c=ro+f*.8,//zoom
         i=c+uv.x*r+uv.y*u,//screen coords
        rd=i-ro;//ray direction
    return rd;
}

vec3 getCheck(vec3 p) {
    float sc = .5;
    vec2 f=fract(p.xz*sc)-0.5,h=fract(p.xy*sc)-0.5;
    return f.x*f.y>0.? vec3(.8) : vec3(.5,.6,.55);  
}

vec3 getStripes(vec2 uv){
    uv.y -= tan(radians(-45.)) * uv.x;
    float sd = mod(floor(uv.y * 2.5), 2.);
    vec3 background = (sd<1.) ? vec3(1.) : vec3(0.);
    return background;
}

vec3 stp3D( in vec3 p, in vec3 n ){
    n *= length(n);
    n = max((abs(n) - 0.2) * 7., 0.001);
    n /= (n.x + n.y + n.z );  
    p = (getStripes(p.yz)*n.x +
         getStripes(p.zx)*n.y +
         getStripes(p.xy)*n.z).xyz;
    return p*p;
}

vec3 getColor(float m, vec3 p, vec3 n) {
    vec3 h = vec3(.5);
    if(m==1.) h = getCheck(p-vec3(0,0,T*speed));
    if(m==2.) h = vec3(.5,.6,.55);
    if(m==4.) h = stp3D(p-vec3(0,0,T*speed),n);
    return h;
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),0. , 1.);
    float shadow = marcher(p + n * .001 * 2., l, 128,0.).x;
    if(shadow < length(p -  lpos)) dif *= .3;
    return dif;
}

//https://www.shadertoy.com/view/MsVSWt
vec3 getMoon(vec2 uv){
    vec2 ms = vec2(-(( ga2 - ga3 )*.75),.5-(ga1*.1));
    float moon = 1.0 - distance(uv,ms);
    moon = clamp(moon,0.0,1.0);
    moon = pow(moon,50.0);
    moon *= 100.0;
    moon = clamp(moon,0.0,1.0);
    return vec3(vec3(.65,.8,.7) * moon);
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ){ need changing to glFragColor and gl_FragCoord.xy
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;
    // Normalized pixel coordinates -1 to 1
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 C = vec3(0.);//default color
    vec3 FC = vec3(.02);//fade color

    // Look Point and Ray order

    vec3 lp = vec3(0.,1.5,0.);
    vec3 ro = vec3(0.,2.,zoom);

    float tm = mod(T*.35, 11.);
    // move x steps in rotation
    float t1 = linearstep(0.0, 1.0, tm);
    float t2 = linearstep(3.0, 4.0, tm);
    float a1 = easeInCubic(t1);
    float a2 = easeOutCubic(t2);
    
    float t3 = linearstep(4.0, 5.0, tm);
    float a4 = linearstep(6.0, 7.0, tm);
    float a3 = easeInCubic(t3);
    
    float a5 = linearstep(7.0, 8.0, tm);
    float t6 = linearstep(9.0, 10.0, tm);
    float a6 = easeOutCubic(t6);
    
    ga1 = (a1-a2);
    ga2 = (a3-a4);
    ga3 = (a5-a6);
    ga4 = (a2-a3);
    ga5 = (a4-a5);
    ga6 = (a6-a5);
    ro.zy *=r2(-.3 + ga1 *.31);
    ro.xz *=r2(( ga2 - ga3 )*.75);

    // solve for Ray direction
    vec3 rd = camera(lp,ro,uv);
    
    // trace scene
    vec2 t = marcher(ro,rd,256,1.);
    //vec2 rt = refmarcher(ro,rd,256);
    float d = t.x,
          m = t.y;

    vec3 p;
    
    // sky clouds
    float clouds = .0 - max(rd.y,0.0)*0.5; //@iq trick
    vec2 sv = 1.75*rd.xz/rd.y;
    clouds += 1.45*(-1.0+4.*S(-0.01,0.75,cloudy(sv-vec2(T*.75)*.75,4)));
    vec3 sky = vec3(0.001);
    
    // if visible 
    if(d<MAXDIST){
             p = ro + rd * d;
        vec3 n = getNormal(p,d);

        vec3 lpos  = vec3(2.,11.,-5.),
             lpos2 = vec3(-.5,8.,-9.);
        
        float dif = getDiff(p,n,lpos);
                 dif += getDiff(p,n,lpos2);
        vec3 h = getColor(m,p,n);
        
        C += h*dif;

    } else {
         sky = mix( vec3(clouds), C, exp(-00.10*max(rd.y,0.0)) )+ getMoon(uv); 
    }
    
    C = mix(sky,C ,  exp(-.00012*t.x*t.x*t.x));
    C +=vec3(glow*.2);
    O = vec4(pow(C, vec3(0.4545)),1.0);

    glFragColor = O;
}
