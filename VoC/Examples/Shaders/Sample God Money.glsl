#version 420

// original https://www.shadertoy.com/view/7tjSRd

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Was just was goofing around / text and isometric
    wasn't really intending to do much - but eh I made
    something.. 
    
    GOD | MONEY
    @byt3_m3chanic | 08/25/21

    God money, I'll do anything for you
    God money, just tell me what you want me to
    *Trent Reznor*

*/
#define R resolution
#define M mouse*resolution.xy
#define T time

#define PI  3.14159265359
#define PI2 6.28318530718

#define MIN_DIST .001
#define MAX_DIST 90.

//linear step timing function - book of shaders
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
//utils
mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }
//@iq 2Dbox functions and extrude
float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float box( in vec2 p, in vec2 b, in vec4 r ){
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}
float opx(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}
// letters and symbols
float getD(vec2 uv){
    float letd = box(uv,vec2(1.45,2.5),vec4(1.25,1.25,0,0));
    letd=abs(letd)-.5;
    letd=min(box(uv+vec2(1.45, .0),vec2(.5,3.)),letd);
    return letd;
}
float getG(vec2 uv){
    float letg = box(uv,vec2(1.45,2.5),vec4(1.25));
    letg=abs(letg)-.5;
    letg = max(letg,-box(uv-vec2(1., .5),vec2(1.25,.5)) );
    letg = min(box(uv-vec2(.95, -.25),vec2(1.,.5)),letg);
    return letg;
}
float getO(vec2 uv){
    float leto = box(uv,vec2(1.45,2.5),vec4(1.25));
    leto=abs(leto)-.5;
    return leto;
}
float getDl(vec2 uv){
    uv.x*=-1.;
    float letd = box(uv-vec2(.25,.75),vec2(1.,1.),vec4(.75,.75,0,0));
    letd = max(letd,-box(uv+vec2(.2,-.75),vec2(1.,.55),vec4(.35,.35,0,0)) );
    letd = min(box(uv+vec2(.25,.75),vec2(1.,1.),vec4(0,0,.75,.75)), letd );
    letd = max(letd,-box(uv+vec2(-.2,.75),vec2(1.,.55),vec4(0,0,.35,.35)) );
    letd = min(box(vec2(abs(uv.x),uv.y)-vec2(.35,.0),vec2(.15,2.25),vec4(0)), letd );
    return letd;
}
float getCr(vec2 uv){
    float letd = box(uv,vec2(.4,2.25));
    letd = min(letd,box(uv-vec2(0,.75),vec2(1.35,.4)));
    return letd;
}
//globals
mat2 r45,r21,turn;
vec3 hit,hitPoint;
vec2 gid,cellId;
float tmod=0.,ga1=0.,ga2=0.,ga3=0.,ga4=0.,ga5=0.,ga6=0.;
//size constants
const vec2 sc = vec2(.14), hsc = .5/sc; 

vec2 map(vec3 p) {
    vec2 res = vec2(1e5,0);
    vec3 p2 = p;
    p2.xz*=r21;
    p2-=.15*sin(p2.x*.4+T*3.);
    p2.z=abs(p2.z)-((ga3)*3.);
    float outline = 1e5;
    float lo = 1e5;
    outline = getG(p2.xy+vec2(5.,-.95));
    lo = min(opx(outline,p2.z,.75),lo);
    outline = getO(p2.xy-vec2(.0,.95));
    lo = min(opx(outline,p2.z,.75),lo);
    outline = getD(p2.xy-vec2(5.,.95));
    lo = min(opx(outline,p2.z,.75),lo);
    
    if(lo<res.x) {
        res = vec2(lo,3.);
        hit=p2;
        gid=vec2(0);
    }
    
    p.xz*=turn;
    p.y+=5.5;

    vec2 id = floor(p.xz*sc) + .5;    
    vec2 r = p.xz - id/(sc);

    float rnd = hash21(id);
    vec3 q = vec3(r.x,p.y,r.y);
    q.xz*=rot((ga5+1.)*rnd*PI2);
    q.xy*=rot((ga2*2.)*rnd*PI2);
    float b3 = getCr(q.xy);
    float b2 = getDl(q.xy);

    float b1 = opx(mix(b3,b2,ga5),q.z,.25);

    if(b1<res.x) {
        res = vec2(b1,2.);
        hit=p;
        gid=id;
    }

    float d9 = p.y+5.5;
    if(d9<res.x) {
        res = vec2(d9,1.);
        hit=p;
        gid=id;
    }
    return res;
}
// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 normal(vec3 p, float t, float mindist){
    float e = mindist*t;
    vec2 h = vec2(1.0,-1.0);
    return normalize( h.xyy*map( p + h.xyy*e).x + 
                      h.yyx*map( p + h.yyx*e).x + 
                      h.yxy*map( p + h.yxy*e).x + 
                      h.xxx*map( p + h.xxx*e).x );
}
//@iq https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 hue(float t){ 
    vec3 d = vec3(0.220,0.961,0.875);
    return .75 + .375*cos(.72*T+PI2*t*(vec3(.985,.98,.95)+d)); 
}

