#version 420

// original https://www.shadertoy.com/view/tsXfzN

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    using a torus do the floor / mod rep thing
    and offset based on the tutorial from Art of Code
    https://www.youtube.com/watch?v=2R7h76GoIJM

    VR update - trying to optimize this..

    click and pan around 

*/

#define MAX_STEPS         75.
#define MAX_DIST          35.
#define MIN_DIST          .0001

#define PI              3.1415
#define PI2             6.2831

// Change to 2 to enable/ 1 to disable antialiasing
#define AA 2

#define ZERO (min(frames,0))

// change throbbing colors
vec3 colorA = vec3(.99, .97, .82);
vec3 colorB = vec3(.8, .04, .25);
vec3 colorC = vec3(.8, .7, .7);
// vaporwave aesthetics //
//vec3 colorA = vec3(.4, .4, .7);
//vec3 colorB = vec3(.0, .8, .5);
//vec3 colorC = vec3(.9, .9, .9);

float refl = 1.;         // turn off reflections 
float speed = .75;         // movement speed
float spacing = 5.;        // domain box around 1 rep of tile
float thic = .45;        // max worm thickness
float thin = .2;        // min work thickness

mat2 r2(float a){ 
    float c = cos(a); float s = sin(a); 
    return mat2(c, s, -s, c); 
}

float hash(vec2 p) {
      p = fract(p*vec2(931.733,354.285));
      p += dot(p,p+39.37);
      return fract(p.x*p.y);
}

vec3 get_mouse(vec3 ro) {
    float x = -.2;
    float y = -.65;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}

