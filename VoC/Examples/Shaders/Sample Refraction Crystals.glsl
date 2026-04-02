#version 420

// original https://www.shadertoy.com/view/ftB3DG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Refraction Crystals [015]
    10/22/21 @byt3_m3chanic
    
    Just playing with some simple fold/mirror formulas / SDF intersection
    to make some pretty fractal crystal like things.

*/

#define R             resolution
#define T             time
#define M             mouse*resolution.xy

#define PI          3.14159265358
#define PI2         6.28318530718

#define MAX_DIST    100.

float hash21(vec2 a) { return fract(sin(dot(a,vec2(21.23,41.232)))*4123.2323); }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), .0, 1.); }
float eoc(float t) { return (t = t - 1.) * t * t + 1.; }

//@iq sdf's
float box(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b;
  return length(max(q,0.)) + min(max(q.x,max(q.y,q.z)),0.0)-r;
}
float octa( vec3 p, float s) {
  p = abs(p);
  return (p.x+p.y+p.z-s)*.5773;
}

// fold formulas
void bet(inout vec4 p, float s, float f, float m) {
    p.xy = abs(p.xy + f) - abs(p.xy - f) - p.xy;
    float rr = dot(p.xyz, p.xyz);
    if (rr < m) {
        if(m==0.) m=1e-5;
        p /= m;
    }else{
        if (rr<1.)p /= rr;
    }
    p *= s;
}

void tet(inout vec4 p, float k1, float k2, float k3, float k4) {
    p = abs(p);
    float k = (k1 - .5)*2.;
    p.xyz /= vec3(k2, k3, k4);

    if (p.x < p.y) p.xy = p.yx; p.x = -p.x;
    if (p.x > p.y) p.xy = p.yx; p.x = -p.x;
    if (p.x < p.z) p.xz = p.zx; p.x = -p.x;
    if (p.x > p.z) p.xz = p.zx; p.x = -p.x;

    p.xyz = p.xyz*k1 - k + 1.;
    p.xyz *= vec3(k2, k3, k4);
    p.w *= abs(k);
}

vec2 sdform(in vec3 pos, float hs) {
    vec4 P = vec4(pos.xzy, 1.);
    float orbits = .0;
    for(int i = 0; i < 3; i++) {
        orbits = max(length(P.xz)*.075,orbits);
        bet(P, 4.25-hs, 3.-hs, .55);
        
        if(hs>.5) {
            tet(P, 1.5+hs, 1.5, 1.5, 1.5);
        }else{
            tet(P, 1.5-hs, 1.+hs, 1.5, 1.5);
        }
    }
  
    float ln = .9*(abs(P.z)-15.)/P.w;
    
    return vec2(ln,orbits);
}

mat2 rx,ry,turn;
float ga1,ga2,ga3,ga4,tmod;
    
const float s = 13.;
const float hf= s/2.;

vec2 map (in vec3 p) {
    vec2 res = vec2(MAX_DIST,0.);
    
    vec3 dp = p;
    
    p.y+= .2;
    p.z+= 1.75;
   
    // movin domain 1 rep but using px to move the ID's
    // as if the domain is continious helps make the refraction
    // stay pretty as things get messy with larger time variables 
    // used for distance
    float px = p.x-(ga2*s);
    p.x-=ga1*s;
    float id = floor((px+hf)/s);

    p.x=mod(p.x+hf,s)-hf;
    p.yz*=rx;
    p.xz*=ry;

    float hs = hash21(vec2(id,1.));
    vec2 f = sdform(p,hs);
    float c = octa(p,3.);
    
    f.x= hs>.85?max(f.x,c):max(-f.x,c);
    if(f.x<res.x) {
        res = f;
    }

    float d = box(dp,vec3(9),.00);
    d=max(d,-box(dp,vec3(5.5,4.,5.5),.001));
    d=max(d,-box(dp,vec3(9.5,3.,4.5),.25));
    d=max(d,-box(dp,vec3(4.5,3.,9.5),.25));
    if(d<res.x) {
        res = vec2(d,14.);
    }

    return res;
}

//Tetrahedron technique
//https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p, float t, float mindist) {
    float e = mindist*t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n) {
    n = normal(p,d,1.);
    vec3 lpos = vec3(.1,9,7);
    vec3 l = normalize(lpos-p);
    float diff = clamp(dot(n,l),0.,1.);
    vec3 clr = .5 + .4 *sin(m + vec3(2.5,1.5,.5));
    vec3 h = mix(vec3(0),clr,.45);
    if(m==14.) h=vec3(.416,.420,.506)*clamp((p.y*.1+.5),0.,1.);
    return h*diff;
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy

    //time = T;
    float timer = T*.08;
    
    tmod = mod(time, 10.);
    float t1 = lsp(0., 5., tmod);
    ga1 = eoc(fract(t1));
    ga1 = ga1*ga1*ga1;
    ga2 = (t1)+floor(time*.1);

    vec3 C=vec3(.0);
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0,0,4.),
         rd = normalize(vec3(uv,-1));

    float x = 0.0; //M.xy == vec2(0) ? 0. :  (M.y/R.y * 1. - .5) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 0. : -(M.x/R.x * 2. - 1.) * PI;
    //float dt = length(uv-vec2(x,y));
    rx = rot(x+.28),ry = rot(timer+y);

    vec3  p = ro + rd * .1;
    float atten = .95,k = 1.;
    
    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    // lower for slow machines (128)
    for(int i=0;i<172;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float d = ray.x*.95;
        float m = ray.y;

        p += rd * d *k;
        
        if (d*d < 1e-7) {

            C+=shade(p,rd,d,ray.y,n)*atten;
            if(m==4.)break;

            p += rd*.01;
            k = sign(map(p).x);

            if(m==14.) {
                atten *=.4;
                rd=reflect(-rd,n);
                p+=n*.02;
            }else{
                atten *= .75;
                rd=refract(rd,n,.9);
            }
        }  
        if(distance(p,rd)>18.) { break; }
    }
    // Output to screen
    glFragColor = vec4(sqrt(smoothstep(0.,1.,C)),1.);
}

//end
