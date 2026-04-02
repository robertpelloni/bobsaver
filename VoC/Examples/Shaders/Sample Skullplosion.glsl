#version 420

// original https://www.shadertoy.com/view/7ddXzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Skullsplosion
    10/10/21 @byt3_m3chanic
    
    'inbetween shader' shader - I ping between a few when stuck..
    so this was one from the head I made for inktober.

    truchet pattern kind of gives it a day of the dead thing
    which i'd like to explore.. 

*/

#define R            resolution
#define T            time
#define M            mouse*resolution.xy

#define PI2            6.28318530718
#define PI            3.14159265358

#define MAX_DIST     85.
#define MIN_DIST    .0001
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
float eoc(float t) { return (t = t - 1.0) * t * t + 1.0; }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }
mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float ellipse( vec3 p, vec3 r ) {
  float k0 = length(p/r),
        k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float box( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sunion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float ssub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

//globals and stuff
vec3 hit,hitPoint;
vec2 sid,gid;
mat2 r45,r22,r12,r32,turn,rpi,rnt;
float glow = 0.;

float shorten=1.,lpscale,xshrink;
float tmod,ga1,ga2,ga3,ga4,ga5,ddrim,ffrim;
const float density = 12.;
const float dshalf = density/2.;

const float size = 3.;
const float hlf = size/2.;

vec2 map(vec3 p){
    vec2 res = vec2(1e5,0.);

    p.xz*=turn;
    p.y-=1.5;
    
    // log-spherical map
    float r = length(p);
    float mul = r/lpscale; 
    p = vec3(log(r), acos(p.y / r ), atan(p.z, p.x));
    xshrink = 1.0/(abs(p.y-PI)) + 1.0/(abs(p.y)) - 1.0/PI;
    p *= lpscale;
    p -= vec3(0,dshalf,hlf);
    // 

    vec3 q = p;
    q.x-=(ffrim*size);
    vec2 qq = q.xz;
    qq.x-=(ddrim*size);
    vec2 id = floor((qq+hlf)/size);
    float chx = mod(id.y+id.x,2.)*2.-1.;
    float hs = hash21(id);
    
    q.xz=mod(q.xz+hlf,size)-hlf;
  
    float a = atan(q.z,q.x);
    vec2 pv = vec2(q.y,a);
    
    float dv =  length(q)-.25;
    if(dv<res.x) {
        res = vec2(dv,1.);
        hit=vec3(pv,p.z);
    }   

    float ff = floor(p.x-id.x)*.01;
    q.xz*=turn;
    q.yz*=rot(1.5);
    
    float rlspd = 6.25+T*hs;

    q.yx*=rot(-rlspd);
    
    vec3 q1 = q; vec3 e1 = vec3(abs(q.x),q.yz);
    q1.yz*=r22;
    float head = ellipse(q1-vec3(0,.4,-.2),vec3(1,.95,1));
    head = sunion(ellipse(q1,vec3(.65,1.25,.65)),head,.1);
    
    vec3 q2 = e1; vec3 q5 = e1; vec3 q4 = q2-vec3(.85,-.3,.30);
    q2.xy*=r12;
    
    vec3 q3 = q2-vec3(.55,.2,.50);
    q3.yz*=r45;
    q4.yz*=r45;
    
    float cheeks = ellipse(q3+vec3(0,0,.1),vec3(.3,.4,.2));
    float incks = ellipse(q4,vec3(.4,.5,.2));
    float brow = ellipse(q3-vec3(0,.5,0),vec3(.25,.4,.25));
  
    cheeks=sunion(brow,cheeks,.15);
    head=sunion(cheeks,head,.075);
    head=ssub(incks,head,.35);
    
    float sockets = ellipse(q2-vec3(.45,.5,.50),vec3(.25,.45,.25));
    head=ssub(sockets,head,.15);
    q2.xy*=r32;
    
    float nosebone = ellipse(q2-vec3(.02,-.1,.6 ),vec3(.09,.20,.1));
    head=ssub(nosebone,head,.15);
    q5-=vec3(.1,-.5,.475);
    q5.x=abs(q5.x)-.05;

    float mouth = ellipse(q1-vec3(0,-.7,.3),vec3(.25,.115,.35));
    float teeth = ellipse(q5,vec3(.05,.1,.02));
    head=ssub(mouth,head,.15);
    head=sunion(teeth,head,.03);
    
    if(head<res.x) {
        res = vec2(chx>.5?head:1.,3.);
        hit=q;
        gid=id;
    }    

    float eye = length(e1-vec3(.38,.5,.35))-.15;
    if(eye<res.x) {
        res = vec2(chx>.5?eye:1.,4.);
        hit=e1;
        gid=id;
    } 
    
    float redux = mul/shorten;
    if(chx>.5) glow += smoothstep(.1,.25,.0025/(.0105+eye*eye*redux)); 

    res.x *=redux;
    return res;
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p, float t){
    float e = t*MIN_DIST;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e).x + 
                      h.yyx*map( p + h.yyx*e).x + 
                      h.yxy*map( p + h.yxy*e).x + 
                       h.xxx*map( p + h.xxx*e).x );
}

