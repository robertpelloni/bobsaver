#version 420

// original https://www.shadertoy.com/view/wdjyRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Experiment in Polar Warping 
    Good read here --> https://www.osar.fr/notes/logspherical/
    SDF and marching stuff picked up from @iq
*/

#define MAX_STEPS     150.
  #define MAX_DIST    45.
  #define MIN_DIST    .001

#define PI          3.14159

mat2 r2(float a){ 
    float c = cos(a); float s = sin(a); 
    return mat2(c, s, -s, c); 
}

vec3 get_mouse(vec3 ro) {
    float x = 0.0;
    float y = 0.0;
    float z = 0.0;

    ro.zy *= r2(x);
    ro.xz *= r2(y);
    return ro;
}

float sdTorus( vec3 p, vec2 t ) {
    p.xy *= r2(PI*4.5);
    p.yz *= r2(PI*4.5);
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
} 

float sdBox( vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float shorten = 1.16;
float density  = 12.;

vec2 map(in vec3 p) {
    float thickness =  0.05;
    float lpscale = floor(density)/PI;
    vec2 res = vec2(100.,0.);
    // forward log-spherical map
    float r = length(p);
    p = vec3(log(r), acos(p.z / length(p)), atan(p.y, p.x));

    // scaling factor to compensate for pinching at the poles
    float xshrink = 1.0/(abs(p.y-PI)) + 1.0/(abs(p.y)) - 1.0/PI;

    // fit in the ]-pi,pi] interval
    p *= lpscale;
    p.x -= time *.75;
    p.z += time *.25;

    // tile coordinates
    p = fract(p*0.5) * 2.0 - 1.0;
    p.x *= xshrink;

    float pole = length(p.xz) - thickness;
    pole = min(length(p.yx) - thickness, pole);
    if(pole<res.x) res = vec2(pole,3.);

    p.xz *= r2(time*.5);

    float ret = sdBox( abs(p)-vec3(0.,.5,0.), vec3(.3,.01,.3) ); 
    ret = min(sdBox( abs(p)-vec3(0.,.5,0.), vec3(.3,.3,.01) ),ret);
    ret = min(sdBox( abs(p)-vec3(0.,.5,0.), vec3(.01,.3,.3) ),ret);
    if(ret<res.x) res = vec2(ret,1.);

    float rings = sdTorus( p.yzx, vec2(.5,.05) ); 
    rings = min(sdTorus( p.zxy, vec2(.5,.05) ),rings);
    if(rings<res.x) res = vec2(rings,2.);

    // compensate for the scaling that's been applied
    float mul = r/lpscale/xshrink;
    float d = res.x * mul / shorten;
    return vec2(d,res.y);
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
 
  vec2 get_ray( in vec3 ro, in vec3 rd ) {
    float depth = 0.;
    float mate = 0.;
    float m = 0.;
    for (float i = 0.; i<MAX_STEPS;i++) {
        vec3 pos = ro + depth * rd;
        vec2 dist = map(pos);
        mate = dist.y;
        if(dist.x<.0001*depth) break;
        depth += abs(dist.x*.65); // hate this but helps edge distortions
           if(depth>MAX_DIST) {
          depth = MAX_DIST;
          break;
        } 
    }
    return vec2(depth,mate);
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
    if(m==1.) mate = vec3(.2,.5,1.2);
    if(m==2.) mate = vec3(1.5,.3,.0);
    if(m==3.) mate = vec3(1.1,1.3,1.3);
    return mate;
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 color = vec3(0.0);
    vec3 fadeColor = vec3(.1,.15,.20);
    vec2 ray = get_ray(ro, rd);
    float t = ray.x;
    vec3 lcolor, dcolor, ccolor;
    
    if(t<MAX_DIST) {
        vec3 p = ro + t * rd;
        vec3 tint = get_color(ray.y); 
        lcolor = vec3(.3,.15,.01);
        dcolor = vec3(.3,.3,.4);
        ccolor = vec3(.2,.21,.22);
        vec3 lpos1 = vec3(-.5, 13.45, 0);
        vec3 lpos2 = vec3(-1.5, 12.21, .1);
        vec3 lpos3 = vec3(1.5, -1., -1.5);
        vec3 diff1 = dcolor * get_diff(p, lpos1);
        vec3 diff2 = lcolor * get_diff(p, lpos2);
        vec3 diff3 = ccolor * get_diff(p, lpos3);
        vec3 diff = diff1 + diff2 + diff3;
        color += tint * diff;
    } 
    //iq - saw it in a tutorial once
    color = mix( color, fadeColor, 1.-exp(-0.005*t*t*t));
    return pow(color, vec3(0.4545));
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    vec3 c = ro + cf * .87;
    vec3 i = c + uv.x * cr + uv.y * cu;
    return i-ro; 
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    // ray origin / look at point
    vec3 lp = vec3(-0.5,0.1,0.);
    vec3 ro = vec3(-1.15,2.5,-2.15);

    ro.xz *= r2(time*.13);

    ro = get_mouse(ro);

    vec3 rd = ray(ro, lp, uv);
    vec3 col = render(ro, rd, uv);
    glFragColor = vec4(col,1.0);
}
