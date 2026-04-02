#version 420

// original https://www.shadertoy.com/view/3dGcRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define PI          3.1415926
#define PI2         6.2831853

#define MINDIST     .001
#define MAXDIST     175.

/**
    Column Sorting Fractals | pjkarlik
    
    Interpretation or stuff seen online and mostly from @FMS_Cats
    Shader Royale 2020 work (https://www.shadertoy.com/view/wsccWj)
    Simple mod domain rep / with moving based on hash - linear timing
    functions which give it that spin.

*/

#define PI          3.1415926
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//Functions used modified from http://mercury.sexy/hg_sdf/

float vmax(vec2 v) {  return max(v.x, v.y);  }
float vmax(vec3 v) {  return max(max(v.x, v.y), v.z);  }
float sgn(float x) {  return (x<0.)?-1.:1.;  }
vec2 sgn(vec2 v)   {  return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);  }

vec3 pMod(inout vec3 p, vec3 size) {
    vec3 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5, size) - size*0.5;
    return c;
}

float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*length(p);
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}
float pMirror (inout float p, float dist) {
    p = abs(p)-dist;
    return sgn(p);
}
vec2 pMirrorOctant (inout vec2 p, vec2 dist, float r) {
    pMirror(p.x, dist.x);
    pMirror(p.y, dist.y);
    p*=r2(r);
    if (p.y > p.x) p.xy = p.yx;
    return sgn(p);
}

float fBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

float linearstep(float begin, float end, float t) {  return clamp((t - begin) / (end - begin), 0.0, 1.0);  }
float easeOutCubic(float t) {  return (t = t - 1.0) * t * t + 1.0;  }
float easeInCubic(float t) {  return t * t * t;  }

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

void getMouse(inout vec3 ro) {
    float x = 0.0;//M.xy == vec2(0) ? 0. : -(M.y/R.y * 1. - .5) * PI;
    float y = 0.0;//M.xy == vec2(0) ? 0. : (M.x/R.x * 1. - .5) * PI;
    ro.zy *=r2(x);
    ro.xz *=r2(y);  
}

// globals and stuff
float ga1,ga2,ga3,ga4,ga5,ga6;

float gragtail(vec3 pos, float z, int lps) {
    float scale = 2.85;

     vec3 cxz =vec3(
        3.45,
        3.25,
        3.
    );

    float r = length(pos);
    float t = 0.0;
    float ss= .99;
    pos.z = abs(pos.z)-3.;
    for (int i = 0;i<lps;i++) {
        pos=abs(pos);

        if ( pos.x- pos.y<0.) pos.yx = pos.xy;
        if ( pos.z- pos.x<0.) pos.zx = pos.xz;
        if ( pos.y- pos.z<0.) pos.zy = pos.yz;
        
        pos.x=scale * pos.x-cxz.x*(scale-1.);
        pos.y=scale * pos.y-cxz.y*(scale-.5);
        pos.z=scale * pos.z;

        if (pos.z>.0) pos.z-=cxz.z*(scale-1.5);

        r =  fBox2(abs(pos.xy)-vec2(25.,10.),vec2(10., 20.));
        r = min(fBox2((pos.yz)-vec2(12.,8.),vec2(5., 3. )),r);
        
        ss*=1./scale;

    }
    return r*ss;
}

vec2 map (in vec3 pos, float sg) {

     vec2 res = vec2(1000.,-1.);
    pos.xy*=r2(T*.2);
    
    float k = 8.0/dot(pos,pos); 
    pos *= k;

    pos.xz+= 12.5;
    pos.z+=T*12.5;
    float hght = 20.;
    float size = 26.;
    vec3 id =floor((pos + size*0.5)/size);
    float hs = hash21(id.xz)+.1;
    float ff = (hght*hs);
   
    if (hs>.7) {
        ff += ga1;
    } else if(hs>.6) {
        ff += ga2;
    } else if(hs>.5) {
        ff += ga3;
    } else if(hs>.4){
        ff += ga4;
    } else if(hs>.3){
        ff += ga5;
    } else if(hs>.2){
        ff += ga6;
    } else if(hs>.1){
        ff += ga4-ga3;
    } else {
        ff += ga2-ga1;
    } 

    
    float zid = hs>.6?T*ff:-(T*ff);
    vec3 q = pos-vec3(0.,zid, 0. );

    pMod(q,vec3(size,hght,size));
    pModPolar(q.xz,4.);
    pMirrorOctant(q.zy, vec2(2.15, 3.), ff);

    float d1 = gragtail(q,zid,3);
    if(d1<res.x )  res = vec2(d1,3.);

    float mul = 1.0/k;
    res.x *=  mul / 1.36;
     return res;
}

