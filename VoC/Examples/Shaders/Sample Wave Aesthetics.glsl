#version 420

// original https://www.shadertoy.com/view/WtsBDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Thick Wavey Lines - Ray Marching
    Kind of like that Joy Division album cover
    Using a 2 pass system for a single axis
    (the x in this case)
    Perlin noise in common tab from @42yeah
*/

#define MAX_DIST    75.
#define PI          3.1415926
#define R           resolution
#define M           mouse*resolution.xy
#define T           time
#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))
#define hue(a) .45 + .42*cos((0.5*a) - vec3(.5,.75,.35));
#define hash(a, b) fract(sin(a*1.2664745 + b*.9560333 + 3.) * 43758.5453)

// https://www.shadertoy.com/view/wsjfRD
// A white noise function.
float rand(vec3 p) {
    return fract(sin(dot(p, vec3(12.345, 67.89, 412.12))) * 42123.45) * 2.0 - 1.0;
}

float perlin(vec3 p) {
    vec3 u = floor(p);
    vec3 v = fract(p);
    vec3 s = smoothstep(0.0, 1.0, v);
    
    float a = rand(u);
    float b = rand(u + vec3(1.0, 0.0, 0.0));
    float c = rand(u + vec3(0.0, 1.0, 0.0));
    float d = rand(u + vec3(1.0, 1.0, 0.0));
    float e = rand(u + vec3(0.0, 0.0, 1.0));
    float f = rand(u + vec3(1.0, 0.0, 1.0));
    float g = rand(u + vec3(0.0, 1.0, 1.0));
    float h = rand(u + vec3(1.0, 1.0, 1.0));
    
    return mix(mix(mix(a, b, s.x), mix(c, d, s.x), s.y),
               mix(mix(e, f, s.x), mix(g, h, s.x), s.y),
               s.z);
}

//@iq
float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.)-.025;
}

float speed = 0.;
vec3 hitPoint, mid;
vec2 map(in vec3 uv) {
    vec2 res = vec2(1000.,0.);
    vec3 q;

    uv.xy += vec2(speed,-.25);

    float size = 1., 
          hlf = size/2.,
          mlf = (hlf/2.)+.065,
          dbl = size*2.,
          id;
    
    float thick = .51;
    
    // two pass method - every other stripe
    // alter to see passes - picked this trick 
    // up from @Shane
    for(int i = 0; i<2; i++){
        // shift center off
        float cnt = i<1 ? size : size * 2.;
        // set local coordinates.
        q = vec3(uv.x-cnt,uv.yz);
        // local group id
        id = floor(q.x/dbl) + .5;
        // new local position.
        q.x -= (id)*dbl;
        // correct positional individual row ID.
        float qf = (id)*dbl + cnt;
        // line thickness
        thick = mlf+(mlf-.15)*sin(qf*.05);
        
        // make wave and apply
        float nz = perlin(vec3(qf*.15-T*.25,.3,q.z*.15)) * 3.15;
        q.y += nz+nz*sin(q.z*.75);
        
        //float d = sdBox(q-vec3(0.,2.,0.),vec3(thick,.05,65.));
        float d = sdBox(abs(q)-vec3(0.,5.75,0.),vec3(thick,.25,65.));
        
        if(d<res.x) {
            res = vec2(d,3.);
            hitPoint = q;
            mid = vec3(qf,nz,float(i));
        }
    }
    res.x = res.x/1.4;
    return res;
}

vec3 get_normal(in vec3 p, in float t) {
    t *= .0002;
    vec2 eps = vec2(t, 0.0);
    vec3 n = vec3(
        map(p+eps.xyy).x - map(p-eps.xyy).x,
        map(p+eps.yxy).x - map(p-eps.yxy).x,
        map(p+eps.yyx).x - map(p-eps.yyx).x);
    return normalize(n);
}

vec2 ray_march( in vec3 ro, in vec3 rd, int maxstep ) {
    float t = .0001,
          m = .0;
    for( int i=0; i<maxstep; i++ ) {
        vec2 d = map(ro + rd * t);
        m = d.y;
        if(abs(d.x)<.0001*t||t>MAX_DIST) break;
        t += d.x*.5;
    }
    return vec2(t,m);
}

float get_diff(vec3 p, vec3 lpos, vec3 n){
    vec3 light = normalize(lpos - p);
    float diff = dot(n, light),
        shadow = ray_march(p + n * .1 * 2., n, 32).x;
    if(shadow<length(lpos-p)) diff *= .35;
    return clamp(diff, 0., 1.);
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

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0.,1.2,-5.5),
         lp = vec3(0.,0.,.0);
    
    vec3 C = vec3(0.); 
    vec3 fC= mix(vec3(.001),vec3(.5,.75,.65),U.y+.5*1.15);

    speed = T*7.25;
    float angle = 0;//M.xy==vec2(0.) ? -.2 : (M.x / R.x * 2. - 1.) * PI;
    ro.xz *=r2(-angle);
    
    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .95,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec2 ray = ray_march(ro,rd,200);
    float t = ray.x;
    float m = ray.y;

    if(t<MAX_DIST) {
        vec3 p = ro + t * rd,
             n = get_normal(p, t),
             h = hue(mid.x*.1+mid.y*1.2+mid.z);
        float diff = get_diff(p,vec3(0.5,0.5,-.5),n);
        C += h * vec3(diff);
        
    } else {
      C += fC;
    }
    
    C = mix( C, fC, 1.-exp(-.000025*t*t*t));
    C = ACESFilm(C);
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}

void mainVR( out vec4 O, in vec2 F, in vec3 fragRayOri, in vec3 fragRayDir ) {
 vec2 U = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = fragRayOri,
         rd = fragRayDir;
    
    vec3 C = vec3(0.); 
    vec3 fC= mix(vec3(.001),vec3(.5,.75,.65),U.y+.5*1.15);
    speed = T*2.25;

    vec2 ray = ray_march(ro,rd,200);
    float t = ray.x;
    float m = ray.y;

    if(t<MAX_DIST) {
        vec3 p = ro + t * rd,
             n = get_normal(p, t),
             h = hue(mid.z);
        float diff = get_diff(p,vec3(0.5,0.5,-.5),n);
        C += h * vec3(diff);
        
    } else {
      C += fC;
    }
    
    C = mix( C, fC, 1.-exp(-.000025*t*t*t));
    C = ACESFilm(C);
    O = vec4(pow(C, vec3(0.4545)),1.0);
}
