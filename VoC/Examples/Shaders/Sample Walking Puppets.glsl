#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NdtSR4

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Walking puppets by Kastorp
//-----------------------------------------------------
// set this parameter to 1 to enable Parallel rendering with raymarching (not optimized) 
#define MODE 0 //0=ONLY TRACING 1=BOTH, 2=ONLY MARCHING 
//------------------------------------------------------
#define NOHIT 1e5
#define ZERO min(frames, 0)
#define time time*2.

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

//-----------Interscetion functions--------------------
vec3 oFuv; 
vec4 iSphere( in vec3 ro, in vec3 rd, float ra )
{
#if (MODE<2)
    vec3 oc = ro ;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0. ) return vec4(NOHIT); // no intersection
    h = sqrt( h );
    vec3 n =normalize(ro-(b+h)*rd); oFuv=vec3(0.,atan(n.y,length(n.xz)),atan(n.z,n.x))*ra*1.5708  ;
    return h-b < 0. ? vec4(NOHIT) : -b-h>=0. ?  vec4(-b-h,n): vec4(0.);
#else
    return vec4(NOHIT);
#endif
}

vec4 iBox( in vec3 ro, in vec3 rd, vec3 boxSize) 
{
#if (MODE<2)
    vec3 m = 1.0/rd; // can precompute if traversing a set of aligned boxes
    vec3 n = m*ro;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m)*boxSize;

    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.) return vec4(NOHIT); // no intersection
    vec3 nor = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz); 
    oFuv=vec3( dot(abs(nor),vec3(1,5,9)+ nor)/2.,dot(ro+rd*tN,nor.zxy),dot(ro+rd*tN,nor.yzx));   
    return tN<0.? vec4(0.): vec4(tN,nor);
#else
    return vec4(NOHIT);
#endif
}

vec4 iPlane( in vec3 ro, in vec3 rd, in vec3 n ,float h)
{
#if (MODE<2)
    float d= -(dot(ro,n)+h)/dot(rd,n);
    oFuv.yz=(ro+d*rd).xz;
    return d>0.?vec4(d,n):vec4(NOHIT);
#else
    return vec4(NOHIT);
#endif
}

//------SDF Functions--------------------------------

float sPlane( vec3 p, vec3 n, float h )
{
#if (MODE>0)
  return dot(p,n) + h;
#else
    return NOHIT;
#endif  
}

float sBox( vec3 p, vec3 b )
{
#if (MODE>0)
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
#else
    return NOHIT;
#endif
}
float sSphere( in vec3 p,  float ra )
{
#if (MODE>0)
    return length(p)-ra;
#else
    return NOHIT;
#endif
}

//---------mixed functions--------------------------
struct RayIn{
    vec3 rd;
    float t; 
};

struct RayOut{   
    float d; 
    vec3 n;
    vec3 fuv;
    float id;
};

RayOut sRayOut(float d,float id) {return RayOut(d,vec3(0),vec3(0),id);}
RayOut tRayOut(vec4 d,float id) {vec4 t=d; return RayOut(d.x,d.yzw,oFuv,id);}

const RayIn rSDF=RayIn(vec3(0),-1.);

RayOut RotSphere( in RayIn m,vec3 p, float ra ,float a, float id)
{
    if(m.t<0.) return  sRayOut(sSphere(  p,  ra ),id);
    else{
        vec4 v = iSphere(p,m.rd,ra);
        oFuv.z-=a*ra*1.57;
        return  tRayOut(v,id);
    }
}

RayOut Box(  in RayIn m,vec3 p, in vec3 b,float id)
{
    if(m.t<0.) return  sRayOut(sBox(  p,b ),id);
    else return  tRayOut(iBox(p,m.rd,b),id);
}

