#version 420

// original https://www.shadertoy.com/view/7d3XRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Ghostsssss
    10/09/21 @byt3_m3chanic
    
    Again we're just moving one domain / then loops
    but I'm making the ID's advace using floor(T*.1)
    which matching the timing for the loop movement.

    I started doing this to prevent artifacts that 
    seem to distort the more you move a scene with time
    / distance or large values.
    
    Just playing - like the ghost from a previous
    shader / anisiotropic effects for glitter and
    some transparency / refraction.
    
    thanks @blackle / @iq / @tachyonflux

*/

#define R             resolution
#define T             time
#define M             mouse*resolution.xy

#define PI          3.14159265358
#define PI2         6.28318530718

#define MAX_DIST    100.

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
float eoc(float t) { return (t = t - 1.0) * t * t + 1.0; }

//@iq sdf shapes    
float box( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float cap( vec3 p, float r,float h ){
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float torus( vec3 p, vec2 t ){
  vec2 q = vec2(length(p.yx)-t.x,p.z);
  return length(q)-t.y;
}

float vcap( vec3 p, float h, float r ){
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float sunion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

// globals
vec3 hit,hitPoint;
vec2 gid,sid;
mat2 r45,rn45,r25,turn;
float tmod=0.,ga1=0.,ga2=0.,ga3=0.,ga4=0.,ga5=0.,glow=0.;

float eyes(vec3 p) {
    float res = 1e5;
    vec3 q = p-vec3(0,.5,0);
    vec3 e1 = vec3(abs(q.x),q.yz);

    float eye = length(e1-vec3(.57,.65,.8))-.15;
    if(eye<res) {
        res = eye;
    } 
    glow += smoothstep(.1,.25,.003/(.0145+eye*eye)); 
    return res;
}

float ghost(vec3 p, float hs) {
    float res = 1e5;
    vec3 q = p-vec3(0,-1.25,0);
    
    vec3 q2=q-vec3(0,1.5,.25);
    vec3 q3=vec3(abs(q.x),q.yz)-vec3(.5,2.72,1.25);
    vec3 q4 = q-vec3(0,2.72,1.65);
    q4.x=abs(q4.x);q4.xz*=r25;
    
    float ghst = vcap(q,2.75,1.6);
    float eyes = length(q3)-.45;
    float lids = torus(q4-vec3(.53,0,0),vec2(.4,.05));
    float chst = vcap(q,2.7,1.25);

    float a = atan(q.z,q.x);
    float tw = .2*sin(a*6.);
    tw *=pow(length(q.xz),1.);
    
    float cuting = cap(q+vec3(0,1.,0),1.-tw,1.65)*.75;
    
    ghst = max(ghst,-cuting);
    ghst = max(ghst,-eyes);
    ghst = sunion(lids,ghst,.08);
    ghst = max(ghst,-chst);
    
    if(ghst<res ) {
        res = ghst;
    }

    return res;
}

const float size = 6.;
const float hlf = size/2.;
const float blx = hlf*.95;
const float hlx = hlf*.825;
const float dbb = size*4.;

vec2 map(vec3 p){
    vec2 res = vec2(1e5,0.);
    vec3 q = p;
    
    //prevent scene from moving
    //just having ID's change
    if(ga4>0.) q.z+=ga4*dbb;
    vec3 tq = q;
    tq.z+=floor(T*.1)*dbb;
    
    vec2 id = floor((tq.xz+hlf)/size);

    q.xz=mod(q.xz+hlf,size)-hlf;
    float hs = hash21(id+floor(T*.1));

    float th = .7;
    float ofs = ga2*10.;
    vec3 q4 = q+vec3(0,6.85,0);

    float tile = box(q4,vec3(blx,5.1,blx))-.125;
    if(ga1>0.&&hs>th) {
        tile=max(tile,-(length(q4.xz)-(hlx*(ga1-ga3))) );
    }
    
    if(tile<res.x) {
        res = vec2(tile,2.);
        hitPoint=q4;
        gid=id;
    } 

    float mof = hs*3.+T*hs;
    q.xz*=rot(hs*36.);
    float hp = .6*sin(T*3.+mof);
    
    vec3 q2=q-vec3(.1*sin(q.x+T*3.5),-7.7+ofs+hp,.6+.15*cos(q.x+T*2.5));
    vec3 q1=q-vec3(0,-8.+ofs+hp,0);

    float ghst = hs>th?ghost(q1,hs):1.;
    if(ghst<res.x && (p.y>-3.75)) {
        res = vec2(ghst,1.);
        hitPoint=q1;
    }  

    float brain = hs>th?eyes(q2):1.;
    if(brain<res.x && (p.y>-3.75)) {
        res = vec2(brain,4.);
        hitPoint=q2;
    } 

    return res;
}

//Tetrahedron technique
//https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p, float t, float mindist) {
    float e = mindist*t;
    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

// cheap hash noise
vec3 vor3D(in vec3 p, in vec3 n ){
    n = max(abs(n), .001);
    n /= dot(n, vec3(1));
    float tx = hash21(floor(p.xy));
    float ty = hash21(floor(p.zx));
    float tz = hash21(floor(p.yz));
    return vec3(tx*tx, ty*ty, tz*tz)*n;
}

// glintz adapted and redux - original @tachyonflux
// https://www.shadertoy.com/view/ll2fzt
vec3 glintz( vec3 lcol, vec3 hitPoint, vec3 n, vec3 rd, vec3 lpos) {
    vec3 mate;
    vec3 pos = hitPoint;
    
    vec3 h = normalize(lpos-rd);
    float nh = abs(dot(n,h)), nl = dot(n,lpos);
    vec3 light = lcol*max(.0,nl)*1.5;
    vec3 coord = pos*1.5, coord2 = coord;

    vec3 ww = fwidth(pos);
    vec3 glints=vec3(0);
    
    for(int i = 0; i < 2;i++) {
        float pw = i==0?.20*R.x:.10*R.x;
        vec3 tcoord = i==0?coord:coord2;
        vec3 aniso = vec3(vor3D(2.-tcoord*pw,n).yy, vor3D(3.-tcoord.zyx*pw,n).y)*1.0-.5;
        if(i==0) {
            aniso -= n*dot(aniso,n);
            aniso /= min(1.,length(aniso));
        }
        float anisotropy = i==0?.55:.6;
        float ah = abs(dot(h,aniso));
        float q = exp2(((i==0?1.15:.1)-anisotropy)*1.5);
        nh = pow( nh, q*(i==0?4.:.4) );
        nh *= pow( 1.-ah*anisotropy, i==0?10.:150. );
        glints += 
        (lcol*nh*exp2(((i==0?1.2:1.)-anisotropy)*1.3))*smoothstep(.0,.5,nl);
    }

    float fresnel = pow(1.0 + dot(n,rd), 2.0);
    fresnel = mix( 0.0, 0.95, fresnel );

    vec3 reflection = vec3(0);
    return 
        mix(light*vec3(0.3), reflection, fresnel) +
        glints +
        reflection*0.015*(clamp(nl,0.,1.))+ reflection*0.05 +
        lcol * .3;
}

//@iq https://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 hue(float t){ 
    vec3 c = vec3(0.953,0.929,0.886),
         d = vec3(0.553,0.227,0.949);
    return vec3(.35) + vec3(.25)*cos( PI*(c*t+d) ); 
}

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n) {
    n = normal(p,d,1.001);
    float csx = 17.*sin(T*.35);
    vec3 lpos = vec3(0,25,0);
    vec3 l = normalize(lpos-p);

    float diff = clamp(dot(n,l),0.,1.);
    float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.5);
    fresnel = mix(.01, .7, fresnel);

    vec3 h = vec3(.5);

    if(m==1.) h=glintz(hue(55.323+hash21(sid+2.))*.5, hit*.075, n, rd, l);
    if(m==2.) {
        float chk = mod(sid.y+sid.x,2.)*2.-1.;
        vec3 clr = chk>.5?vec3(0.282,0.082,0.337):hue(sid.y+sid.y);
        clr=mix(clr,vec3(.1),hit.y<4.55?clamp(.5-(hit.y-3.55)*.5,0.,1.):0.);
        h=glintz(clr, hit*.075, n, rd, l);
    }

    return h;
}