vec3 render(vec3 p, vec3 rd, vec3 ro, float d, float m, inout vec3 n){
    n = normal(p,d,1.01);
    vec3 lpos =  vec3(-4,20,-4);
    vec3 l = normalize(lpos-p);

    float diff = clamp(dot(n,l),0.,1.);

    float shdw = 1.;
    float t=.1;
    // i still havent found a good
    // soft shadow I like - or just
    // havent come across one yet..
    for( float i=.0; i<30.; i++ )
    {
        float h = map(p + l*t).x;
        if( h<MIN_DIST ) { shdw = 0.; break; }
        shdw = min(shdw, 12.*h/t);
        t += h*.8;
        if( shdw<MIN_DIST || t>55. ) break;
    }
    diff = mix(diff,diff*shdw,.35);

    vec3 h = vec3(0.800,0.961,0.929);
    //quad tree from my previous shader
    if(m==1.) {
        hitPoint*=sc.xxx;
        hitPoint.x+=ga4*2.;
        hitPoint.z+=ga1*2.;
        float px = .001;
        h = vec3(0.902,0.902,0.902);
        vec3 h3=hue(15.25);

        vec2 i = floor(hitPoint.xz);
        float rnd = hash21(i+vec2((date.z),2.));
        vec2 f = fract(hitPoint.xz)-.5;
        h3=hue(rnd*5.);
        //level 1
        if(rnd>.5){
            i = floor(f);
            rnd = hash21(i+rnd);
            f = fract(f*2.)-.5;
            h3=hue(rnd);
            //level 2
            if(rnd>.6){
                i = floor(f);
                rnd = hash21(i+rnd);
                f = fract(f*2.)-.5;
                h3=hue(rnd);
                //level 3
                if(rnd>.6){
                    i = floor(f);
                    rnd = hash21(i+rnd);
                    f = fract(f*2.)-.5;
                    h3=hue(rnd);
                    //level 4
                    if(rnd>.7){
                        i = floor(f);
                        rnd = hash21(i+rnd);
                        f = fract(f*2.)-.5;
                        h3=hue(rnd);
                    }
                }
            }
        }

        float cirx = length(f)-.485;
        float b3 = getCr(f.xy*6.);
        float b2 = getDl(f.xy*6.);
        float cir = mix(b3,b2,rnd>.35?1.:0.);
        cir=max(cirx,-cir);
        if(rnd>.5)cir=abs(cirx+.1)-.05;
        cir = smoothstep(-px,.01+px,cir);
        h=mix(h,hue(3.*rnd),1.-cir);
    } 
        
    if(m==2.) h = hue(hash21(cellId));

    if(m==3.) h = vec3(0.922,0.957,0.953);

    if(m==4.) h = vec3(0.475,0.824,0.773);

    return (h*diff);
}

float zoom = 16.;
void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;

    // precal all your vars
    //time = T;
    turn= rot(time*.1);
    tmod = mod(time, 10.);
    
    float t1 = lsp(3.0, 6.0, tmod);
    float t2 = lsp(7.0, 9.0, tmod);
    ga2 = (t1-t2);
    float t3 = lsp(0.0, 1.0, tmod);
    float t4 = lsp(5.0, 6.0, tmod);
    ga3 = (t3-t4);
    float t9 = lsp(1.0, 2.0, tmod);
    float t0 = lsp(8.0, 9.0, tmod);
    ga5 = (t9-t0);
    
    ga4 = (t4)+floor(time*.1);
    ga1 = (t1)+floor(time*.1);
    r21 = rot(ga3*PI2);
    // precal
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
  
    //orthographic camera
    vec3 ro = vec3(uv*zoom,-zoom);
    vec3 rd = vec3(0,0,1.);
    
    //.78539816339 = 45*PI/180
    mat2 rx = rot(-0.78539816339*ga5);
    mat2 ry = rot(ga2*0.78539816339);
    
    ro.yz *= rx;ro.xz *= ry;
    rd.yz *= rx;rd.xz *= ry;

    vec3 C = vec3(0);
    vec3  p = ro + rd;
    float atten = .85;
    float k = 1.;
    float d = 0.;
    for(int i=0;i<120;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float m = ray.y;

        d = ray.x * .85;
        p += rd * d *k;
        //@blackle transparent tricks
        if (d*d < 1e-7) {
            hitPoint = hit;
            cellId = gid;
            
            C+=render(p,rd,ro,d,ray.y,n)*atten;
            if(m==2.)break;
            
            atten *= .45;
            p += rd*.015;
            k = sign(map(p).x);

            vec3 rr = vec3(0);
            if(m==1.){
                rd=reflect(-rd,n);
                p+=n*.1;
            }else{
                float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 9.);
                fresnel = mix(.01, .9, fresnel);
                rr = refract(rd,n,.2);
                rd=mix(rr,rd,1.-fresnel);
            }
        } 
       
        if(distance(p,rd)>45.) { break; }
    }

    C = mix(C,C+.07,hash21(uv));
    C = clamp(C,vec3(.03),vec3(1));
    C = pow(C, vec3(.4545));
    O = vec4(C,1.0);

    glFragColor = O;
}
