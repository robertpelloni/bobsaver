#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NtX3Rj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Crank and Shaft Gear Animation
    
    I dont know why I had this in my head then when
    I tried it - i failed, thankfully folks on the
    shadertoy FB page helped!! 
    
    Was done more for learning than anything else.
    @byt3_m3chanic
*/

#define R         resolution
#define T         time
#define M         mouse*resolution.xy

#define PI              3.14159265358
#define PI2             6.28318530718
#define PH              1.57079632679

#define MAX_DIST    100.

float mtime=0.;

float hash21(vec2 a)
{
    return fract(sin(dot(a,vec2(21.23,41.232)))*4123.2323);
}

mat2 rot(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

void getMouse(inout vec3 ro, inout vec3 rd)
{
    float x = .15;
    float y = .00;

    mat2 rx = rot(x);
    mat2 ry = rot(y);
    
    ro.yz *= rx;
    rd.yz *= rx;
    ro.xz *= ry;
    rd.xz *= ry;
}

float vmax(vec3 p)
{
    return max(max(p.x,p.y),p.z);
}

float box(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}

float cap( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float vcap( vec3 p, float h, float r )
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float torus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xy)-t.x,p.z);
    return length(q)-t.y;
}

float opx( in vec3 p, float d, in float h )
{
    vec2 w = vec2( d, abs(p.z) - h );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}
 
float smin( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float gear(vec3 p, float radius, float thick)
{
    float hole = (radius*.35);
    
    float sp = floor(radius*PI2);
    float gs = length(p.xy)-radius;
    float at = atan(p.y,p.x);
    
    float gw = abs(sin(at*sp)*.2);
    gs +=smoothstep(.05,.5,gw);
    
    float cog = opx(p,gs,thick);
    
    cog=max(cog,-(length(p.xy)-hole));

    return cog * .55;
}

vec3 hit=vec3(0);vec3 hp=vec3(0);
mat2 r90,tr1,tr2;
float rt1,rt2;
vec2 fid= vec2(0.),sid=vec2(0.);

vec2 map(vec3 p) {
    vec2 res = vec2(100.,-1.);
    p.y+=.5;
    p.x-=T*.5;
    fid = vec2(
        floor((p.x+3.5)/7.)-5.,
        floor((p.x+3.5)/7.)-5.
    );   

    p.x=mod(p.x+3.5,7.)-3.5;

    vec3 b = p-vec3(0,1,0);
    vec3 q = p-vec3(3.5,2.75,0);
    vec3 r = p-vec3(-3.5,2.75,0);
    
    b.xy*=tr1;
    q.xy*=tr2;
    r.xy*=tr2;
    
    float cog1 = gear(b, 1.5,1.15);
    float cpp1 = cap(b.yzx-vec3(-.95,1.05,0),.25,.85);
    
    cog1=min(cpp1,cog1);
    
    if(cog1<res.x)
    {
        res = vec2(cog1,5.);
        hit=b;
        fid.x +=fid.y*1.3;
    }  

    float armlength = 2.;

    vec3 pu = p-vec3(0,-1.,1.75);
    vec3 sv = p-vec3(0,1.,1.75);
    
    float u = .95 * sin(rt1);
    float v = .95 * cos(rt1);
    
    sv.x-=u;
    sv.y+=v;

    float beta = asin(u/armlength);
    
    sv.xy *= rot(-beta);
    
    float sft = armlength*cos(beta)+v;
    float arm1 = vcap(sv+vec3(0,armlength,0),armlength,.15);
    float arm1a= vcap(pu+vec3(0,sft,0),armlength,.2 );
    arm1a= min(vcap(pu+vec3(0,1.75+(sft*.5),0),armlength,.3 ),arm1a);
   
    if(arm1<res.x)
    {
        res = vec2(arm1,3.);
        hit=b;
    }  
    
    
    float cog2 = gear(q, 2.5,.75);
    float cpp2 = cap(q.yzx-vec3(1.5,.75,0),.4 ,.75);  
    cog2=min(cpp2,cog2);
    
    if(cog2<res.x)
    {
        res = vec2(cog2,4.);
        hit=q;
        fid.y +=1.;
    } 
    
    vec3 pc = p-vec3(3.5,-1.4,1.25);
    vec3 sc = p-vec3(3.5,2.75,1.25);
    
    u = 1.5 * sin(rt2);
    v = 1.5 * cos(rt2);
    
    sc.x+=u;
    sc.y-=v;
    
    armlength = 4.;
    
    beta = sin(u/armlength);
    
    sc.xy *= rot(beta);
    sft = armlength*cos(beta)-v;
    
    float arm2 = vcap(sc+vec3(0,armlength,0),armlength,.15);
    float arm2a= vcap(pc+vec3(0,sft,0),armlength,.2 );
    arm2a= min(vcap(pc+vec3(0,3.75+(sft*.5),0),armlength,.35 ),arm2a);
  
    if(arm2<res.x)
    {
        res = vec2(arm2,1.);
        hit=sc;
    }  
 
    float cog3 = gear(r, 2.5,.75);
    float cpp3 = cap(r.yzx-vec3(1.5,.75,0),.4 ,.75);
    cog3=min(cpp3,cog3);
    if(cog3<res.x)
    {
        res = vec2(cog3,4.);
        hit=r;
       
    } 
    
    pc = p-vec3(-3.5,-1.4,1.25);
    sc = p-vec3(-3.5,2.75,1.25);
    
    u = 1.5 * sin(rt2);
    v = 1.5 * cos(rt2);
    
    sc.x+=u;
    sc.y-=v;
    
    armlength = 4.;
    
    beta = sin(u/armlength);
    
    sc.xy *= rot(beta);
    sft = armlength*cos(beta)-v;
    
    float arm3 = vcap(sc+vec3(0,armlength,0),armlength,.15);
    float arm3a= vcap(pc+vec3(0,sft,0),armlength,.2 );
    arm3a= min(vcap(pc+vec3(0,3.75+(sft*.5),0),armlength,.35 ),arm3a);
  
    if(arm3<res.x)
    {
        res = vec2(arm3,1.);
        hit=sc;
    }  
    arm1a=min(arm2a,arm1a); 
    arm1a=min(arm3a,arm1a);
    if(arm1a<res.x)
    {
        res = vec2(arm1a,6.);
        hit=r;
    } 
    
    float flr = box(p+vec3(0,7.5,0),vec3(2.75,5.5,2.75));
    flr = max(flr,-vcap(pu+vec3(0,3.,0),15.,.5 ) );
    if(flr<res.x)
    {
        res = vec2(flr,2.);
        hit=p;
    }  
    
    res.x*=.75;
    return res;
}

vec3 normal(vec3 p, float t)
{
    float d = map(p).x;
    vec2 e = vec2(t,0);
    
    vec3 n = d-vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
    );
    return normalize(n);
}

