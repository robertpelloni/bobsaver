#version 420

// original https://www.shadertoy.com/view/Dt3XR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #024
    05/25/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 
    
    glintz based off @tachyonflux https://www.shadertoy.com/view/ll2fzt

*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI         3.141592653
#define PI2        6.283185307

#define MAX_DIST    50.
#define MIN_DIST    1e-4

#define AA 2

// globals
vec3 hit,hitPoint;
float spd=.3;

// constants
const float size = 1.85;
const float hlf = size*.5;

vec2 hash2( vec2 p ){ return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453); }
float hash21(vec2 p){return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453);}
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

//@iq extrude
float opx(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

vec2 map(vec3 pos){
    vec2 res = vec2(1e5,0);
    pos.x-=spd;
    
    vec2 uv = pos.xz;
    
    vec2 id = floor(uv*size);
    float rnd = hash21(id);
    
    float chk = mod(id.y+id.x,2.)*2.-1.;
    vec2 q = fract(uv*size)-.5;
    if(rnd>.5) q.x=-q.x; 

    vec2 cv = vec2(length(q-.5),length(q+.5));
    vec2 p = cv.x<cv.y?q-.5:q+.5;
    
    float thc = .05+.045*sin(pos.x*1.63);
          thc+= .05+.045*sin(pos.z*2.47);
    
    float k = length(p)-.5;k = abs(k)-thc;
    
    if(chk>.5) { 
        float tk = length(abs(q.x)-(thc*1.55))-(thc*.55);
        k = max(min(length(q.x)-thc,length(q.y)-thc),-tk);
    }

    float d = opx(k,pos.y,.85*thc)-.01;
    if(d<res.x) {
        res = vec2(d,2.);
        hit=vec3(q.x,pos.y,q.y);
    }

    float gnd = pos.y+.01;
    float gnt = d-.05;
    if(gnd<res.x) {
        res = vec2(gnd,gnt<gnd?3.:1.);
        hit=pos;
    }

    return res;
}

// Tetrahedron technique @iq
// https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

// reduced voronoi based off @iq
// https://www.shadertoy.com/view/ldl3W8
vec3 voronoi( in vec2 x) {
    vec2 n = floor(x), f = fract(x);
    vec2 mg, mr;
    float md = 8.,ox = 0.;
    for( float j=-1.; j<=1.; j++ )
    for( float i=-1.; i<=1.; i++ )
    {
        vec2 g = vec2(i,j);
        vec2 o = hash2( n + g );
        vec2 r = g + o - f;
        float d = dot(r,r);
        if( d<md ){
            md = d;
            mr = r;
            mg = g;
        }
    }
    md = 8.;
    vec2 o = hash2( n + mg );
    ox = o.x;
    return vec3(md,ox,mr.x);
}

vec3 vor3D(in vec3 p, in vec3 n ) {
    n = max(abs(n), MIN_DIST);
    n /= dot(n, vec3(1));
    vec3 tx = voronoi(p.yz).xyz;
    vec3 ty = voronoi(p.zx).xyz;
    vec3 tz = voronoi(p.xy).xyz;
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}

vec3 glintz( vec3 lcol, vec3 pos, vec3 n, vec3 rd, vec3 lpos) {
    vec3 mate = vec3(0);
    vec3 h = normalize(lpos-rd);

    float nh = abs(dot(n,h)), nl = dot(n,lpos);
    vec3 light = lcol*max(.0,nl)*1.5;
    vec3 coord = pos*1.5, coord2 = coord;

    vec3 ww = fwidth(pos),glints=vec3(0),tcoord;
    float pw,q,anisotropy;

    for(int i = 0; i < 2;i++) {
        if( i==0 ) {
            anisotropy=.55;
            pw=R.x*.20;
            tcoord=coord;
        } else {
            anisotropy=.62;
            pw=R.x*.10;
            tcoord=coord2;
        }

        vec3 aniso = vec3(vor3D(tcoord*pw,n).yy, vor3D(tcoord.zyx*vec3(pw,-pw,-pw),n).y)*1.-.5;
        if(i==0) {
            aniso -= n*dot(aniso,n);
            aniso /= min(1.,length(aniso));
        }

        float ah = abs(dot(h,aniso));
        if( i==0 ) {
            q = exp2((1.15-anisotropy)*2.5);
            nh = pow( nh, q*4.);
            nh *= pow( 1.-ah*anisotropy, 10.);
        } else {
            q = exp2((.1-anisotropy)*3.5);
            nh = pow( nh, q*.4);
            nh *= pow( 1.-ah*anisotropy, 150.);
        }     

        glints += (lcol*nh*exp2(((i==0?1.25:1.)-anisotropy)*1.3))*smoothstep(.0,.5,nl);
    }
    float fresnel = mix(0.,.95,pow(1.+dot(n,rd),2.));
    return mix(light*vec3(0.3),vec3(.5),fresnel)+glints+lcol *.3;
}
mat2 rx,ry;

vec3 renderFull( vec2 uv )
{

    vec3 ro = vec3(0,0,2.);
    vec3 rd = normalize(vec3(uv,-1.));
    
    // mouse //
    ro.xz*=ry;ro.zy*=rx;
    rd.xz*=ry;rd.zy*=rx;

    float d = 0.,m = 0.;
    vec3 color = vec3(0), n = vec3(0),p = vec3(0);
    
    // marcher
    for(int i=0;i<100;i++)
    {
        p = ro + rd * d;
        vec2 ray = map(p);
        if(abs(ray.x)<MIN_DIST*d||d>MAX_DIST)break;
        d += i<32? ray.x*.4: ray.x*.9;
        m  = ray.y;
    } 
    
    hitPoint=hit;
    
    if (d < MAX_DIST) 
    {
        vec3 n = normal(p, d);
        vec3 lpos =vec3(8,0,8)+vec3(8.*sin(time*.45),12,6.*cos(time*.45));
        vec3 l = normalize(lpos-p);
        float diff = clamp(dot(n,l),.05,1.);
        
        //shadows
        float shdw = 1.;
        for( float t=.01; t < 12.; ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 12.*h/t);
            t += h;
            if( shdw<MIN_DIST ) break;
        }
        diff = mix(diff,diff*shdw,.65);
        float spec = .75 * pow(max(dot(normalize(p-ro),reflect(l,n)),.0),24.);
        vec3 h = vec3(0);
        
        if(m==3.) h = vec3(.0,.08,.16)*diff;
        if(m==1.){
            float mp = fract((p.x-spd-p.z)*2.);
            float sw = smoothstep(.76,.77,sin(mp)*.5+.5);
            vec3 cr = mix(vec3(0,.5,1),vec3(.95),sw);
            vec3 hp = mix(hitPoint*.05,(p-vec3(spd,0,0))*.1,sw);
            h = glintz(cr,hp, n, rd, l)*diff+spec;
        }
        if(m==2.){
            float mp = clamp(sin(p.z+.75)*.5+.4,0.,1.);
            h = glintz(vec3(.95), hitPoint*.3, n, rd, l)*diff+spec;
        }
        color = h;
    }

    return color;
}

float vmul(vec2 v) {return v.x * v.y;}

void main(void) { //WARNING - variables void (out vec4 O, in vec2 F) {  need changing to glFragColor and gl_FragCoord.xy

    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    //  precal //
    vec3 col = vec3(0); 
    spd = time*.15;

    float x = 0.;
    float y = 0.;

    rx = rot(x-1.1);
    ry = rot(y-.1*sin(time*.02));
       
    vec2 o = vec2(0);

    // AA and motion blur from iq https://www.shadertoy.com/view/3lsSzf
    // set AA above renderFull
    #ifdef AA
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        o = vec2(float(m),float(n)) / float(AA) - 0.5;
    #endif
        vec2 p = (-R.xy + 2. * (F + o)) / R.x;
        col += renderFull(p);
    #ifdef AA
    }
    col /= float(AA*AA);
    #endif

    col = pow( col, vec3(0.4545) );

    O = vec4(col, 0);
    
    glFragColor=O;
}
