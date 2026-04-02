#version 420

// original https://www.shadertoy.com/view/sdcSWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Box Node Connections
    10/3/21 @byt3_m3chanic
    
    Just playing with a simple fold/mirror formula / simple box and tube with
    a little refraction.

*/

#define R resolution
#define M mouse*resolution.xy
#define T time

#define PI  3.14159265359
#define PI2 6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
float eoc(float t) { return (t = t - 1.0) * t * t + 1.0; }

//@iq thanks for the sdf's!

float sdbox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdframe( vec3 p, vec3 b, float e ) {
  p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

//globals
mat2 rx, ry;
float tmod=0.,ga2=0.,ga4=0.,ga5=0.;
vec3 hit,hitPoint;

//fold
void octa(inout vec4 p, float k1, float k2, float k3, float k4)  
{
    p.y = abs(p.y);
    if (p.x + p.y<0.0) p.xy = -p.yx;
    if (p.x + p.z<0.0) p.xz = -p.zx;
    if (p.x - p.y<0.0) p.xy = p.yx;
    if (p.x - p.z<0.0) p.xz = p.zx;
    p.xyz = p.xyz*k1 - (k1 - 1.0);
}

const float zoom = 23.5;
const float cell = 24.;
const float hlf = cell/2.;

vec2 map(vec3 p) {
    vec2 res =vec2(1e5,0.);

    vec3 pp = p;
    
    if(ga4>0.) p.xz*=rot(ga4*PI/2.);
    if(ga5>0.) p.y+=ga5*cell;
    
    p.y=mod(p.y+hlf,cell)-hlf;
  
    vec4 P = vec4(p.xyz, 1.0);
    float spc = 6.;
    
    for(int j=0;j<2;j++) { 
        octa(P, 1.,1.,1.,1.); 
        P.xyz = abs(P.zxy)-spc;
    }
    vec3 q = P.xyz;

    q.x = abs(q.x)-spc;
    q.z = abs(q.z)-spc;

    vec3 fq = q;
    fq.x=abs(fq.x)-1.6;
    fq.y=abs(abs(fq.y)-.4)-.2;
    float mainbox = sdbox(q,vec3(1.25));
    float cutbox =  sdbox(vec3(q.xy,abs(q.z))-vec3(0,0 ,1.35),vec3(.65,.65,3.75 ));
    float frame = sdbox(fq,vec3(.1,.1,.75));

    mainbox = min(mainbox, frame);
    mainbox = max(mainbox, -cutbox);
    if(mainbox<res.x) res = vec2(mainbox/P.w,2.);

    float frame2 = sdframe(q,vec3(1.475),.225)-.0125;
    if(frame2<res.x) res = vec2(frame2/P.w,4.);

    float dv = .45+.25*sin(q.z*.75);
    float beams = length(q.xy)-dv;

    if(beams<res.x) {
        res = vec2(beams/P.w,3.);
        hit=pp+vec3(0,ga2*cell,0);
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

//iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 render(vec3 p, vec3 rd, vec3 ro, float d, float m, inout vec3 n, inout float fresnel) {
    n = normal(p,d,1.);
    vec3 lpos =  vec3(18,18,18);
    lpos.xz*=ry;
    vec3 l = normalize(lpos-p);
    float diff = clamp(dot(n,l),0.,1.);
    
    fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 9.);
    fresnel = mix(.0, .9, fresnel);

    vec3 h = vec3(.1);
    if(m==3.) h = hsv2rgb(vec3(p.x*.003+hitPoint.y*.0125,.8,.5));
    if(m==4.) h=vec3(.4);
 
    return diff*h;
}

void main(void)
{
    vec2 F = gl_FragCoord.xy;
    // precal
    float time = T;

    tmod = mod(time, 10.);
    float t7 = lsp(0.0, 5.0, tmod);
    float t9 = lsp(4.0, 10.0, tmod);

    ga4 = eoc(t7);
    ga4 = ga4*ga4*ga4;
    ga4 = ga4+floor(time*.1);
    
    t9 = eoc(t9);
    t9 = t9*t9*t9;  
    ga2 = t9+floor(time*.1);
    ga5 = (t9);
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0, 0, zoom);
    vec3 rd = normalize(vec3(uv, -1.0));
    
    float x = 0.0; //M.xy == vec2(0) ? 0. : -(M.y/R.y * .25 - .125) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 0. : -(M.x/R.x * 1.  - .5) * PI;

    rx = rot(x+.18); ry = rot(y-.58);

    ro.yz *= rx; ro.xz *= ry;
    rd.yz *= rx; rd.xz *= ry;

    vec3 C = vec3(.0015);
    vec3 p = ro + rd;
    
    float atten = .95;
    float k = 1., d = 0.;
    
    for(int i=0;i<100;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float m = ray.y;

        d = ray.x*.75;
        p += rd * d *k;
        
        float fresnel=0.;
        if (d*d < 1e-7) {
            hitPoint=hit;
            C+=render(p,rd,ro,d,ray.y,n,fresnel)*atten;
  
            atten *= .55;
            p += rd*.01;
            k = sign(map(p).x);

            if(m==4.||m==1.) {
                rd=reflect(-rd,n);
                p+=n*.025;
            } else {
                vec3 rr = refract(rd,n,.55);
                rd=mix(rr,rd,.5-fresnel);
            }

        } 
       
        if(distance(p,rd)>50.) { break; }
    }

    if(C.r<.008&&C.g<.008&&C.b<.008) C = hash21(uv)>.5 ? C+.005 : C;
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1.0);
}

//end