vec3 hue(float t)
{ 
    vec3 d = vec3(0.702,0.961,0.220);
    return .575 + .375*cos(PI2*t*(vec3(.985,.98,.99)*d)); 
}

const vec3 lpos = vec3(.1,9,7);

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n)
{
    vec3 l = normalize(lpos-p);

    float diff = clamp(dot(n,l),0.,1.);

    vec3 h = vec3(0);
    if(m==1.)h=hue(sid.y+15.);
    if(m==2.) {
        vec3 f = fract(p*.35)-.5;
        h=(f.x*f.y*f.z>0.)?vec3(0.894,0.871,0.824):vec3(0.141,0.141,0.141);
    }
    if(m==3.)h=hue(sid.x+2.);
    if(m==4.)h=hue(sid.y);
    if(m==5.)h=hue(sid.x);
    if(m==6.)h=vec3(0.898,0.953,0.980);
    return diff*h;
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;

    rt1 =  665.+T * 125.* PI / 180.0;
    rt2 = -T *  75.* PI / 180.0;
    
    tr1 = rot(rt1);
    tr2 = rot(rt2);

    vec3 C=vec3(.01);
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    // uv = floor(uv*(76.*R.x/R.y))/(76.*R.x/R.y);
    vec3 ro = vec3(0,.5,9),
         rd = normalize(vec3(uv,-1));

    getMouse(ro,rd);

    vec3  p = ro + rd * .1;
    float atten = .65;
    float k = 1.;
    float o = 0.;
    
    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    
    for(int i=0;i<155;i++)
    {
        vec2 ray = map(p);
        float d = ray.x;
        float m = ray.y;
        sid=fid;
        float fresnel=0.;
        
        o +=ray.x;
        p += rd * d *k;
        
        if (d*d < 1e-7) {
            hp=hit;
            o*=.65;

            vec3 n = normal(p,d);
            C+=shade(hp,rd,d,ray.y,n)*atten;

            atten *= .75;
            p += rd*.005;
            k = sign(map(p).x);
            
            fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 8.);
            fresnel = mix(.001, .990, fresnel);
            
            vec3 rr = vec3(0);
            //reflect or refract
            if(m==2.||m==6.){
               rr=reflect(-rd,n);
               p+=n*.1;
            }else{
                if(int(F.x)%2 != int(F.y)%2) {
                   rr = refract(rd,n,.75);
                }else{
                   rr=reflect(-rd,n);
                   p+=n*.1;
                }
            }
            rd=mix(rr,rd, fresnel);
        }
        
        if(distance(p,rd)>50.) { break; }
    }
    // Output to screen
    glFragColor = vec4(sqrt(smoothstep(0.,1.,C)),1.0);
}

//end
