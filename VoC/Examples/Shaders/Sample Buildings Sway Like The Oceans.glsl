#version 420

// original https://www.shadertoy.com/view/wdKXDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Buildings sway like the oceans
// 
// Hash noise to generate city
// size / figured out amount of windows/floors
// kept it basic - no real materials
// wanting to add etherial glowing orb
// in progress or just done plaing?
//
// sdf functions/deformation & help
// iq/shane and others on shadertoy
// 
// click and drag camera
// auto cam - enable/disable below 1 on 0 off
//////////////////////////////////////////
#define cameraAuto 0

#define MAX_DIST     100.0
#define MIN_DIST     0.0001
#define MAX_STEPS     255

#define PI          3.1415926
#define PI2         6.2831853
#define r(x) fract(sin(x * star) * 36.)
const float size = 10.;
const float hlf = size/2.;

vec2 hash2( vec2 p ) {
    return fract(
        sin(
            vec2(
                dot(p,vec2(44.3,25.7)),
                dot(p,vec2(87.2,54.1)))
           )*4258.4373);
}

float noise( vec2 coord, float seed ){
  float phi = 1.6180339887498 * 0000.1;
  float pi2 = PI * 0.1;
  float sq2 = 1.4142135623730 * 10000.;

  float temp = fract(
    sin(
      dot(
        coord*(seed+phi), vec2(phi, pi2)
      )
    ) * sq2
  );
  return temp;
}

mat2 r2( float a ) { 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}

vec3 get_mouse( vec3 ro ) {
    float x = .5;
    float y = .3;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}

float box( vec3 p, vec3 b ) {
      vec3 d = abs(p) - b;
      return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float soc( vec3 p, float s) {
  p.xz *= r2(.79); 
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float ball( vec3 p, float r ) {
  return length( p ) - r;
}

float building(vec3 p, vec2 pi) {
    float bs = size / 3.5;
    float d1 = 1.;
    float sx = .65;
    float sz = sx-.15;
    float res = d1;
    vec2 ph = hash2(pi);
    
    float tf = floor(ph.y * 8.);
    float hgt = abs(tf/sx)*sx;
    
    if(hgt<1.){
        hgt = .001;
    }else{
          float d0 = box(p,vec3(bs+1.,.15,bs+1.));
        d1 = box(p-vec3(0.,hgt,0.),vec3(bs,hgt,bs));
        d1 = min(d0,d1);
    }

    vec3 d = vec3(abs(p.x),p.y,abs(p.z));
    vec3 e = vec3(p.x,p.y,abs(p.z));
    vec3 f = vec3(abs(p.x),p.y,p.z);

    if (hgt>1.9) {  
        float d2 = box(d-vec3(bs+.75,0.,bs+.75),vec3(.05,.65,.05));
        d1=min(d2,min(box(p-vec3(0.,hgt*1.92,0.),vec3(bs+.25,.2,bs+.25)),d1));

        if(hgt>5.6 && ph.y <.5 || ph.x <.25 && hgt>2. ){
            d1 = min(soc(p-vec3(0.,hgt*2.,0.),bs+1.),d1); //dtip
        }
        
        if(hgt>3.){
            float wd = (hgt-1.) / sx;
            float d9 = 1.;
            // cut windows//
            for(float i = 0.; i<wd; i+=1.){
               float ypos = 1.+float(i)*1.25;
               d9 = box(d-vec3(bs-.1,ypos,bs/2.),vec3(5.11,sz,sz*1.95)); 
               d2 = box(d-vec3(bs/2.,ypos,bs-.1),vec3(sz*1.95,sz,5.11));
               d2 = min(box(p-vec3(0.,ypos,0.),vec3(sz)),d2);
               d1 = max(d1,-min(d2,d9));
            }
            
            float d8 = min(
                box(p-vec3(0.,hgt*2.,0.),vec3(bs-.5,.4,bs-.5)),
                box(p-vec3(0.,hgt*2.05,0.),vec3(bs-1.5,.4,bs-1.5))
            );
            d1 = min(d8,d1);
        }
    }
    
    if (hgt>1. && hgt <2.5) {
        d1 = min(box(p-vec3(0.,hgt+.5,0.),vec3(bs+.15,hgt *.15,bs+.15)),d1);   
        if(hgt >1.05) d1 = min(ball(p-vec3(0.,hgt+1.,0.),bs),d1);  
    }
 
    res = d1;
    
    return res;
}

float roads(vec3 p, vec2 pi) {
    vec3 d = vec3(abs(p.x),p.y,abs(p.z));
    float hgt = -.05;//10. + 10. * sin(time * .5);
    float d1 = box(d-vec3(hlf,hgt,hlf),vec3(hlf,.15,.8));
       float d2 = box(d-vec3(hlf,hgt,hlf),vec3(.8,.15,hlf));
    
    d1 = min(d2,d1);
    return d1;
}

float map (in vec3 pos) {
     float res = 1.;
    pos.z += time *2.15;

    vec3 center = vec3(0., 0., 0.);
    vec3 p = pos-center;
    float t = time + 13.;
       float fwave = .11 + .11 * sin(p.y*.25 + t*3.75) - cos(p.x*.35 + t*1.05);

    p.yx  -= fwave;
    vec3 pi = floor((p + hlf)/size);
    
    p = vec3(
        mod(p.x+hlf,size) - hlf,
        p.y,
        mod(p.z+hlf,size) - hlf
    );

    vec3 g = p;
    
    float d1 = building(p, pi.xz);
     if(d1<res)  res = d1;
    
    float d2 = roads(p, pi.xz);
     if(d2<res)  res = d2,1;
    
 return res;
}

vec3 get_normal(in vec3 p) {
    float d = map(p);
    vec2 e = vec2(.01,.0);
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx)
    );
    return normalize(n);
}

