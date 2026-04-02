#version 420

// original https://www.shadertoy.com/view/7dfBDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    Sliced SDF shapes interwoven
    2/20/22 | @byt3_m3chanic

    Nothing too exciting but working with a
    formula from Javad Taba for slicing SDF 
    shapes. This is the result of taking SDFs
    sliced at alternating intervals.

    Original post here - check his stuff, it's REALLY good!
    https://twitter.com/smjtyazdi/status/1484828390104485896

*/

#define R resolution
#define M mouse*resolution.xy
#define T time

#define PI  3.14159265359
#define PI2 6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

//@iq
float sdtorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

//globals
mat2 rx, ry,trot, qrot;

vec2 map(vec3 p) {
    vec2 res =vec2(1e5,1.);

    p.yz*=trot;

    float d = .5+.25*sin(T*.4); 
    vec3 q=p+vec3(0,0,d*.5);
    
    float mf = 1e5,pf = 1e5,bf=1e5;
    
    for(float j=-1.;j<1.;j+=1.){
        vec3 np =p;
        np.z=round(np.z/d+j)*d;
        np.xy*=trot;

        vec3 nn=np;
        nn.yz*=qrot;
        float sd= sdtorus(nn,vec2(4.5,1.25));
        sd=abs(sd)-.025;

        np.z=clamp(p.z,np.z-d/5.,np.z+d/5.);
        sd=length(vec2(max(.0,sd), np.z-p.z));
        mf=min(mf,sd);

        vec3 nf =q;
        nf.z=round(nf.z/d+j)*d;

        nf.xy*=trot;
        float fd= length(nf)-3.75;
        fd=abs(fd)-.025;

        nf.z=clamp(q.z,nf.z-d/5.,nf.z+d/5.);
        fd=length(vec2(max(.0,fd), nf.z-q.z));
        pf=min(pf,fd);
        
        
        vec3 pt = nf;
        pt.xy*=qrot;

        sd=length(abs(pt)-2.85)-1.;
        sd=abs(sd)-.025;
        sd=length(vec2(max(.0,sd), nf.z-q.z));
        bf=min(bf,sd);

    }

    if(pf<res.x) res=vec2(pf,1.);
    if(mf<res.x) res=vec2(mf,2.);
    if(bf<res.x) res=vec2(bf,3.);
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

vec3 render(vec3 p, vec3 rd, vec3 ro, float d, float m, inout vec3 n, inout float fresnel) {
    n = normal(p,d,1.);
    vec3 lpos =  vec3(11,0,12);
    vec3 l = normalize(lpos-p);
    float diff = clamp(dot(n,l),.03,.9);
    fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 9.);
    fresnel = mix(.0, .95, fresnel);
    vec3 h = vec3(.4);
    if(m==1.) h=vec3(1.000,0.000,0.867);
    if(m==2.) h=vec3(0,.5,1);
    if(m==3.) h=vec3(0.016,1.000,0.000);
    return diff*h;
}

void main(void)
{
	vec2 F=gl_FragCoord.xy;

    // precal
    float time = T;
    trot = rot(T*.15);
    qrot = rot(T*.5);
    rx = rot(.78);

    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0, 0, 10);
    vec3 rd = normalize(vec3(uv, -1.0));

    ro.yz *= rx; ro.xz *= rx;
    rd.yz *= rx; rd.xz *= rx;

    float mask = length(uv)-.5;
    mask=smoothstep(.05,.95,mask);
    
    vec3 C = mix(vec3(.008,.035,.05),vec3(.008,.21,.43),mask);
    vec3  p = ro + rd;
    float atten = .95;
    float k = 1.;
    float d = 0.;
    
    for(int i=0;i<254;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float m = ray.y;

        d = i<64 ? ray.x*.25 : ray.x*.75;
        p += rd * d *k;
        
        if (d*d < 1e-6) {
            float fresnel=0.;
            C+=render(p,rd,ro,d,ray.y,n,fresnel)*atten;

            atten *= .45;
            p += rd*.15;
            k = sign(map(p).x);

            vec3 rr = refract(rd,n,.915);
            rd=mix(rd,rr,.5-fresnel);
        } 
       
        if(distance(p,ro)>45.) { break; }
    }

    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1.0);
}
