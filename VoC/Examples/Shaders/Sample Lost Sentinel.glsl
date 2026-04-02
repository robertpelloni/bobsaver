#version 420

// original https://www.shadertoy.com/view/DdS3Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
   phreax 2022
*/

#define SIN(x)  (.5+.5*sin(x))
#define PI 3.141592
#define PHI 1.618033988749895

float tt, gl, mat, cid;
vec3 ro;

// from shadertoy user tdhopper
#define GDFVector3 normalize(vec3(1, 1, 1 ))
#define GDFVector4 normalize(vec3(-1, 1, 1))
#define GDFVector5 normalize(vec3(1, -1, 1))
#define GDFVector6 normalize(vec3(1, 1, -1))

#define GDFVector7 normalize(vec3(0, 1, PHI+1.))
#define GDFVector8 normalize(vec3(0, -1, PHI+1.))
#define GDFVector9 normalize(vec3(PHI+1., 0, 1))
#define GDFVector10 normalize(vec3(-PHI-1., 0, 1))
#define GDFVector11 normalize(vec3(1, PHI+1., 0))
#define GDFVector12 normalize(vec3(-1, PHI+1., 0))

#define GDFVector13 normalize(vec3(0, PHI, 1))
#define GDFVector14 normalize(vec3(0, -PHI, 1))
#define GDFVector15 normalize(vec3(1, 0, PHI))
#define GDFVector16 normalize(vec3(-1, 0, PHI))
#define GDFVector17 normalize(vec3(PHI, 1, 0))
#define GDFVector18 normalize(vec3(-PHI, 1, 0))

#define fGDFBegin float d = 0.;
#define fGDF(v) d = max(d, abs(dot(p, v)));
#define fGDFEnd return d - r;

float fIcosahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12)
    fGDFEnd
}

vec3 pal(float t) {
        vec3 cols[] = vec3[](vec3(0.510,0.510,0.510), vec3(0.102,0.675,0.918), vec3(0.427,0.220,1.000), vec3(0.259,1.000,0.443), vec3(1.000,0.220,0.894));
        return cols[int(t) % cols.length()];
}

mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

// iq's impulse function
float impulse2( float x, float k) {
    
    float h = k*x;
    return h*exp(1.0-h);
}

float impulse( float x, float k, float e) {
    
    float h = k*pow(x, e);
    return h*exp(1.0-h);
}

// repetitive, continues pulse function for animation
float continuesPulse(float x, float k, float e, float period) {
   
    return impulse(mod(x, period), k, e);
    
}

// repetitive, continues pulse function for animation
float continuesPulse2(float x, float k, float period) {
   
    return impulse2(mod(x, period), k);
    
}

// remap [0,1] -> [a, b])
float remap(float x, float a, float b) {
    return a*x+b;
}

float cyl(vec2 p, float r) {
    return length(p) - r;
}

float sph(vec3 p, float r) {
    return length(p) - r;
}

