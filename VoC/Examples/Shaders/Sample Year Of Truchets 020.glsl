#version 420

// original https://www.shadertoy.com/view/clVGDw

uniform int frames;
uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #020
    05/17/2023  @byt3_m3chanic
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
*/

// AA = 1 = OFF else 2 > depending on GPU
#define ZERO (min(frames,0))
#define AA 1

// AA

#define R            resolution
#define T             time
#define M             mouse*resolution.xy

#define PI          3.141592653
#define PI2         6.283185307

#define MAX_DIST    50.

// globals & const
vec3 hit,hp;
float mid,sid;
mat2 flip,turn,r90;

const vec2 sz = vec2(1.25,1.5);

const vec3 size = sz.xyx;
const vec3 hlf = size/2.;
const vec3 bs = vec3(hlf*.9);
// change depth / width / height of truchet grid
const vec3 grid = vec3(1,1,1);

const float thick = .175;
const float tc = thick*.55;
const float tf = thick*1.8;
const float td = thick;
const float tg = thick*1.2;
    
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.53,84.21+date.z)))*4832.3234); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }

//@iq sdf's
float box(vec3 p,vec3 b){
    vec3 q = abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float cap(vec3 p,float r,float h){
    vec2 d = abs(vec2(length(p.xy),p.z))-vec2(h,r);
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}
 
float trs( vec3 p,vec2 t){
    vec2 q = vec2(length(p.zx)-t.x,p.y);
    return length(q)-t.y;
}

vec2 map(vec3 p){
    vec2 res = vec2(1e5,0.);
    p.yz*=flip; p.xz*=turn;
    vec3 q = p;
    
    vec3 id = floor((q + hlf)/size);
    q = q-size*clamp(round(q/size),-grid,grid);
   
    float hs = hash21(id.xz+id.y);
    if(hs>.5) q.xz*=r90;

    vec2 p2 = vec2(length(q.xz-hlf.xz), length(q.xz+hlf.xz));
    vec2 gx = p2.x<p2.y ? vec2(q.xz-hlf.xz) : vec2(q.xz+hlf.xz);
    vec3 uv = vec3(gx.x,q.y,gx.y);

    
    float xhs = fract(2.*hs+id.y);
    float rhs = fract(hs+id.x);
    float trh = trs(uv,vec2(hlf.x,thick));

    if(rhs>.9){
        trh = length(vec3(abs(q.x),q.yz)-vec3(hlf.x,0,0))-thick;
        trh = min(length(vec3(q.xy,abs(q.z))-vec3(0,0,hlf.z))-thick,trh);
    } else if(rhs>.6){
        trh = cap(q,hlf.x,thick);
        trh = min(length(vec3(abs(q.x),q.yz)-vec3(hlf.x,0,0))-thick,trh);
    } 
 
    trh=max(abs(trh)-.075,-trh);
    trh=max(trh,box(q,bs));

    if(trh<res.x ) {
        float mt = floor(mod(xhs*7.32,4.))+1.;
        res = vec2(trh,mt);
        hit = uv;
    } 

    
    float bls = cap(vec3(q.xy,abs(q.z))-vec3(0,0,hlf),tc,tf);
      bls = min(cap(vec3(q.zy,abs(q.x))-vec3(0,0,hlf),tc,tf),bls);
    
    float crt = cap(vec3(q.xy,abs(q.z))-vec3(0,0,hlf),td,tg);  
      crt = min(cap(vec3(q.zy,abs(q.x))-vec3(0,0,hlf),td,tg),crt);
   
    bls=max(bls,-crt)-.01;

    if(bls<res.x) {
       res = vec2(bls,8.);
       hit = q;
    } 

    return res;
}

//Tetrahedron technique
//https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t, float mindist) {
    float e = mindist*t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}
//@iq hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0,4,2),6.)-3.)-1., 0., 1. );
    return c.z * mix( vec3(1), rgb, c.y);
}

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n) {
    n = normal(p,d,1.);
    vec3 lpos = vec3(2,12,7);
    vec3 l = normalize(lpos);
    float diff = clamp(dot(n,l),.01,1.);
    vec3 h = m==8.? vec3(.12) : hsv2rgb(vec3(T*.075+m*.08,.7,.3))*.4;

    return h*diff;
}

vec3 render(in vec2 uv, in vec2 F )
{    
    vec3 C = vec3(0);
    vec3 ro = vec3(0,0,3.25),
         rd = normalize(vec3(uv,-1));

    // mouse //
    float mvt = 1.5707*sin(T*.08);
    float x = .68;
    float y = .00;

    flip=rot(x+T*.07);
    turn=rot(y+mvt);
    r90=rot(1.5707);
    
    // bounces - set lower if slow
    float b = 10.;

    vec3  p = ro + rd * .1;
    float atten = 1., k = 1., iv = 1., alpha = 1.;
    
    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    for(int i=0;i<100;i++)
    {
        vec2 ray = map(p);
        vec3 n = vec3(0);

        float d = i<32? ray.x*.3: ray.x*.9;
        float m = ray.y;

        p += rd * d * k;
        
        if (d*d < 1e-6) {
            C+=shade(p,rd,d,ray.y,n)*atten;
            
            alpha *= 1e-1;
            b -= 1.;
            if(m==12.||b<1.)break;
            
            atten *= .98;
            p += rd* .025;
            k = sign(map(p).x);
        
            vec3 rf=refract(rd,n,iv>0.?.875:1.1);
            iv *= -1.;
            
            if(length(rf) == 0.) rf = reflect(rd,n);
            
            rd=rf;
            p+=-n*.0025;
        } 
        if(distance(p,rd)>45.) { break; }
    }
    
    return C;
}

float fltm(float t, float d) { return hash21(vec2(t,d));}

// AA from @iq https://www.shadertoy.com/view/3lsSzf

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);

    vec3 C = vec3(0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        vec2 o = vec2(float(m),float(n)) / float(AA) - .5;
        vec2 uv = (-R.xy + 2.*(F+o))/max(R.x,R.y);
#else    
        vec2 uv = (-R.xy + 2.*F)/max(R.x,R.y);
#endif
        vec3 color = render(uv,F);       
        color = 1.35*color/(1.+color);
        C += color;
#if AA>1
    }
    C /= float(AA*AA);
#endif
    C = pow(C, vec3(.4545) );
    // Output to screen
    O = vec4(C,1.);
    
    glFragColor = O;
}
//end