float sdTorus( vec3 p, vec2 t, float a ) {
  if(a>0.){
      p.xy *= r2(PI*4.5);
      p.yz *= r2(PI*4.5);
  }
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float yOffset =23.;
vec4 map(in vec3 p) {
    float size = spacing;
    float hlf = size/2.;
    vec2 res = vec2(100.,0.);
    p.y += yOffset-hlf/2. + .1* sin(time*.45);
    p.z += .2* sin(time*.35);
    p.x += 20.+ time*0.6;
    vec3 v = p;

    vec3 vi = floor((v + hlf)/size);
    vec3 vp = vec3(
      mod(v.x+hlf,size) - hlf,
      mod(v.y+hlf,size) - hlf,
      mod(v.z+hlf,size) - hlf
    );
  
    p.x -=hlf;
    p.y +=hlf;
    p.z += hlf;
  
    vec3 pi = floor((p + hlf)/size);
    vec3 rp = vec3(
      mod(p.x+hlf,size) - hlf,
      mod(p.y+hlf,size) - hlf,
      mod(p.z+hlf,size) - hlf
    );

    float n = hash(pi.xz);
    float checker = mod(pi.z + pi.x,2.) * 2. - 1.;
    if(n>.5)rp.x *= -1.;

    float n2 = hash(vi.xz);
    float checker2 = mod(vi.z + vi.x,2.) * 2. - 1.;
    if(n2>.5)vp.x *= -1.;
  
    float thx  = thic + thin *sin(p.z*1.25+p.x*.8+p.y*1.85+time*.55);

    float rings = min(
      sdTorus(vp-vec3(hlf,0.,hlf),vec2(hlf,thx),0.),
      sdTorus(vp-vec3(-hlf,0.,-hlf),vec2(hlf,thx),0.)
    );

    if(rings<res.x) res = vec2(rings,3.);
    
    float rings2 = min(
      sdTorus(rp-vec3(hlf,hlf,0.),vec2(hlf,thx),1.),
      sdTorus(rp-vec3(-hlf,-hlf,0.),vec2(hlf,thx),1.)
    );

    if(rings2<res.x) res = vec2(rings2,4.);
  
    // reference grid //
    //float thickness = .02;
    //float pole = length(rp.xz) - thickness;
    //pole = min(length(rp.yx-vec2(.0,0.)) - thickness, pole);
    //pole = min(length(rp.zy-vec2(.0,0.)) - thickness, pole);
    //if(pole<res.x) res = vec2(pole,1.);
  
    return vec4(res, pi.xy);
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
 
vec4 get_ray( in vec3 ro, in vec3 rd ) {
    float depth = 0.;
    float mate = 0.;
    float m = 0.;
    vec2 bi = vec2(3.);
    for (float i = 0.; i<MAX_STEPS;i++) {
        vec3 pos = ro + depth * rd;
        vec4 dist = map(pos);
        mate = dist.y;
        bi = dist.zw;
        if(dist.x<.0001*depth) break;
        depth += abs(dist.x*.6);
        if(depth>MAX_DIST) {
          depth = MAX_DIST;
          break;
        } 
    }
    return vec4(depth,mate,bi);
}

vec2 get_reflect( in vec3 ro, in vec3 rd ) {
    float depth = 0.;
    float m = 0.;
    for (float i = 0.; i<75.;i++) {
        vec3 pos = ro + depth * rd;
        vec4 dist = map(pos);
        if(dist.x<.001*depth) break;
        m = dist.y;
        depth += abs(dist.x*.55); 
    }
    return vec2(depth,m);
}
  
float get_diff(vec3 p, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    vec3 n = get_normal(p);
    float dif = clamp(dot(n,l),0. , 1.);
    float shadow = get_reflect(p + n * MIN_DIST * 2., l).x;
    if(shadow < length(p -  lpos)) {
       dif *= .1;
    }
    return dif;
}
    
vec3 get_light(vec3 p, vec3 lpos, vec3 color) {
    return color * get_diff(p, lpos);
}

vec3 mix_color(float m, vec3 p) {
    vec3 ca = colorA;
    vec3 cb = colorB;
    vec3 cc = colorC;
    
    float size = spacing;
    float hlf = size/2.;
    p.y += yOffset-hlf/2.;
    vec3 dp = p;
    vec3 pz = (floor((dp + hlf)/size))*2.;
    
    p.x -=hlf;
    p.y +=hlf;
    p.z += hlf;
    vec3 py = (floor((p + hlf)/size))*2.;
    
    vec3 mate;
    if(m==4.) {
          mate = mix(ca,cb,cos(py.z+p.y*0.75 + time*.5));
    } else {
         mate = mix(cc,vec3(1.),sin(pz.y+dp.z*.95 + time*.6));
    }
     return mate;
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv, float vr) {
  vec3 color = vec3(0.0);
  vec3 fadeColor = colorC;
  vec4 ray = get_ray(ro, rd);
  float t = ray.x;
  vec2 bi = ray.zw;

  if(t<MAX_DIST) {
      float size = spacing;
      float hlf = size/2.;
      vec3 p = ro + t * rd;
      vec3 n = get_normal(p);
      vec3 tint = mix_color(ray.y, p);
 
      vec3 color4 = vec3(0.3);
      
      vec3 lpos1 = vec3(.0, .05, -.1);
      vec3 lpos2 = vec3(.05, .02, 1.);
      vec3 lpos3 = vec3(-.2, 0., -2.5);

      vec3 diff1 = get_light(p, lpos1,color4);
      vec3 diff2 = get_light(p, lpos2,color4);
      vec3 diff3 = get_light(p, lpos3,color4);

      vec3 diff =  diff1 + diff2 + diff3;
      color += tint * diff;
      
      if((ray.y==3.|| ray.y==4. ) && vr <1. && refl >0.) {

          vec3 rcolor = vec3(0.);
          vec3 rr=reflect(rd,n);
          vec2 tm=get_reflect(p,rr);
          if(tm.x<MAX_DIST){
             p+=tm.x*rr;
             vec3 tint = mix_color(ray.y, p);
             rcolor += tint * get_light(p, lpos1,color4);
          }   
        color += rcolor;
      }
  } 
    
  //iq - saw it in a tutorial once
  color = mix( color, fadeColor, 1.-exp(-0.00026*t*t*t));
  return pow(color, vec3(0.4545));
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
  vec3 cf = normalize(lp-ro);
  vec3 cp = vec3(0.,1.,0.);
  vec3 cr = normalize(cross(cp, cf));
  vec3 cu = normalize(cross(cf, cr));
  vec3 c = ro + cf * .8;
  vec3 i = c + uv.x * cr + uv.y * cu;
  return i-ro; 
}

void main(void) {
    vec3 color = vec3(0.);
       vec2 uv;
    // 
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        uv = (gl_FragCoord.xy-.5 * resolution.xy+o)/min(resolution.x,resolution.y);
    #else    
        uv = (gl_FragCoord.xy-.5 * resolution.xy)/min(resolution.x,resolution.y);

    #endif
        
    vec3 lp = vec3(.0,.0,.0);
    vec3 ro = vec3(0.,.0,-.85);

    ro = get_mouse(ro);

    vec3 rd = ray(ro, lp, uv);
    color += render(ro, rd, uv, 0.);
    // AA from NuSan
    #if AA>1
        }
    color /= float(AA*AA);
    #endif
      glFragColor = vec4(color,1.0);
}
