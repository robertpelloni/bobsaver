#version 420

// original https://www.shadertoy.com/view/WlXBD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//     As they say in the movies - RUN!!!!
//     pjk | 08/12-17/2020
//    Height map ray marching
//  Added some heat distortion, random
//  lava balls and fake motion! 
//
//////////////////////////////////////////

#define SCALE .44
#define MHEIGHT 5.0
#define SHEIGHT 1.

#define MAX_DIST     75.
#define PI          3.1415926
#define R             resolution
#define M             mouse*resolution.xy
#define T             time
#define S             smoothstep
#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))
#define hash2(a, b) fract(sin(a*1.2764745 + b*.9560333 + 3.) * 14958.5453)

vec3 hitPoint;

// second hash
float hash(vec2 p) {
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}

float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// mouse*resolution.xy pos function
vec3 get_mouse( vec3 ro ) {
    float x = 0.0; //M.xy==vec2(0) ? 0. : -(M.y / R.y * 1. - .5) * PI;
    float y = 0.0; //M.xy==vec2(0) ? 0. : (M.x / R.x * 2. - 1.) * PI;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}
// cheap hight map
float height_map(vec2 p) {
    float height = noise(p * SCALE) * MHEIGHT;
    height = floor(height / SHEIGHT) * SHEIGHT;
    return height;
}
//@iq smooth union
float su( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

vec2 map (in vec3 pos) {
    vec3 q = pos;
    vec3 p = pos+vec3(0.,1.,time*6.85);
    vec2 res = vec2(100.,-1.);
    float sz = 8.;
    float hlf = sz/2.;
    
    vec3 qid = floor((q+hlf)/sz);
    q = vec3(
        mod(q.x+hlf,sz)-hlf,
        q.y,
        mod(q.z+hlf,sz)-hlf
        );

    // ground
    float height = height_map(p.xz) * SCALE;
    float d = (p.y-height);
    d = 1.+p.y - height;
    hitPoint = p;

    // rnd bouncy phases based on hash
    float hsx = hash2(qid.x,qid.z);
    hsx*=6.37;
    float sw = -7.+pow(hsx+hsx*sin(hsx*25.+T*.75),1.);
    float zw = .2*sin(hsx-T*2.10);
    // balls
    float bs = length(q-vec3(sw*.1,sw,zw))-2.75;
    // merge balls and land
    bs = su(bs,d,2.25);
    if(bs<res.x) res = vec2(bs/1.65,height+q.y);
    
    return res;
}

vec3 get_normal(in vec3 p, float t) {
    float e = 0.001*t;

    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec2 ray_march( in vec3 ro, in vec3 rd, int maxstep ) {
    float t = .0;
    float m = 0.;
    for( int i=0; i<maxstep; i++ ) {
        vec2 d = map(ro + rd * t);
        m = d.y;
        if(d.x<.0001*t||t>MAX_DIST) break;
        t += d.x*.5;
    }
    return vec2(t,m);
}

vec3 get_hue(float rnd) {
    return mix(vec3(.25,.3,.1),vec3(.5,.4,.1),rnd*2.);
}

// ACES tone mapping from HDR to LDR
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x) {
    float a = 2.51,
          b = 0.03,
          c = 2.43,
          d = 0.59,
          e = 0.14;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0, 1.0);
}

void main(void) {
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    float mt = mod(T*.03,2.);
    float zoom = mt<1.? -10.75 : 9.75;
    vec3 ro = vec3(5.65*sin(T*.25),9.-4.+4.*sin(T*.18),zoom),
         lp = vec3(0.,.4,.0);
    
    // sligth heat distortion at the bottom of the screen
    U = mix(U, U+(sin(U*45.)*.0045),1.-U.y*1.15);
    
    // uncomment to look around
    //ro = get_mouse(ro);
    vec3 cf = normalize(lp-ro),
          cp = vec3(0.,1.,0.),
          cr = normalize(cross(cp, cf)),
          cu = normalize(cross(cf, cr)),
          c = ro + cf * .75,
          i = c + U.x * cr + U.y * cu,
          rd = i-ro;

    vec3 C = vec3(0.);
    vec3 fC = vec3(.25,.3,.1);
    
    // sky clouds using same height map
    float clouds = .0 - max(rd.y,0.0)*0.5; //@iq trick
    vec2 sv = 1.5*rd.xz/rd.y;
    clouds += 0.1*(-1.0+2.0*smoothstep(-0.1,0.1,height_map(sv*2.)));
    vec3 sky = mix( vec3(clouds), fC, exp(-10.0*max(rd.y,0.0)) ) * fC; 

    // trace 
    vec2 ray = ray_march(ro,rd,256);
    float t = ray.x;
    float m = ray.y;

    if(t<MAX_DIST) {
        vec3 p = ro + t * rd,
             n = get_normal(p, t),
             h = get_hue(m);

        C += h * (ray.x*.025);
        C = mix( C, fC, 1.-exp(-.000025*t*t*t));
    } else {
       C = mix( C, fC, 1.-exp(-.000025*t*t*t));
       C += sky;
    }
    C = ACESFilm(C);
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