void main(void) {

    vec2 F = gl_FragCoord.xy;

    vec3 C=vec3(.0);
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);

    // precal all your vars!
    r25=rot(-.28);
    float time = T;
    
    tmod = mod(time, 10.);
    float t1 = lsp(0.5, 1.0, tmod);
    float t2 = lsp(7.5, 8.0, tmod);
    
    float t3 = lsp(1.0, 1.5, tmod);
    float t4 = lsp(6.5, 7.5, tmod);
    
    float t5 = lsp(1.5, 2.5, tmod);
    float t6 = lsp(5.5, 6.5, tmod);
    
    float t7 = lsp(8.0,10., tmod);
    
    ga1 = eoc(t1-t2);
    ga1 = ga1*ga1*ga1;
    
    ga2 = eoc(t3-t4);
    ga2 = ga2*ga2*ga2;
    
    ga3 = eoc(t5-t6);
    ga3 = ga3*ga3*ga3;
    
    ga4 = eoc(t7);
    ga4 = ga4*ga4*ga4;

    //zoom slice per uv.x
    float dz = .38+.18*sin(uv.y*2.3+T);
    //zoom levels
    float zoom = 14.;
    if(uv.x> dz) zoom=21.;
    if(uv.x<-dz) zoom=42.;
    
    vec3 ro = vec3(uv*zoom,-zoom-15.);
    vec3 rd = vec3(0,0,1.);
    
    // mouse
    float y = 0.0; //M.xy == vec2(0) ? 0. :  (M.x/R.x * 2. - 1. ) * PI;

    mat2 rx =rot(.485);
    mat2 ry =rot(-2.45+y-T*.125);
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;
    
    vec3  p = ro + rd * .1;
    float atten = 1.;
    float k = 1.;
    
    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    for(int i=0;i<200;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float fresnel=0.;
        float d = ray.x * .7;
        float m = ray.y;

        p += rd * d *k;
        
        if (d*d < 1e-8) {
            hit=hitPoint;
            sid=gid;
            C+=shade(p,rd,d,ray.y,n)*atten;
            if(m==2.) break;
            
            atten *= .65;
            p += rd*.1;
            k = sign(map(p).x)*.9;
            
            fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 9.);
            fresnel = mix(.0, .9, fresnel);

            vec3 rr = refract(rd,n,.8);
            rd=mix(rr,rd,.5-fresnel);
  
        }  
        if(distance(p,rd)>80.) { break; }
    }
    
    float glowMask = clamp(glow,.0,1.);
    C = mix(C,vec3(0.145,0.659,0.914)*glow,glowMask);
    float px = fwidth(uv.x);
    if(uv.x<px-dz&& uv.x>-(dz+px)) C = vec3(1);
    if(uv.x>(dz-px)&& uv.x<(dz+px)) C = vec3(1);
    C=clamp(C,vec3(0),vec3(1));
    
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1.0);
}

//end
