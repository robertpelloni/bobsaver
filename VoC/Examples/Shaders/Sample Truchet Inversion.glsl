#version 420

// original https://www.shadertoy.com/view/3d2cDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Playing with inversions thansks to @mla
    Some fooling around with patterns i've 
    done in 2d and brining them into 3D

    one level cheap reflections and rainbow
    effect. 

    thanks to all for tips/tricks/comments

*/

#define MAX_STEPS         145.
#define MAX_DIST          20.
#define MIN_DIST          .001

#define PI              3.14159
#define PI2             6.28318

// Change to 2 to for antialiasing
#define AA 1
#define ZERO 0
mat2 r2(float a){ 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}
  
mat2 s2(float s) {
    return mat2(s,0.,0.,s);
}

float hash(vec2 p) {
      p = fract(p*vec2(931.733,354.285));
      p += dot(p,p+39.37);
      return fract(p.x*p.y);
}

vec3 hash(vec3 p) {
    p *= mat3( 127.1,311.7,-53.7,
               269.5,183.3, 77.1,
              -301.7, 27.3,215.3 );
    return 2.*fract(sin(p)*43758.5453123) -1.;
}
    //@iq for a lot but this too
vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1., 0., 1.);
    return c.z * mix(vec3(1.), rgb, c.y);
}

vec3 get_mouse(vec3 ro) {
    float x = -5.;
    float y = 0.0;
    float z = 0.0;

    ro.zy *= r2(x);
    ro.xz *= r2(y);
    return ro;
}

    //@BigWIngs truchet tutorial on youtube rocks!
float get_truch(vec2 uv) {
    vec2 tile_uv = fract(uv) -.5;
    vec2 id = floor(uv);
    float n = hash(id);
    float checker = mod(id.y + id.x,2.) * 2. - 1.;
    if(n>.5)tile_uv.x *= -1.;

    vec2 cUv = tile_uv-sign(tile_uv.x+tile_uv.y+.001)*.5;
    float d = length(cUv);
    float mask = smoothstep(.01, -.01, abs(d-.5)-.15);
    return mask;
}
    
    float shorten = 1.36;
    float density  = 8.;
    float thickness =  0.025;

vec4 map(vec3 p) {
    vec2 res = vec2(100.,0.);
    //@mla inversion
    float k = 8.0/dot(p,p); 
    p *= k;
      
    p.z -= time;
    float mask = get_truch(p.xz*1.)/PI2; // also try .375 here too
    p.x +=1.;

    // tile coordinates
    vec3 pi = floor((p + 1.)/2.);
    p = mod(p+1.,2.) - 1.;

    float pole = length(p.xz) - thickness;
    pole = min(length(p.yx-vec2(.0,0.)) - thickness, pole);
    pole = min(length(p.zy-vec2(.0,0.)) - thickness, pole);
    if(pole<res.x) res = vec2(pole,1.);

    float grnd = length(p.y) - .015 + mask / PI;\
    grnd = min(length(p) - .2,grnd);
       // grnd = max(grnd,-mask)*grnd;
    if(grnd<res.x) res = vec2(grnd,3.);

    // compensate for the scaling that's been applied
    float mul = 1.0/k;
    float d = res.x * mul / shorten;
    return vec4(d,res.y, pi.xy);
}

vec3 get_normal(vec3 p) {
      float d = map(p).x;
    vec2 e = vec2(.01,.0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
    );
    return normalize(n);
}
 
vec4 get_ray(vec3 ro,vec3 rd ) {
    float depth = 0.;
    float mate = 0.;
    float m = 0.;
    vec2 bi = vec2(3.);
    for (float i = 0.; i<MAX_STEPS;i++) {
        vec3 pos = ro + depth * rd;
        vec4 dist = map(pos);
        mate = dist.y;
        bi = dist.zw; // if you want the id for tiles
        if(dist.x<.001*depth) break;
        depth += abs(dist.x*.35);
        if(depth>MAX_DIST) {
          depth = MAX_DIST;
          break;
        } 
    }
    return vec4(depth,mate,bi);
}

float get_diff(vec3 p, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    vec3 n = get_normal(p);
    float dif = clamp(dot(n,l),0. , 1.);
    float shadow = get_ray(p + n * MIN_DIST * 2., l).x;
    if(shadow < length(p -  lpos)) {
       dif *= .1;
    }
    return dif;
}
    
vec3 get_color(float m){
    vec3 mate = vec3(.2);
    if(m==1.) mate = vec3(.5);
    if(m ==2.) mate = vec3(.05);
    if(m ==3.) mate = vec3(.2);
    return mate;
}
    
vec3 render(vec3 ro, vec3 rd, vec2 uv, float isVr) {
    vec3 color = vec3(0.0);
    vec3 fadeColor = vec3(.1,.15,.19);
    vec4 ray = get_ray(ro, rd);
    float t = ray.x;
    vec2 bi = ray.zw;
    if(t<MAX_DIST) {
        vec3 p = ro + t * rd;
        vec3 n = get_normal(p);
        vec3 tint = get_color(ray.y); 

        vec3 lpos1 = vec3(.0, .5, -3.5);
        vec3 lpos2 = vec3(-.5, .5, -1.5);
        vec3 lpos3 = vec3(.0, .13, -.89);

        vec3 diff1 = vec3(.5) * get_diff(p, lpos1);
        vec3 diff2 = vec3(.2) * get_diff(p, lpos2);
        vec3 diff3 = hsv2rgb(vec3(bi.x*.1,1.,.5)) * get_diff(p, lpos3);

        vec3 diff =  diff1 + diff2 + diff3;
        color += tint * diff;

        if(ray.y==3. && isVr ==0.) {
          tint = hsv2rgb(vec3(p.y*.6+p.x*.75,1.,.5))*.5;
          vec3 rr=reflect(rd,n);
          vec4 tm=get_ray(p,rr);
          if(tm.x<MAX_DIST){
              p+=tm.x*rr;
              color += tint * get_diff(p, lpos1) *    get_diff(p, lpos2);
          }   
        }
    } 
    //@iq - basics you know..
    color = mix( color, fadeColor, 1.-exp(-0.085*t*t*t));
    return pow(color, vec3(0.4545));
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    vec3 c = ro + cf * .9;
    vec3 i = c + uv.x * cr + uv.y * cu;
    return i-ro; 
}

void main(void) {
    vec3 color = vec3(0.);
    vec2 uv;
    // AA @NuSan
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {

        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        uv = (2. * gl_FragCoord.xy - (resolution.xy+o))/resolution.y;
    #else    
        uv = (2. * gl_FragCoord.xy - resolution.xy )/resolution.y;
    #endif
        float time =50.+ time*.9/PI2;
        // ray origin / look at point
        vec3 lp = vec3(.0,.3,.0);
        vec3 ro = vec3(0.,.4,-2.25);

        ro = get_mouse(ro);

        vec3 rd = ray(ro, lp, uv);
        color += render(ro, rd, uv,0.);

    #if AA>1
    }
    color /= float(AA*AA);
    #endif

    glFragColor = vec4(color,1.0);
}