RayOut RotBox(  in RayIn m, vec3 p, in vec3 b, vec3 ax, vec3 c, float a,float id)
{
    vec3 pr=  c+ erot( p-c , ax, a); 
    m.rd=  erot( m.rd , ax, a); 
    if(m.t<0.) return  sRayOut(sBox(pr ,b ),id);
    else {
          vec4 d=iBox(pr,m.rd,b);
          return RayOut(d.x,erot( d.yzw , ax, a),oFuv,id);
    }
}
RayOut Plane(  in RayIn m, vec3 p, in vec3 n ,float h,float id)
{
    if(m.t<0.) return  sRayOut(sPlane(  p,n,h ),id);
    else return  tRayOut(iPlane(p,m.rd,n,h),id);
}

RayOut Union( RayOut a, RayOut b)
{
   if(a.d<b.d) return a;
   else return b;
}
#define Add(_ro,_func) _ro = Union(_ro,_func);

#define  RotView( p, _ri,_ro, _ax,  _c ,  _a,  _body) \
    p=  _c+ erot( p-_c , _ax, _a); \
    _ri.rd=  erot( _ri.rd , _ax, _a); \
    _body \
    _ro.n=erot( _ro.n , _ax, -_a); 

//------------------------------------

RayOut oRay;
float map(in RayIn m0,vec3 p0 ) { 
    RayOut r =  Plane(m0,p0,vec3(0,1.0,0),0.,1.);
    
   //rotate(p0,m0, vec3(1,0,0),vec3(0,1,0), time*1.2);
   float s=2.5,n=2.;
   RayOut r0=Box(m0,p0,vec3(1.8+s*n,2.2,1.8+s*n),2.); //bounding box:  group
   if(( m0.t<0.  && r0.d <.5) || (m0.t>=0. && r0.d>=0. && r0.d<NOHIT)){
    
    for(float x=-s*n;x<=s*n;x+=s) for(float y=-s*n;y<=s*n;y+=s){ //iterate over players
    float a = -time*.3 -x*.45+y*.55;
        vec3 p=p0-vec3(x,0,y)-vec3(cos(a),0,sin(a))*1.2; 
        r0=Box(m0,p,vec3(.6,2.2,.6),2.);//bounding box:  player
        if((m0.t<0. && r0.d <.5) || (m0.t>=0. && r0.d>=0. && r0.d<NOHIT)){
            RayIn ri_player=m0;
            Add(r,RotSphere(ri_player,p-vec3(0,2.,0),.18,a,3.)); //todo fix head rotation
           
            RayOut ro_player;
            RotView(p,ri_player,ro_player, vec3(0,1,0),vec3(0.,0,0), a, //player rotation
                
                ro_player=  Box(ri_player,p-vec3(0,1.43,0),vec3(.28,.35,.1),4.);
                float mrot=.8; float rot= abs(mod(time*.5,mrot*2.)-mrot);
                Add(ro_player,RotBox(ri_player,p-vec3(+.4,1.47,0),vec3(.08,.3,.08),vec3(1,0,0),vec3(0,0.25,0),rot-mrot*.5,5.));
                Add(ro_player,RotBox(ri_player,p-vec3(-.4,1.47,0),vec3(.08,.3,.08),vec3(1,0,0),vec3(0,0.25,0),mrot*.5 -rot,5.));    
                Add(ro_player,RotBox(ri_player,p-vec3(+.17,.5,0),vec3(.08,.5,.08),vec3(1,0,0),vec3(0,0.35,0),mrot*.5 -rot,6.));
                Add(ro_player,RotBox(ri_player,p-vec3(-.17,.5,0),vec3(.08,.5,.08),vec3(1,0,0),vec3(0,0.35,0),rot-mrot*.5,6.));
            );
           
            r= Union(r,ro_player);
        } else if( r0.d >=.5) r=Union(r,r0); //outside player BB
    }
    }else if( r0.d >=.5) r=Union(r,r0);//outside group BB
    oRay=r;
    return r.d;
}
vec3[6] mat = vec3[6](vec3(0.184,0.380,0.082),vec3(0.859,0.420,0.420),vec3(0.769,0.471,0.471),vec3(0.141,0.310,0.439),vec3(0.851,0.408,0.408),vec3(0.824,0.416,0.416));

