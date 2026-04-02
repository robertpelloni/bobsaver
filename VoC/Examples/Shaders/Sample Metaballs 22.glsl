#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dKfzD

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Was picking over my bookmarked links from being a newbie 
    and started to play with metaballs and soft shadows. 
    [url]http://www.pouet.net/topic.php?which=7931[/url]

    However I cant figure out how to lighten those softshadows
    they always seem so solid black/dark..?
*/

const float min_dist = .001;
const float max_dist = 65.;

#define T                 time
#define M                mouse*resolution.xy
#define R                resolution

const float PI = acos(-1.0);

mat2 r2(float a)     {    return mat2(cos(a),sin(a),-sin(a),cos(a));}
float hash(float n)    {    return fract(sin(n)*43758.5453123);}
float hash21(vec2 p){    return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453);}
float noise(in vec2 x){
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    float res = mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                    mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
    return res;
}
vec3 hsv(float h,float s,float v) {
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

const vec3 check1 = vec3(0.118,0.235,0.580);
const vec3 check2 = vec3(0.773,0.808,0.827);
const vec3 check3 = vec3(0.306,0.141,0.016);
const float checkSize = 0.25;
vec3 g_hitPoint, s_hitPoint;
float g_hash, s_hash;

//@iq sdf
float sdBox( vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float opSu( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

//metaball stuff
float isosurfacelevel;
float metaballs(vec3 p) {
    float sum=0.0, i=0.0, nballs=14.0;
    while (i++<nballs){
        float fn = (i*5.27)/nballs;
        float x = .43*sin(i+fn-T*.24)+.45*cos(i-T*.44);
        float y = .45+.41*sin(fn+T*.26)+.45*cos(i-T*.24);
        float z = .31*cos(i+fn+T*.42)+.23*sin(i+T*.24);
        sum += .6175 / length(vec3(x,y,z) - p);
    }
    return ((nballs*nballs+isosurfacelevel) / (sum*sum) - isosurfacelevel) * .1;
}

mat2 rot;
vec2 map(vec3 p) {
    vec2 res = vec2(100.,-1.);
    vec3 q = p-vec3(0.,.5,0.);
    p.z+=T*.5;

    vec2 f=fract((p.xz-1.)*checkSize)-0.5;
    vec2 fd = floor(f+.5*checkSize)-.5;
    
    float d2 = p.y + 1.;
    if(d2<res.x) {
        res = vec2(d2,3.);
        g_hitPoint=p;
    }

    float d4 = sdBox(vec3(f.x,p.y+1.1,f.y),vec3(.245,.15,.245));
    d4 = min(sdBox(vec3(f.x,p.y+1.1,f.y),vec3(.145,.2,.145)),d4);
    
    if(d4<res.x) {
          res = vec2(d4,3.);
        g_hitPoint=p;
    }
    
    float d5 = sdBox(vec3(f.x,p.y+1.1,f.y),vec3(.05,.85,.05));
    if(d5<res.x) {
          res = vec2(d5,4.);
        g_hitPoint=p;
    }

    float d = metaballs(q+vec3(0,.35,0));
    if(d<res.x) {
        res = vec2(d/2.1,2.);
        g_hitPoint=q;
    }
    
    return res;
}

vec2 raymarcher(vec3 ro, vec3 rd, int maxsteps){
    float d = 0.;
    float m = -1.;
    for(int i=0;i<maxsteps;i++){
        vec2 t = map(ro + rd * d);
        if(abs(t.x)<d*min_dist||d>max_dist) break;
        d += i<48 ? t.x*.25 : t.x * .95;
        m  = t.y;
    }
    return vec2(d,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t){
    float h = t * min_dist;
    #define ZERO (min(frames,0))
    vec3 n = vec3(0.0);
    for(int i=ZERO; i<4; i++) {
        vec3 e = 0.5773*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.);
        n += e*map(p+e*h).x;
    }
    return normalize(n);
}

vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 cf = normalize(lp - ro),
         cr = normalize(cross(vec3(0,1,0),cf)),
         cu = normalize(cross(cf,cr)),
         c  = ro + cf *.95,
         i  = c + uv.x * cr + uv.y * cu,
         rd = i - ro;
    return rd;
}

vec4 getCheck(vec3 pos){
    vec3 p = pos;
    vec3 marbleAxis,board,vein;
    vec2 f=fract(p.xz*checkSize)-0.5;

    board = check2;
    vein = check3;
    marbleAxis = normalize(vec3(1,2,3));
    
    if (f.x*f.y>0.) {
        board = check1;
        vein = check2;
        marbleAxis = normalize(vec3(1,-3,2));  // move normalize out
    } 
          
    vec3 mfp = (p + dot(p,marbleAxis)*marbleAxis*2.0)*2.0;
    float marble = 0.0;
    marble += abs(noise(mfp.xz)-.5);
    marble += abs(noise(mfp.xz*2.0)-.5)/2.0;
    marble += abs(noise(mfp.xz*4.0)-.5)/4.0;
    marble += abs(noise(mfp.xz*8.0)-.5)/8.0;
    marble /= 1.5-1.5/8.0;
    marble = pow(1.0-clamp(marble,0.0,1.0),15.0); // curve to thin the veins
    return vec4(mix( board, vein, marble ), marble);
}
 

vec3 getSpec(vec3 p, vec3 n, vec3 l, vec3 ro) {
    vec3 spec = vec3(0.);
    float strength = 0.75;
    vec3 view = normalize(p - ro);
    vec3 ref = reflect(l, n);
    float specValue = pow(max(dot(view, ref), 0.), 32.);

    return spec + strength * specValue;
}

// softshadow www.pouet.net
// http://www.pouet.net/topic.php?which=7931
float softshadow( vec3 ro, vec3 rd, float mint, float maxt, float k ){
    float res = 1.0;
    for( float t=mint; t < maxt; ){
        float h = map(ro + rd*t).x;
        if( h<0.001 ) return 0.2;
        res = min( res, k*h/t );
        t += h;
    }
    return res+0.2;
}

float getDiff(vec3 p, vec3 n, vec3 l) {    
    return clamp(dot(n,l),.01 , 1.);
}

vec3 getColor(float m) {   
    vec3 h = vec3(.5);
    if(m==2.) h = vec3(.7,.735,.75);
    if(m==1.) h = hsv(s_hash,1.,.5);
    if(m==3.) h = getCheck(s_hitPoint).xyz;  
    return h;
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ){ need changing to glFragColor and gl_FragCoord.xy
    isosurfacelevel=1.+.51*sin(T*.2);

    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 C = vec3(0.08),
         FC =  vec3(.43,.44,.445);
    
    vec3 lp = vec3(0.,0.25,0.),
         ro = vec3(1.5,.5,2.5);
    
    vec3 rd = camera(lp,ro,uv);
    vec2 t = raymarcher(ro,rd, 256);
    s_hitPoint=g_hitPoint;
    s_hash= g_hash;

    if(t.x<max_dist){
        vec3 p = ro + rd * t.x;
        vec3 n = getNormal(p, t.x);
        vec3 lpos = vec3(2.5,12.5, 11.25);
        vec3 l = normalize(lpos);
        float shadow = softshadow( p + n * min_dist, l, .1, 128., 32. );
        
        float diff = clamp(dot(n,l),.01 , 1.);
        vec3 h = getColor(t.y);
        C+= diff * (h * shadow);

        if(t.y>0. && t.y!=15.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = raymarcher(p ,rr, 192);
            s_hitPoint=g_hitPoint;
            s_hash= g_hash;
            
            if(tr.x<max_dist){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                l = normalize(lpos);
                diff = clamp(dot(n,l),.01 , 1.);
                shadow = softshadow( p + n * min_dist, l, .1, 86., 32. );
                h = getColor(tr.y);
                C+=(diff * (h * shadow))*.5;
                
                //comment out block to speed up
                if(t.y>0. && tr.y!=15.){
                    rr=reflect(rr,n); 
                    tr = raymarcher(p ,rr, 128);
                    s_hitPoint=g_hitPoint;
                    s_hash= g_hash;
                    
                    if(tr.x<max_dist){
                        p += rr*tr.x;
                        n = getNormal(p,tr.x);
                        l = normalize(lpos);
                        diff = clamp(dot(n,l),.01 , 1.);
                        shadow = softshadow( p + n * min_dist, l, .1, 64., 32. );
                        h = getColor(tr.y);
                        C+=(diff * (h * shadow))*.4;
                    }  
                }
                //comment out block to speed up
            }  
        }
    }
 
    C = mix( C, FC, 1.-exp(-.00015*t.x*t.x*t.x));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