//@iq https://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 hue(float t){ 
    vec3 c = vec3(0.886,0.953,0.894),
         d = vec3(0.553,0.227,0.949);
    return vec3(.55) + vec3(.35)*cos( PI*(c*t+d) ); 
}

vec4 FC= vec4(0.196,0.263,0.263,0.);

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, inout float d) {

    vec3 C = vec3(0);
    vec3 p = ro;
    float m = 0.;
    for(int i=0;i<128;i++) {
        p = ro + rd * d;
        vec2 ray = map(p);
        if(abs(ray.x)<MIN_DIST*d||d>MAX_DIST)break;
        d += i<32? ray.x*.25: ray.x*.75;
        m  = ray.y;
    } 

    hitPoint = hit;
    sid = gid;
    
    float alpha = 1.;
    if(d<MAX_DIST) {
        alpha = 0.;
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        vec3 lpos = vec3(-5,15,-15);
        vec3 l = normalize(lpos-p);
        
        vec3 h = vec3(.5);

        float diff = clamp(dot(n,l),.03,1.);
        float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.);
        fresnel = mix(.01, .7, fresnel);

        float shdw = 1.,t=.0;
        for( float i=.01; i < 25.;i++ ){
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 24.*h/t);
            t += h;
            if( shdw<MIN_DIST || t>32. ) break;
        }
        diff = mix(diff,diff*shdw,.65);
        
        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.5 * pow(max(dot(view, ret), 0.), 24.);
        
        float cs = hash21(sid);
        h = vec3(1);
        
        if(m==3.) {
            vec3 uv = hitPoint.yzx*1./.5;
            uv.z=abs(uv.z);
            vec2 id=floor(uv.xz);
            vec2 grid = fract(uv.xz)-.5;
        
            float hs = hash21(id.yx+sid);
            float chk = mod(id.y + id.x,2.) * 2. - 1.;

            if(hs>.5) grid.y*=-1.;
            
            vec2 d2 = vec2(length(grid-.5), length(grid+.5));
            vec2 gx = d2.x<d2.y? vec2(grid-.5) : vec2(grid+.5);

            float px = fwidth(uv.x);
            float circle = length(gx)-.5;

            float circle3 = abs(abs(abs(circle)-.225)-.075)-.025;
            circle3=smoothstep(-px,px,circle3);
            circle=(chk>0.^^ hs>.5 ) ? smoothstep(-px,px,circle) : smoothstep(px,-px,circle);

            if(cs>.35) h = mix(vec3(1.), vec3(0.000,0.702,0.655),circle);
            
            float circle2 = min(circle3,circle);
            h = mix(h,vec3(.05),circle2);
            
            vec2 arc = grid-sign(grid.x+grid.y+.001)*.5;
            float angle = atan(arc.x, arc.y);

            float d = length(arc);
            float width = .15;
            vec2 tuv = vec2(
                fract(2.*chk*angle/1.57),
                (d-(.5-width))/(2.*width)*2.
            );
            tuv.y-=.5;

            vec2 tid = vec2(
                floor(2.*chk*angle/1.57),
                floor(d-(.5-width))/(2.*width)
            );

            if(chk>0.^^ hs>.5 ) tuv.y=1.-tuv.y;

            if(mod(tid.x,2.)==0.) tuv.x = 1.-tuv.x;
            tuv.xy*=vec2(2.5,.65);
            tuv.x=mod(tuv.x+.5,1.)-.5;
            float dots = length(tuv.xy-vec2(0,.25))-.25;
            dots=abs(abs(dots)-.25)-.125;
            dots=smoothstep(-px,px,dots);
            h = mix(h,vec3(0.894,0.624,0.047),1.-dots);
            
            ref = mix(h-fresnel,vec3(0),min(circle2,dots));
        }

        C = diff*h+spec;

        float glowMask = clamp(glow,.0,1.);
        C = mix(C,vec3(0.000,0.702,0.655)*glow+(glow*.25),glowMask);
        
        ro = p+n*1e-5;
        rd = mix(rd,reflect(rd,n),.9-fresnel);
    } else {
        C = FC.rgb;
    }
     
    return vec4(C,alpha);
}

