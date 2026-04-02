#version 420

// original https://www.shadertoy.com/view/wlXBWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Fractal Experiment 05
    warp and fractal - more just playing around and 
    going Ooohh and Ahhh personally - fractals are
    not (mostly) productive but way fun to play with.

    fragtal() function based on map
    https://www.shadertoy.com/view/ttsBzM
    by @gaz

*/
#define MAX_DIST    80.

#define PI          3.1415926
#define PI2         6.2831853
#define R           resolution
#define T           time
#define S           smoothstep
#define M           mouse*resolution.xy
#define hue(a) .45 + .42*cos(1.42*a + vec3(1.45,.38,.15));
#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))

// rotation speeds - midi uniforms
float ar = .1, br = .12, cr = .095;

// offsets for fractal - midi uniforms
float av = .0105, bv = 1.35, cv = 1.26;

float folds;

vec3 fragtal(vec3 p, vec3 r, vec3 o) {
    vec3 res =  vec3(1000.,0.,0.);
    
    p.xy *= r2(r.x);
    p.xz *= r2(r.y);
    p.zy *= r2(r.z);

    p = abs(p)-1.65;

    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    if (p.x < p.y) p.xy = p.yx;

    float s=1.45;
    
    for(int i=0;i++<12;)
    {
      float r2=2./clamp(dot(p,p),.1,1.);
      p=abs(p)*r2-o;
      s*=r2;
    }

    float d = length(p)/s;
    
    if(d<res.x) {
        folds=log2(s*.00015);
        res = vec3(d,1.,folds);
    }

    return res;
}

vec3 map(vec3 p){

    float k = 6.0/dot(p,p); 
    p *= k;

    vec3 res =  vec3(1000.,0.,0.);
    vec3 q3 = p+vec3(0,1,0);

    float fl =6.5, hf = fl*.5;
    vec3 pi =  floor((p - hf)/fl);

    p = mod(p+hf,fl)-hf;
    
    // offset of slice - some osc going on.
    cv = 1.5+.2*sin(T*.25);
    bv = 1.35+.12*cos(T*.15);
    
    vec3 r = vec3(T*ar,T*br,T*cr);
    vec3 o = vec3(av,bv,cv);

    vec3 d = fragtal(p,r,o);
    if(d.x<res.x) {
        res = d;
    }

    float mul = 1.0/k;
    res.x *= mul / 1.5;
    return res;
}

vec3 get_normal(in vec3 p, in float t) {
    t *= .0005;
    vec2 eps = vec2(t, 0.0);
    vec3 n = vec3(
        map(p+eps.xyy).x - map(p-eps.xyy).x,
        map(p+eps.yxy).x - map(p-eps.yxy).x,
        map(p+eps.yyx).x - map(p-eps.yyx).x);
    return normalize(n);
}

vec3 ray_march( in vec3 ro, in vec3 rd, int maxstep ) {
    float t = .0001;
    vec2 m = vec2(0.);
    float r = 0., w = 1., dt;
    for( int i=0; i<maxstep; i++ ) {
        vec3 p = ro + rd * t;
        vec3 d = map(p);
        if(d.x<.0005*t||t>MAX_DIST) break;
        t += d.x;
        m = d.yz;
    }
    return vec3(t,m);
}

float get_diff(vec3 p, vec3 lpos, vec3 n) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),0. , 1.),
          shadow = ray_march(p + n * .001 * 2., l, 64).x;
    if(shadow < length(p -  lpos)) dif *= .1;
    return dif;
}

vec3 r( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 c = vec3(0.);
    vec3 fadeColor =  hue(uv.y*2.5);
    vec3 ray = ray_march(ro, rd, 128);
    float t = ray.x,
          m = ray.y,
          f = ray.z;
    if(t<MAX_DIST) {
        vec3 p = ro + t * rd,
             n = get_normal(p, t);
        vec3 color1 = hue(4.7);
        vec3 color2 = hue(16.5);
        // lighting and shade
        vec3 lpos1 = vec3(-.2, 24.2, 8.5);
        vec3 lpos2 = vec3(.0, 12.0, 12.0);
        vec3 diff = color1 * get_diff(p,lpos1,n) +
                    color2 * get_diff(p,lpos2,n);
        //cheap fill light
        vec3 sunlight = clamp(dot(n,vec3(1.,9.,9.)),.25 ,6.) *vec3(.35);
       
        //simple color
        vec3 h = hue(f);

        //mixdown
        c += h * diff * sunlight; 
    } else {
        c = fadeColor;
    }
    //fog @iq
    c = mix( c, fadeColor, 1.-exp(-.0025*t*t*t));
    return c;
}

float zoom = 4.5;

void main(void) {
    //uv coords
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    //if(M.w>0.) zoom = 2.35;
    //set origin and direction
    vec3 ro = vec3(0.,0.,.1+zoom),
         lp = vec3(0.,0.,0.);

    //set camera view
    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .95,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;
    //render
    vec3 C = r(ro, rd, U);
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
