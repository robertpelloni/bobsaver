#version 420

// original https://www.shadertoy.com/view/sttyD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// philip.bertani@gmail.com

//#define oct 5   //number of fbm octaves
#define pi  3.14159265
#define sphr .3

int oct=5;

struct RayInfo  {
    vec3 p1,p2;
    bool hit;
};

RayInfo RaySphereIntersect(vec3 ro, vec3 rd, vec3 spherepos, float r) {

    vec3  a = (spherepos - ro);
    float b = dot(rd, a);
    float c = dot(a,a) - r*r;
    float d = b*b - c;

    RayInfo ri; ri.hit=false;

    if ( d < 0.0 ) return ri;

    float sd = sqrt(d);
    float t1 = b - sd, t2 = b + sd;

    ri.p1 = ro + rd * t1;
    ri.p2 = ro + rd * t2;
  
    ri.hit = true;

    return ri;

}

float dist_func01(vec3 p) {
    return length(p) - sphr;
}

vec3 gradient(vec3 p) {

    vec2 dpn = vec2(1.,-1.);
    vec2 dp  = .01 * dpn; 

    vec3 df = dpn.xxx * dist_func01(p+dp.xxx) +
              dpn.yyx * dist_func01(p+dp.yyx) +
              dpn.xyy * dist_func01(p+dp.xyy) +
              dpn.yxy * dist_func01(p+dp.yxy);

    return normalize(df); 

}

float random(vec3 p) {
    //a random modification of the one and only random() func
    return fract( sin( dot( p, vec3(12., 90., -.8)))* 1e5 );
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    float a = random(i + vec3(1.,1.,1.));
    float b = random(i + vec3(1.,-1.,-1.));
    float c = random(i + vec3(-1.,1.,1.));
    float d = random(i + vec3(-1.,1.,-1.));
     vec2 u = f.yz *f.xy*(3.-2.*f.xz);
    
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;

}

float fbm3d(vec3 p) {
    float v = 0.;
    float a = .5;
  
    for (int i=0; i<oct; i++) {
        v += a * noise(p);
        p = p * 2.;
        a *= .7;  //changed from the usual .5
    }
    return v;
}

mat3 rxz(float an){
    float cc=cos(an),ss=sin(an);
    return mat3(cc,0.,-ss,
                0.,1.,0.,
                ss,0.,cc);                
}
mat3 ryz(float an){
    float cc=cos(an),ss=sin(an);
    return mat3(1.,0.,0.,
                0.,cc,-ss,
                0.,ss,cc);
}   

vec3 get_color(vec3 p) {
    vec3 q;
    q.x = fbm3d(p);
    q.y = fbm3d(p.yzx);
    q.z = fbm3d(p.zxy);

    float f = fbm3d(p + q);
    
    return q*f;
}

void main(void)
{
 
    vec3 light; 
    float myTime = 10. + time; // mod(time,120.);

    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 mm = (2.*mouse*resolution.xy.xy-resolution.xy)/resolution.y/2.;

    vec3 rd = normalize( vec3(uv, -2.) );  
    vec3 ro = vec3(0.,0.,0.);
    
    float delta = 2.*pi/10.;
 
    mat3 rot = rxz(-2.*delta) * ryz(.2*delta); 
    
    ro -= rot[2]*myTime/4.;
    
    rd = rot * rd;
    
    vec3 p = ro + rd;
    
    vec3 cc = vec3(0.);

    float stepsize = .01;
    float totdist = stepsize;
  
    vec3 spherepos = ro + .7*rot[2];
    //if ( mouse*resolution.xy.w != 0. ) spherepos += -mm.x*rot[0] - mm.y*rot[1];

    RayInfo ri = RaySphereIntersect(ro,rd,spherepos,sphr);    
    vec3  nn;
    
    if ( ri.hit ) {  
    
        nn = gradient( ri.p1 );
        vec3 rd2 =  refract( rd, -nn, .1);  //change ray direction
        //p+= 3.*(ri.p2-ri.p1)*rd2;   //this was a mistake - but looked cool
        p+= 1.3*(length(ri.p2-ri.p1))*rd2;   //move the ray to exit  the sphere
        oct = 7;   //make the sphere noisier 
    }
  
    for (int i=0; i<16; i++) {
       vec3 cx = get_color(p);
       p += stepsize*rd;
       float fi = float(i);
       cc += exp(-totdist*totdist*float(i))* cx;
       totdist += stepsize;
       rd = ryz(.4)*rd;   //yz rotation here
               
    }
    
    if ( ri.hit ) {
        cc *= .8 ; 
        cc.b += 2.*fbm3d(ri.p2);
    }
    
    cc = .5 + 1.3*(cc-.5);  //more contrast makes nice shimmering blobs
    cc = pow( cc/15. , vec3(3.));    //play with this

    glFragColor = vec4(cc,1.0);
    
    
}