//------------------------------------
float trace(vec3 ro, vec3 rd) {
    return map( RayIn(rd,0.), ro);
}

float march(vec3 ro, vec3 rd) {
    // Raymarch.
    vec3 p;
    float d = .01;
    for (float i = 0.; i < 120.; i++) {
        p = ro + rd * d;
        float h = map(rSDF,p);
        if (abs(h) < .0015)
            break;
        d += h;
        if(d>500.) break;
    }
    return d;
}

float ray(vec3 ro, vec3 rd,bool tracing){
 return  tracing? trace(ro,rd): march(ro,rd); 
}

vec3 calcN(vec3 p, float t) {
    float h = .002 * t;
    vec3 n = vec3(0);
    
    for (int i = ZERO; i < 4; i++) {
        vec3 e = .5773 * (2. * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.);
        n += e * map(rSDF,p + e * h);
    }

    return normalize(n);
}

float calcSoftshadow( in vec3 ro, in vec3 rd, float tmin, float tmax, const float k )
{
  
    float res = 1.0;
    float t = tmin;
    for( int i=0; i<100; i++ )
    {
        float h = map(rSDF, ro + rd*t );
        res = min( res, k*h/t );
        t += clamp( h, 0.02, 0.20 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
    
}

float ao(vec3 p, vec3 n, float h) {
    return map(rSDF,p + h * n) / h;
}

#define MM (mouse*resolution.xy.x>0.?mouse*resolution.xy.x/resolution.y -.5*resolution.x/resolution.y:-.5*resolution.x/resolution.y)

vec3 lights(vec3 p, vec3 rd, float d,bool tracing) {
    vec3 lightDir = normalize( vec3(8.,19.,18.) );
    vec3 ld = normalize(lightDir*16.5 - p), 
    n = tracing? oRay.n:calcN(p, d) ;

    float ao =tracing? 1.: .1 + .9 * dot(vec3(ao(p, n, .05), ao(p, n, .3), ao(p, n, .5)), vec3(.2, .3, .5)),
    l1 = max(0., .5 + .5 * dot(ld, n)),
    
    spe = max(0., dot(rd, reflect(ld, n))) * .1,
    fre = smoothstep(.7, 1., 1. + dot(rd, n));
   
    vec3 pp=p+.001*n;    
    if(tracing) l1 *=    smoothstep(.001,500., ray(pp,ld,tracing));
     else  l1*=calcSoftshadow(pp, ld,.01,13.,17.5);
     
    vec3 lig = ((l1 *.9+.1)* ao + spe) * vec3(1.) *2.5;
    return mix(.3, .4, fre) * lig;
}

vec3 getRayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

void main(void)
{
    
    float t= .4;//-time*.5;
    vec3 ro =2.*vec3(3.*cos(t), 1., 3.*sin(t));
    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 rd =  getRayDir(ro, vec3(0,1,0), uv);
        
    //left:raymarching with SDF, right:ray tracing with intersectors
#if (MODE==1)
    bool tracing=(uv.x>MM || uv.x<MM-.3) ;  
#else
    bool tracing= MODE<1;
#endif 
   float d=ray(ro,rd,tracing);
      
    vec3 p=ro+rd*d; 
    vec3 alb=mat[int(oRay.id)-1];
    vec2 uvt= fract(oRay.fuv.yz)-.5;
    if(uvt.x*uvt.y<0.)alb*=.75;
    //if(oRay.id>=4. && oRay.fuv.x==5.) alb*=0.;
    
    vec3 col=lights(p, rd, d,tracing) * exp(-d * .085)*alb;
    //if(MODE==1) col=mix(col,vec3(1,0,0),smoothstep(.005,0.,abs(abs(uv.x-MM+.15)-.15)));
    glFragColor = vec4(pow(col, vec3(.45)), 0);
}
