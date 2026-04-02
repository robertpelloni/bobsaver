#version 420

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R        resolution
#define M        mouse
#define T        time
#define PI          3.1415926
#define PI2         6.2831853

#define MINDIST         .001
#define MAXDIST         175.

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hash(a, b) fract(sin(a*1.2664745 + b*.9560333 + 3.) * 14958.5453)

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

// globals and stuff
float glow, ga1,ga2,ga3,ga4,ga5,ga6;
mat2 rTm,r27,r28;

float gragtail(vec3 pos, float z, int lps) {
    float scale = 2.85;

     vec3 cxz =vec3(
        3.45-ga1-ga2,
        3.25-ga3-ga4,
        3.+ga5
    );

    float r = length(pos);
    float t = 0.0;
    float ss= .99;
    pos.z = abs(pos.z)-3.;
    for (int i = 0;i<3;i++) {
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
     vec2 res = vec2(100.,-1.);
    //pos.xz*=r2(T*.05);
    pos.xz+=12.5;
    pos.x+=T*12.5;
    float size = 25.;
    vec3 id =floor((pos + size*0.5)/size);
    float hs = hash(id.x,id.z);
    float ff;
    if (hs>.9) {
        ff = ga1;
    } else if(hs>.75) {
        ff = ga1+ga2;
    } else if(hs>.5) {
        ff = ga1+ga2;
    } else if(hs>.25){
        ff = ga3+ga4;
    } else {
        ff = ga5+ga6;
    } 
    
    hs += .5;
    vec3 q = pos-vec3(0.,(size*ff*hs),0.);

    pMod(q,vec3(size,20.,size));
    pModPolar(q.xz,4.);
    pMirrorOctant(q.zy, vec2(2.15, 3.),0. );

    float d1 = gragtail(q,1.,3);
    if(d1<res.x)  res = vec2(d1,3.);
     return res;
}

vec2 marcher(vec3 ro, vec3 rd, float sg,  int maxstep){
    float d =  .0,
           m =  -1.;
        for(int i=0;i<192;i++){
            vec3 p = ro + rd * d;
            vec2 t = map(p, sg);
            if(abs(t.x)<d*MINDIST||d>MAXDIST)break;
            d += t.x*.95;
            m  = t.y;
        }
    return vec2(d,m);
}

vec3 getNormal(vec3 p, float t){
    float e = t*MINDIST;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e, 0.).x + 
                      h.yyx*map( p + h.yyx*e, 0.).x + 
                      h.yxy*map( p + h.yxy*e, 0.).x + 
                      h.xxx*map( p + h.xxx*e, 0.).x );
}

vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 f=normalize(lp-ro),
         r=normalize(cross(vec3(0,1,0),f)),
         u=normalize(cross(f,r)),
         c=ro+f*.75,
         i=c+uv.x*r+uv.y*u,
         rd=i-ro;
    return rd;
}

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

void main( ) {
    // precal for ship
    rTm = r2(T*.5);
    r27 = r2(-42.*PI/180.);
    r28 = r2(37.*PI/180.);
    // pixel screen coordinates
    vec2 uv = (gl_FragCoord.xy - R.xy*0.5)/R.y;
    vec3 C = vec3(0.);
    vec3 FC = vec3(.05);

    float tf = mod(T, 12.);
    // move x steps in rotation
    float t1 = linearstep(0.0, 1.0, tf);
    float t2 = linearstep(2.0, 3.0, tf);
    float a1 = easeInCubic(t1);
    float a2 = easeOutCubic(t2);
    
    float t3 = linearstep(4.0, 5.0, tf);
    float t4 = linearstep(5.0, 6.0, tf);
    float a3 = easeInCubic(t3);
    float a4 = easeOutCubic(t4);
    
    float t5 = linearstep(7.0, 8.0, tf);
    float t6 = linearstep(9.0, 10.0, tf);
    float a5 = easeInCubic(t5);
    float a6 = easeOutCubic(t6);

    float t7 = linearstep(11.0, 12.0, tf);
    float a7 = easeInCubic(t7);
    
    ga1 = (a1-a3);ga2 = (a2-a4);
    ga3 = (a5-a7);ga4 = (a2-a5);
    ga5 = (a4-a6);ga6 = (a7-a2);

    vec3 lp = vec3(0.,0.,0.);
    vec3 ro = vec3(0.,1.,2.5);

    vec3 rd = camera(lp,ro,uv);

    vec2 t = marcher(ro,rd, 1., 192);
    float d = t.x,
          m = t.y;
    vec3 h = gethue(d*.1);

    if(d<MAXDIST){
        vec3 p = ro + rd * d;
        vec3 nor = getNormal(p,d);
        vec3 li =  normalize(vec3(0,1,1));
        vec3 col = vec3(.07,.09,.08)*.1;
        
        col *= pow(1.-d*.1,2.); 
        col *= clamp(dot(nor,li),.3,.8);
        col *= max(1.5+.75*nor.y,0.);
        
        float rimd = pow(clamp(1.-dot(reflect(-li,nor),-rd),.0,1.),2.5);
        col += pow(clamp(dot(reflect(normalize(p-ro),nor),li),0.,1.),1.);

        float ao = calcAO(p,nor);
        C += col * h * ao;
        
    } else {
         C =  vec3(.6);
    }
    C = mix( C, FC, 1.-exp(-.0000025*d*d*d));
    C = mix( C, vec3(1), glow);
 
    glFragColor= vec4(pow(C, vec3(0.4545)),1.0);
}
