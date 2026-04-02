#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/fdVXRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Just an experiment into doing some
    visual representations / layers like in
    those old science textbooks.
    
    AA chugs a bit/2pass hack bit anything
    more kills it on my PC

*/

#define R         resolution
#define T         time
#define M         mouse*resolution.xy

#define PI      3.14159265358
#define PI2     6.28318530718

// set to 1.0 if it chugs for you
#define AA 2.0

mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 a) { return fract(sin(dot(a,vec2(21.23,41.232)))*43758.5453); }

//@iq
float box( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float cap( vec3 p, float h, float r ){
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdGry(vec3 p, float s, float t, float b) {
    p *= s;
    float sw = 1.25+1.25*sin(23.3);
    return abs(dot(sin(p*1.57-sw), cos(p.zxy))-b)/(s)-t;
}

//global
vec3 hit=vec3(0),hitPoint=vec3(0);
vec2 uv=vec2(0);
mat2 turn,rx,ry;
float g1,g2,g5,g4,gg5;
float dz = .38;

vec2 map(vec3 p){
    vec2 res = vec2(1e5,0.);
    float cutbox = cap(p, 7.,5.);

    vec3 q = p;
    q.xz*=turn;
 
    float gdens = 1.35, g1 = 0.;

    g2 = sdGry(q, gdens*8., .028, .2);
    g5 = sdGry(q, gdens*7., .058, .2)*.5;

    g1 = sdGry(q, gdens, .008, .5);
    g1 = max(g1-.05,g2);

    g1 = max(cutbox,g1*.5); 
    if(g1<res.x&&uv.x>dz) {
        res=vec2(g1,1.);
        hit=q;
    }

    g1 = sdGry(q, gdens, .02, .8);
    g1 = max(g1,g5);
    
    g1 = max(cutbox,g1*.5); 
    if(g1<res.x&&uv.x>-dz) {
        res=vec2(g1,2.);
        hit=q;
    }
    
    g1 = sdGry(q, gdens, .098, 1.15);
    g1 = max(g1,g5);
    
    g1 = max(cutbox,g1*.5); 
    if(g1<res.x) {
        res=vec2(g1,3.);
        hit=q;
    }
 
    return res;
}

//Tetrahedron technique
//https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p, float e) {
    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n, inout float fresnel) {
    n = normal(p,d);
    vec3 lpos = vec3(.1,9,7);
    vec3 l = normalize(lpos);

    float diff = clamp(dot(n,l),0.,1.);
    fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 8.5);
    fresnel = mix(.0, .9, fresnel);
    
    vec3 h = vec3(.01);
    if(m==1.) h = vec3(0.690,0.408,0.012);
    if(m==2.) h = vec3(0.012,0.306,0.549);
    if(m==3.) h = vec3(0.161,0.129,0.173);
    if(m==3.) {
        h = mix(vec3(0.161,0.129,0.173),vec3(0.690,0.271,0.620),g5*4.);
    }

    return diff*h;
}

vec3 render(vec3 ro, vec3 rd, vec2 F) {
   
    vec3 C = vec3(0);
    vec3  p = ro + rd * .1;
    float atten = 1., k = 1.;
    
    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    for(int i=0;i<128;i++)
    {
        vec2 ray = map(p);
        vec3 n = vec3(0);
        float fresnel=0.;
        float d = ray.x*.65;
        float m = ray.y;
        p += rd * d *k;
        
        if (d*d < 1e-7) {
 
            hitPoint=hit;
            
            C+=shade(p,rd,d,m,n,fresnel)*atten;

            atten *= .45;
            p += rd*.1;
            k = sign(map(p).x);

            vec3 rr = vec3(0);

            if((int(F.x)%3 != int(F.y)%3)&&m!=3.) {
                rd = refract(rd,n,m==2.?.8:.5);
            }else{
                rd=reflect(-rd,n);
                p+=n*.015;
            } 
         
            
        }  
        if(distance(p,rd)>30.) { break; }
       
    }
    return C;
}

void image( out vec4 O, in vec2 F ) {   
    turn = rot(T*1.25*PI/180.);

    vec3 C = vec3(.0);
    
    uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    dz = .42+.11*sin(uv.y*2.3+T);

    vec3 ro = vec3(0,0,9.),
         rd = normalize(vec3(uv,-1));
    vec2 mm = M.xy/R.xy;
    float x = M.xy == vec2(0) ? .0 : -(mm.y * 1. - .5) * PI;
    float y = M.xy == vec2(0) ? .0 :  (mm.x * 2. - 1.) * PI;

    rx = rot(x);ry = rot(y);

    ro.yz *= rx;rd.yz *= rx;
    ro.xz *= ry;rd.xz *= ry;

    C = render(ro,rd,F);
    
    float px = fwidth(uv.x)*PI;
    if(uv.x<px-dz&& uv.x>-(dz+px)) C = vec3(1);
    if(uv.x>(dz-px)&& uv.x<(dz+px)) C = vec3(1);
    
    C = clamp(C,vec3(.03),vec3(.98));
    O = vec4(C,1.0);
}

void main(void) {
    vec2 F=gl_FragCoord.xy;
    vec4 C = vec4(0);
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    float px = .125;
    
    if(AA==1.0) {
        image(C,F);
    } else {
    
        vec4 C2;
        image(C2,F.xy+vec2(px,px));
        C.rgb+=C2.rgb;
        image(C2,F.xy+vec2(-px,-px));
        C.rgb+=C2.rgb;
        C/=2.0;
    }
    
    C = sqrt(smoothstep(0.,1.,C));
    glFragColor = vec4(C);
}

// end
