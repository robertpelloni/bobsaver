#version 420

// original https://www.shadertoy.com/view/wtScRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Hexagon using the worst tile method 
//
// tiling from @Shane https://www.shadertoy.com/view/3d2fzK
// learning though deconstruction 
// 4 pass method for hex packing

#define MAX_DIST     135.

#define PI          3.1415926
#define PI2         6.2831
#define R             resolution
#define M             mouse*resolution.xy
#define T             time
#define S             smoothstep
#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))

vec3 hsv2rgb( in vec3 c ) { //@iq
    vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
    return c.z * mix(vec3(1.),rgb,c.y);
}

//@iq vec2 to float hash.
float hash2(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

float circle(vec2 pt, float r, vec2 center, float lw) {
      vec2 p = pt - center;
      float len = length(p);
      float hlw = lw / 2.;
      float edge = .01;
      return S(r-hlw-edge,r-hlw, len)-S(r+hlw,r+hlw+edge, len);
}

// not used
vec3 get_mouse( vec3 ro ) {
    float x = -.6;
    float y = .9;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}
// 2d hex functions and mapping
float hexdist(vec2 p) {
    p=abs(p);
    float h = dot(p,normalize(vec2(1.,1.73)));
    h = max(h,p.x);
    return h; 
}

vec2 hexmp(vec2 p) {
    vec2 r = vec2(1.,1.73);
    vec2 hr = r*.5;
    vec2 GA = mod(p,r)-hr;
    vec2 GB = mod(p-hr,r)-hr;
    vec2 G = dot(GA,GA)<dot(GB,GB) ? GA : GB; 
    return G;
}

vec2 G;
vec4 hexcoord(vec2 p) {
    G = hexmp(p); 
    float x = atan(G.x,G.y);
    float y = 0.5-hexdist(G);
    vec2 I = (p-G);
    //float x
    return vec4(x,y,I);
}

//@iq twist
vec3 twist( in vec3 p ){
    float cx = .01;//+.10*sin(T*.08); 
    float kx = -clamp(cx,.0,.08);
    return vec3(r2(kx*p.z)*p.xy,p.z)/1.5;
}

//@iq extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}
float sHexS(in vec2 p, float r, in float sf){
      const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.
      // X and Y reflection.  
      p = abs(p); 
      p -= 2.*min(dot(k.xy, p), 0.)*k.xy;
      r -= sf;
      // Polygon side.
      return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r) - sf;
}

#define HEX_SCALE .5
float mid = 0.;
vec3 hitPoint =vec3(0.);

vec4 map(vec3 q3){
    q3 = twist(q3);
    q3.xz*=r2(T*.062);
    q3.z -= T*12.5;
    
    
    //@Shane - Hexagon tiling >mind blown<
    const float scale = 2./HEX_SCALE;
     // dimension | length to height ratio.
    const vec2 l = vec2(scale*1.732/2., scale);
    // helper | size of the repeat cell.
    const vec2 s = l*2.;
    float d = 1e5;
    vec2 p, ip;
    // brick ID.
    vec2 id = vec2(0);
    vec2 cntr = vec2(0);
    const vec2[4] ps4 = vec2[4](vec2(-l.x, l.y), l + vec2(0., l.y), -l, vec2(l.x, -l.y) + vec2(0., l.y));
    
    float boxID = 0.; // Box ID. (which pass you're on)
    
    for(int i = 0; i<4; i++){
        // Block center.
        cntr = ps4[i]/2.;
        // Local coordinates.
        p = q3.xz - cntr;
        ip = floor(p/s) + .5; // Local tile ID.
        p -= (ip)*s; // New local position.
        // Correct positional individual tile ID.
        vec2 idi = (ip)*s + cntr;
         
        // hashed height and stuff
        //float hx=distance(idi,vec2(.5));
        float hx=hash2(idi)*1.25;
        float th = hash2(idi)*2.;
        float h = hash2(idi*3.4);
        h = h + h*sin(th*2.+T*3.1);
   

        // make shape
        float di2D = sHexS(p, scale/(2.95-th*.45) + .035*scale, .05*scale),
              di = opExtrusion(di2D, (q3.y - th), th);
        // ID, and box ID. 
        if(di<d){
            d = di;
            id = idi;
            boxID = float(i);
            mid = 1.;
        }
        // second riser
        vec3 p3 = vec3(p.x,q3.y,p.y);
        float di3D = sHexS(p, scale/5.5 + .035*scale, .05*scale),
              sp = opExtrusion(di3D, (q3.y - (th*2.)-h)-.01, h);
        if(sp<d){
            d = sp;
             id = idi;
            boxID = float(i);
            mid = 2.;
        }   
    }
    
    float flr = q3.y;
    if(flr<d){
        d = flr;
        mid = 3.; 
    }
    
    hitPoint = vec3(q3);
    // Return the distance, position-base ID and box ID.
    return vec4(d/1.15, id, boxID);
}