float ray_march( in vec3 ro, in vec3 rd ) {
    float depth = 0.0;
    float m = -1.;
    for (int i = 0; i<MAX_STEPS;i++) {
        vec3 pos = ro + depth * rd;
        float dist = map(pos);
        if(dist<MIN_DIST) break;
        depth += (dist*.65);
           if(depth>MAX_DIST) depth = MAX_DIST;
    }
 
    return depth;

}

float get_diff(vec3 p, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    vec3 n = get_normal(p);
    float dif = clamp(dot(n,l),0. , 1.);
    
    float shadow = ray_march(p + n * MIN_DIST * 2., l);
    if(shadow < length(p -  lpos)) {
       dif *= .1;
    }
    return dif;
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 color = vec3(0.);
    vec3 fadeColor = vec3(.0);
    float ray = ray_march(ro, rd);
    float t;
    if(ray<MAX_DIST) {
        t = ray;
        vec3 p = ro + ray * rd;
        vec3 n = get_normal(p);
        vec2 swave = 2. + 2. * sin(p.yz * .2 + time *.5 * PI/2.);
        float wb = 1. + 1. * sin(time*.5);
        vec3 lpos  = vec3(5.1, 3.+wb, 5.);
        vec3 lpos2 = vec3(-1., 15., 1.);
        vec3 diff1 = vec3(wb, .5, .95) * get_diff(p, lpos);
        vec3 diff2 = vec3(.1, .3, .6 ) * get_diff(p, lpos2);
        vec3 diff  = diff1 + diff2;
        
        float bounce = clamp( .1 + .5 * dot(n,vec3(0.,-1.,0.)), 0.,1.)*.5;
   
        color += vec3(.8) * diff + bounce;
    } else {

        for (float star = 0.; star != 323.; ++star) {
            color += vec3(1.) * smoothstep(.55 / resolution.y, 0., 
            length((uv*.5+.5) - fract(vec2(
                r(star) * (resolution.x+ro.x),
                r(star) * (resolution.y-ro.y-time*.01)
            ))));
        }
        color = mix(color, fadeColor,exp(-1.*rd.y));   
    }
        
    color = mix( color, fadeColor, 1.-exp(-0.000009*t*t*t));
    return pow(color, vec3(0.4545));
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
    // set vectors to solve intersection
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    
    // center of the screen
    vec3 c = ro + cf * .75;
    
    vec3 i = c + uv.x * cr + uv.y * cu;
    // intersection point
    return i-ro; 
}

void main(void) {
    // pixel screen coordinates
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/
        max(resolution.x,resolution.y);
    // ray origin / look at point
    float swv = .25 + .35 * sin(time*.1*PI/2.);
    vec3 ro = vec3(5.,11.,-25.);
    vec3 lp = vec3(5.,8.5,0.);
    ro.zy *= r2(-.25);

    #if cameraAuto
    float mtimer = 13. + time*.15;
    float mcheck = mod(mtimer,6.);

    if(mcheck<2.) {
           ro = vec3(5.4,32.,5.);
        lp = vec3(5.4,.1,0.);
        ro.zy *= r2(.2);
        ro.zx *= r2(.3);
    } else if(mcheck<4.) {
          ro.zy *= r2(.5);
           ro.zx *= r2(-.86);
    }
    #else
    // get any camera movment
    ro = get_mouse(ro);
    #endif
    
    // get ray direction
    vec3 rd = ray(ro, lp, uv);
    // render scene
    vec3 col = render(ro, rd, uv);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
