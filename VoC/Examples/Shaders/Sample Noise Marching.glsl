#version 420

// original https://www.shadertoy.com/view/WtcGRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///////////////////////////////////////////////////
//
// Raymarching Noise - Experiment
// Based on some 2D tutorials - intro to GLSL Shaders
// 
// Wanted to experiment with taking the 2D lessons
// learned and apply them to my raymarching.
// Noise function @iq 
// https://www.shadertoy.com/view/lsf3WH
// perlin function found online - unknown
///////////////////////////////////////////////////

#define MAX_DIST     85.
#define MIN_DIST     .001
#define MAX_STEPS   205

#define PI          3.1415926
#define PI2         6.2831853

// Noise from @iq - https://www.shadertoy.com/view/Msf3WH
// check and swap with some other noise functions.
vec2 hash2( vec2 p ) {
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise2( in vec2 p ) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
    vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3  n = h*h*h*h*vec3( dot(a,hash2(i+0.0)), dot(b,hash2(i+o)), dot(c,hash2(i+1.0)));
    return dot( n, vec3(70.0) );
}

mat2 r2( float a ) { 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}

vec3 get_mouse( vec3 ro ) {
    float x = 0;
    float y = 0;
    ro.zy *= r2(x);
    ro.xz *= r2(y);
    return ro;
}

vec3 map(in vec3 pos) {
     vec3 res = vec3(1.,-1.,.0);
      vec3 center = vec3(0., -10., 0.);
      vec3 p = pos-center;
    p.x -= time * 2.;
      //p.y -= 4.5 + 4.5 * sin(p.x * .08 + time *.84) + cos(p.z * .08 + time *.75);

      //float timer = time * .05;
    
    // Simple noise function and way easier on processor
    float n = noise2(vec2(p.x * .15,p.z * .15));
    // Perlin Noise with time, processor hungry
      //float n = pnoise(vec3(p.x * .1,p.z * .1,timer),vec3(0.)) * 1.5;

      float ring = 1.25 - fract(4. * n);
      float lerpy = pow(ring, .45) + n;
    
    // now this stuff if just for effect
    lerpy += smoothstep(0., ring, n)*.75;
    float d2 = p.y - lerpy;
    res = vec3(d2,n,1.);
    
    float d1 = length(pos-vec3(0.,7.,0.))-9.5-(lerpy);
    if(d1<res.x) res = vec3(d1,n,2.);
    
      return res;
}

vec3 get_normal(in vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(.01,.0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
    );
    return normalize(n);
}

vec3 ray_march( in vec3 ro, in vec3 rd ) {
    float depth = 0.0;
    float m = -1.;
    float n = 0.;
    vec3 pos = ro;
    for (int i = 0; i<MAX_STEPS;i++) {
        vec3 dist = map(pos);
        if(dist.x<MIN_DIST) break;
        depth += abs(dist.x*.25);
        n = dist.y;
        m = dist.z;
        pos = ro + depth * rd;
           if(depth>MAX_DIST) depth = MAX_DIST;
    }
    return vec3(depth,n,m);
}

float get_diff(vec3 p, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    vec3 n = get_normal(p);
    float dif = clamp(dot(n,l),0. , 1.);
    
    float shadow = ray_march(p + n * MIN_DIST * 2., l).x;
    if(shadow < length(p -  lpos)) dif *= .15;
    return dif;
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 color = vec3(0.);
    vec3 fadeColor = vec3(.1, .3, .8 );
    vec3 ray = ray_march(ro, rd);
    float t;
    float m;
    float n;
    if(ray.x<MAX_DIST) {
        t = ray.x;
        n = ray.y;
        m = ray.z;
        vec3 p = ro + ray.x * rd;
        vec3 nor = get_normal(p);

        vec3 lpos  = vec3(18., 27., 3.);
        vec3 lpos2 = vec3(-12., 29., 1.);
        vec3 diff1 = vec3(.8) * get_diff(p, lpos);
        vec3 diff2 = vec3(.9) * get_diff(p, lpos2);
        vec3 diff  = diff1 + diff2;
        
        float ring = 1.4 - fract(4. * n);
        float lerp = pow(ring, 1.2) + n;

        vec3 mate = vec3(.0,0.2,.6) * 
                vec3(mix(vec3(.0,.3,.8), vec3(.75+.5*sin(n)), lerp));
        if(m == 2.) {
            mate=vec3(.8,.5,.1) * 
                vec3(mix(vec3(.5,.1,.0), vec3(.75+.5*sin(n)), lerp));
        }
        color += mate * diff2;
    } else {
        color += fadeColor;
    }
    color = mix( color, fadeColor, 1.-exp(-0.000004*t*t*t));
    return pow(color, vec3(0.4545));
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
    // set vectors to solve intersection
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    
    // center of the screen
    vec3 c = ro + cf * 1.;
    
    vec3 i = c + uv.x * cr + uv.y * cu;
    // intersection point
    return i-ro; 
}

void main(void) {
    // pixel screen coordinates
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/
        max(resolution.x,resolution.y);
    
    vec3 ro = vec3(0.,35.,-1.);
    vec3 lp = vec3(0.,0.,0.);

    //ro = get_mouse(ro);

    vec3 rd = ray(ro, lp, uv);
    vec3 col = render(ro, rd, uv);
    // Output to screen
    glFragColor = vec4(col,1.0);
}