vec3 get_normal(in vec3 p, in float t) {
    t *= 0.001+.0001;
    vec2 eps = vec2(t, 0.0);
    vec3 n = vec3(
        map(p+eps.xyy).x - map(p-eps.xyy).x,
        map(p+eps.yxy).x - map(p-eps.yxy).x,
        map(p+eps.yyx).x - map(p-eps.yyx).x);
    return normalize(n);
}
// marcher with distance steps shortened to reduce
// artifacts 
vec4 ray_march( in vec3 ro, in vec3 rd, int maxstep ) {
    float t = 0.001;
    vec3 m = vec3(0.);
    for( int i=0; i<maxstep; i++ ) {
        vec4 d = map(ro + rd * t);
        m = d.yzw;
        if(d.x<.001*t||t>MAX_DIST) break;
        t += d.x*.8;
    }
    return vec4(t,m);
}
// Shading is my second worst skill..
float get_diff(in vec3 p, in vec3 lpos, in vec3 n) {
    vec3 l = lpos-p;
    vec3 lp = normalize(l);
    float dif = clamp(dot(n,lp),0. , 1.),
          shadow = ray_march(p + n * 0.0001 * 2.,lp,64).x;
    if(shadow < length(l)) dif *= .2;
    return dif;
}
// ACES tone mapping from HDR to LDR
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0, 1.0);
}
void main(void) {
    vec2 F = gl_FragCoord.xy;
    // UV Space and coords
    vec2 U = (2.*F.xy-R.xy)/max(R.x,R.y);
    // Camera Ray Order and Look at Point
    vec3 ro = vec3(7.,25.,15.5),
         lp = vec3(0.,1.,.0);

    // uncomment to pan around
    //ro = get_mouse(ro);
    
    // set camera
    vec3 cf = normalize(lp-ro),
          cp = vec3(0.,1.,0.),
          cr = normalize(cross(cp, cf)),
          cu = normalize(cross(cf, cr)),
          c = ro + cf * .75,
          i = c + U.x * cr + U.y * cu,
          rd = i-ro;

    vec3 C = vec3(0.);
    
    // trace dat map
    vec4 ray = ray_march(ro,rd,128);
    float t = ray.x;
    vec3 hid = ray.yzw;
    
    if(t<MAX_DIST) {
        vec3 p = ro + t * rd,
             n = get_normal(p, t),
             h = vec3(.5);
        
        // coloring stuff
        float fs = distance(hid.xy,vec2(.5))*.04;
        h = vec3(.5);
        // just the first block color
        if(mid==1.){
            h = hsv2rgb(vec3(fs,1.,.5));
        }
        // circle on hex's
        if(mid==2.){
            const float scale = .5/HEX_SCALE;
            vec2 Hxp = hexmp((hitPoint.zx+vec2(0.,1.732))*.5/scale);
            float circl = circle(Hxp,.20+.15*sin(hash2(hid.xz)*4.+T*1.3),vec2(0.),.1);
            h -= hsv2rgb(vec3(fs,1.,.5))*(circl);
        }
        // floor hex map design
        if(mid==3.){
            const float scale = 2./HEX_SCALE;
            vec4 H = hexcoord((hitPoint.zx+vec2(100.,1.732))/scale);
            
            float gz = 1.-G.x-G.y;
            float angle = atan(G.x, G.y) - T*sign(gz);
            float stripes = sin(angle * 11.);

            h -= hsv2rgb(vec3(fs*2.,1.,.5))*S(.2,.75,max(1.-stripes,H.y));
        }
        
        // shading and stuff
        vec3 lpos1 = vec3(1.0, 16.0, 1.5),
             diff =  vec3(2.) * get_diff(p, lpos1, n);
             diff +=  vec3(2.) * get_diff(p, vec3(3.75,11.,20.5), n);

        C += h * (diff);
        
    } else {
        C += vec3(.025);
    }
    // fog ACES and Gamma before output
    C = mix( C, vec3(.025), 1.-exp(-.000025*t*t*t));
    C = ACESFilm(C);
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