float cylcap( vec3 p, float r, float h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float ring(vec3 p, float h, float rout, float rin) {
    return max(cylcap(p, h, rout), -cylcap(p, 2.*h, rin));
}

float box(vec3 p, vec3 r) {
    vec3 d = abs(p) - r;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
/*
    p = abs(p) - r;
    return max(p.x, max(p.y, p.z));
}
*/

vec2 repeat(vec2 p, vec2 s) {
       return (fract(p/s-.5)-.5)*s;
}

float repeat(float p, float s) {
       return (fract(p/s-.5)-.5)*s;
}

float sdOctopus(vec3 p) {
    float s = 0.4;
    vec3 q = p;
    
    
    q.z = abs(q.z);
     
    q.y = -abs(q.y);
    q.yz *= rot(PI*0.25);
    q.z = abs(q.z);
    q.y = -abs(q.y);
    q.yz *= rot(PI*0.125);
    q.z = abs(q.z);
   
    q.xz *= rot(-PI*0.25);

    q.xz -= 0.5;
 
    int maxIter = 20;
    float d = 1e6;
    float alpha = remap(continuesPulse((tt), 0.7, 4.0, 5.0), -0.45, 0.15);

    for(int i=1; i < maxIter; i++) { 
        q.xz *= rot(-alpha);
        q.z-=10./float(maxIter);
        s -= 0.8/float(maxIter);
        float b = box(q, vec3(s))-.01;
        d = min(d, b);              
    }
    
    float head = fIcosahedron(p, .7);
    
    d = min(d, head);
  
    return d;
}

vec3 tunnel(vec3 p) {
    vec3 off = vec3(0);
    off.x += sin(p.z*.1)*4.;
    off.y += sin(p.z*.12)*3.;
    return off;
}

vec2 moda(vec2 p, float s) {
    float r = length(p);
    float a = atan(p.y, p.x);
    a = (fract(a/s-.5)-.5)*s;
    return r*vec2(cos(a), sin(a));
       
}

float repeat2(inout float p, float size) {
  float c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

void cam(inout vec3 p) {
    p.z += tt*5.;// + 7.*sin(.1*tt);
    p -= tunnel(p);
}

float map(vec3 p) {

    vec3 np = p;

    float tunr = 10.;
    float vrep = 10.;
    
    p += tunnel(p);
   
    vec3 vvp = p;
    vvp.z += vrep/2.;
    cid = 1.+(repeat2(vvp.z, vrep)/vrep)*10.;
    float octo;
    
    {
    
        vec3 q = p;
        float pulse = continuesPulse((tt), 0.7, 3.0, 5.0);
        float pulse2 = continuesPulse2((tt-1.), 3., 5.0);
  
        q.z += 5.;
        
        q.z -= remap(pulse, 1.5, 10.0);   \
        q.z -= 1.5*tt + tt *remap(pulse2, 0., 3.5);
                
       // float oid = repeat2(q.z, 30.);
        q.xz *= rot(-PI*.5);
        vec3 o1 = q;
        vec3 o2 = q;

        o1.xy += vec2(-4.5*sin(tt), 3.3*cos(.4*tt));
        //o2.x -= 5.0;

        o1.xz *= rot(.4*sin(tt*.4));
        float s = 1.8;
        octo = 1./s*sdOctopus(o1/s);
    }

    vec3 bp = p;
    vec3 vp = p;
    vec3 cp = p;
    vec3 sp = p;
    
    
    bp.x = atan(p.y, p.x)*30./3.1415;
    bp.y = length(p.xy)-tunr;

    
    bp.xz = repeat(bp.xz, vec2(4));
    bp.xz = abs(bp.xz) - 1.; 
    bp.x -= bp.z*.4;
     
    for(float i = 0.; i < 3.; i += 1.) {
        bp.xz *= rot(tt*.1+cid);
        //bp.yz *= rot(5.*i);
      
        bp.xz = abs(bp.xz) - 1. - .1*SIN(i*tt*.3);

        bp.x += .1;
 
    }
      
    float b = .9*box(bp, vec3(.8));

    float dz = abs(ro.z-np.z);
    float fade = exp(-sqrt(dz)*.4);
    
    cp.xy *= rot(.08*p.z);
    cp.x = abs(cp.x) - 3.;
    cp.x += sin(0.25*cp.y+sin(tt))*2.;
    cp.z = repeat(cp.z, 5.);
    
    float vid = repeat2(vp.z, vrep);
    vp.yz *= rot(PI*.5);
    float veil = ring(vp, max(0., .01), tunr, tunr-.1);
    
    float gls = SIN(vid*2.+2.*tt);
    gl += .018/(.1+pow(abs(veil), 8.));
    
    float tun = b;
    
   // repeat2(sp.z, vrep);
    //sp.y -= 9.4;
    //sp.z -= vrep/2.;
    //float stone = .3*fIcosahedron(sp, 1.5);

    mat = tun < octo ? 0. : 1.+cid;
    
    float d = min(tun, octo);
    return d;
}

float calcAO(vec3 p, vec3 n)
{
    float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    tt = 1.5*time;
    
    vec3 ls = vec3(0, 0, -10.0); // light source
    vec3 col = vec3(0);
    
    ro = vec3(0, 0, -20);
    vec3 rd = normalize(vec3(-uv, .7)); 
    
    vec3 gcol = vec3(0.467,0.706,0.933);

    cam(ro);
    cam(ls);
    vec3 p = ro;
    float d = 0.1;
    
    float l_mat = 0.;
    float l_cid = 0.;
    
    float i, t= .1;
    for(i=0.; i<150.; i++) {
        d = map(p);
        
        if(d < 0.001 || d > 20.) break;
        
        p += d*rd;
        t += d;
        l_mat = mat;
        l_cid = cid;     
    }
    
    if(d < 0.001) {
        vec2 e = vec2(0.0035, -0.0035);
        
        vec3 al = pal(l_cid);
        vec3 n = normalize( e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) +
                            e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx));
        
        vec3 l = normalize(ls-p);
        float dif = max(dot(n, l), .0);
        float spe = pow(max(dot(reflect(-rd, n), -l), .0), 40.);
        float sss = smoothstep(0., 1., map(p+l*.4))/.4;
        float ao = calcAO(p, n);

        if(l_mat < 1.) {
           // gcol = mix(gcol, al, .2);
            col += pow(i/100., 1.2)*3.*gcol*exp(-t*t*0.001);
        } else {
            col +=  .2*spe+.8*al*(.3+.8*dif+1.5*sss) + .2*ao;
          
          
        }
    }
    
    col += 0.08*gl*gcol;
           
    col = pow(col, vec3(1.4));
    glFragColor = vec4(col,1.0);
}