void topLayer(inout vec3 C, vec2 uv, float alpha)  {
    float px = fwidth(uv.x);

    vec2 mv=uv,nv=uv;
    float cvs = mv.x*3.;
    mv.y+=.25*cos(cvs);
    float bx = length(mv.y+.5)-.1;
    bx=abs(abs(abs(bx)-.02)-.01)-.005;
    bx=smoothstep(px,-px,bx);

    nv.y-=.25*cos(cvs);
    float cx = length(nv.y-.5)-.1;
    cx=abs(abs(abs(cx)-.02)-.01)-.005;
    cx=smoothstep(px,-px,cx);
    
    float fx = .15+.15*sin(uv.x*2.5+T*1.5);
    float ft = .15+.15*cos(uv.x*2.5+T*1.25);
    C =mix(C,C+mix(vec3(0.455,0.314,0.008),vec3(0.000,0.702,0.655),fx),cx);
    C =mix(C,C+mix(vec3(0.455,0.314,0.008),vec3(0.000,0.702,0.655),ft),min(bx,alpha));   
    C = clamp(C,vec3(0.),vec3(1.));
}

void main(void) {
    vec2 F=gl_FragCoord.xy;

    // precal
    lpscale = floor(density)/PI;
    turn=rot(T*.25);
    
    r45=rot(-.45);
    r22=rot(-.22);
    r32=rot(.32);
    r12=rot(.12);

    float time = T*.25;
    ddrim = floor(time);
    ffrim = fract(time);
    tmod = mod(time, 10.);
    float t1 = lsp(0.0, 3.0, tmod);
    float t2 = lsp(5.0, 8.0, tmod);

    ga1 = eoc(t1-t2);
    ga1 = ga1*ga1*ga1;
    //
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,0,17.5);
    vec3 rd = normalize(vec3(uv,-1));

    float y = 0.0; //M.xy == vec2(0) ? .0 :  (M.x/R.x * 2. - 1.) * PI;
    
    mat2 rx = rot(.75+.25*sin(T*.25+ga1));
    mat2 ry = rot(y);
    
    ro.yz *= rx;ro.xz *= ry;
    rd.yz *= rx;rd.xz *= ry;
        
    FC.rgb = mix(FC.rgb,vec3(0.031,0.071,0.071),length(uv));
    vec3 C = vec3(0);
    vec3 ref=vec3(0);
    vec3 fill=vec3(1.);
    
    float d =0.,a=0.;
    //@BigWings reflection loop
    for(float i=0.; i<3.; i++) {
        vec4 pass = render(ro, rd, ref, d);
        C += pass.rgb*fill;
        fill*=ref;
        if(i==0.) { a=pass.w; FC = vec4(FC.rgb,exp(-.000245*d*d*d)); }
    }

    C = mix(C,FC.rgb,1.-FC.w);
    C = clamp(C,vec3(0),vec3(1));
    topLayer(C,uv,a);
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1.0);
}

//end