vec2 marcher(vec3 ro, vec3 rd, float sg,  int maxstep){
    float d =  .0,
           m =  -1.;
        int i = 0;
        for(i=0;i<maxstep;i++){
            vec3 p = ro + rd * d;
            vec2 t = map(p, sg);
            if(abs(t.x)<d*MINDIST||d>MAXDIST)break;
            d += t.x*.95;
            m  = t.y;
        }
    return vec2(d,m);
}

// https://www.iquilezles.org/www/articles/normalsSDF
vec3 getNormal(vec3 p, float t){
    float e = t*MINDIST;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e, 0.).x + 
                      h.yyx*map( p + h.yyx*e, 0.).x + 
                      h.yxy*map( p + h.yxy*e, 0.).x + 
                      h.xxx*map( p + h.xxx*e, 0.).x );
}

//camera setup
vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 f=normalize(lp-ro),
         r=normalize(cross(vec3(0,1,0),f)),
         u=normalize(cross(f,r)),
         c=ro+f*.65,
         i=c+uv.x*r+uv.y*u,
         rd=i-ro;
    return rd;
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<4; i++ ){
        float hr = float(i + 1)*.25/5.; 
        float d = map(p + n*hr, 0.).x;
        occ += (hr - d)*sca;
        sca *= .9;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 gethue(float a){ return .65 + .45*cos((PI2*a) + vec3(3.75,1.45, .75)); }

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy

    // pixel screen coordinates
    vec2 uv = (gl_FragCoord.xy - R.xy*0.5)/R.y;
    vec3 C = vec3(0.);
    vec3 FC = vec3(.05);
    
    // timing functions
    float tf = mod(T*2.5,13.);
    // move x steps in rotation
    float t1 = linearstep(0.0, 2.0, tf);
    float t2 = linearstep(2.0, 4.0, tf);
    float a1 = easeInCubic(t1);
    float a2 = easeOutCubic(t2);
    
    float t3 = linearstep(3.0, 5.0, tf);
    float t4 = linearstep(5.0, 6.0, tf);
    float a3 = easeInCubic(t3);
    float a4 = easeOutCubic(t4);
    
    float t5 = linearstep(6.0, 7.0, tf);
    float t6 = linearstep(9.0, 11.0, tf);
    float a5 = easeInCubic(t5);
    float a6 = easeOutCubic(t6);

    float t7 = linearstep(11.0, 12.0, tf);
    float a7 = easeInCubic(t7);
    
    ga1 = (a1-a3);
    ga2 = (a2-a4);
    ga3 = (a3-a5);
    ga4 = (a4-a6);
    ga5 = (a5-a7);
    ga6 = (a6+a2);

    // render scene
    vec3 lp = vec3(0.,0.,0.);
    vec3 ro = vec3(0.,0.,.11);
    //getMouse(ro);
    vec3 rd = camera(lp,ro,uv);
    vec2 t = marcher(ro,rd, 1., 192);
    
    float d = t.x,
          m = t.y;
    vec3 h = gethue(d*10.01);//25.
    // if visible 
    if(d<MAXDIST){
        vec3 p = ro + rd * d;
        vec3 nor = getNormal(p,d);
        vec3 li =  normalize(vec3(0,1,1));
        vec3 col = vec3(.07,.09,.08)*.1;
        
        //@gaz https://www.shadertoy.com/view/WsKcR1
        col *= pow(1.-d*.1,2.); 
        col *= clamp(dot(nor,li),.3,.8);
        col *= max(1.5+.75*nor.y,0.);
        float rimd = pow(clamp(1.-dot(reflect(-li,nor),-rd),.0,1.),2.5);
        col += pow(clamp(dot(reflect(normalize(p-ro),nor),li),0.,1.),1.);
        //
        
        float ao = calcAO(p,nor);
        C += col * h * ao;
        
    } else {
         C =  vec3(.6);
    }
    C = mix( C, FC, 1.-exp(-100.*d*d));
    //C = mix( C, FC, 1.-exp(-.00025*d*d));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
