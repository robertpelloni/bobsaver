#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dsyzS

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( float n ) {
    return fract(sin(n)*43758.5453);
}

float snoise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.-2.*f);

    float n = p.x + p.y*57. + 113.*p.z;

    float res = mix(mix(mix( hash(n+  0.), hash(n+  1.),f.x),
                        mix( hash(n+ 57.), hash(n+ 58.),f.x),f.y),
                    mix(mix( hash(n+113.), hash(n+114.),f.x),
                        mix( hash(n+170.), hash(n+171.),f.x),f.y),f.z);
    return res * 2.0 - 1.0;
}

    

mat2 Rot(float a){

    float c = cos(a);
    float s = sin(a);
    return mat2(c,-s,s,c);
}

vec3 Transform ( vec3 p ){
    p.xy *= Rot(p.x*.15);
    p.z -= time * .1;

    
    p += sin(p.x+p.z+time)*.03
        +sin(p.y+time)*.05
        +cos(p.x+p.z+time)*.03
        -cos(p.x+time)*.03
        +cos(p.y+time)*.05;
        
    p.xy *= Rot(time*.0015);
    
    p.xy *= Rot(p.z*0.15);
    return p;
    
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) {
    p *= scale;
    return abs(dot(sin(p), cos(p.zxy))+bias)/scale - thickness;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float line( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float smin(float a, float b, float k)
{
    float h=clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b,a,h)-k*h*(1.0-h);
}

float smax(float a, float b, float k)
{
   
    float h = clamp( 0.5 + 0.5*(a-b)/k, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*k;
}
vec2 opUMin( vec2 a, vec2 b, float k ) { 
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 ); 
    return vec2( mix( b.x, a.x, h ) - k*h*(1.0-h), (a.x<b.x) ? a.y : b.y ); 
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

const float PI  = 3.14159265359;
const float PHI = 1.61803398875;

void basis(vec3 n, out vec3 b1, out vec3 b2) 
{
    if(n.y<-0.999999) 
    {
        b1=vec3(0,0,-1);
        b2=vec3(-1,0,0);
    } 
    else 
    {
        float a=1./(1.+n.y);
        float b=-n.x*n.z*a;
        b1=vec3(1.-n.x*n.x*a,-n.x,b);
        b2=vec3(b,-n.z,1.-n.z*n.z*a);
    }
}

vec4 invsf(vec3 p, float n)
{
    float m=1.-1./n;
    float phi=min(atan(p.y,p.x),PI);
    float k=max(2.,floor(log(n*PI*sqrt(5.)*
                             (1.-p.z*p.z))/log(PHI+1.)));
    float Fk=pow(PHI,k)/sqrt(5.);
    vec2  F=vec2(round(Fk), round(Fk*PHI));
    vec2 ka=2.*F/n;
    vec2 kb=2.*PI*(fract((F+1.)*PHI)-(PHI-1.));    
    mat2 iB=mat2(ka.y,-ka.x, 
                    kb.y,-kb.x)/(ka.y*kb.x-ka.x*kb.y);
    
    vec2 c=floor(iB*vec2(phi, p.z-m));
    float d=0.;
    vec4 res=vec4(0);
    for(int s=0; s<4; s++) 
    {
        vec2 uv=vec2(s&1,s>>1);
        float i=dot(F,uv+c); 
        float phi=2.*PI*fract(i*PHI);
        float ct=m-2.*i/n;
        float st=sqrt(1.-ct*ct); 
        
        vec3 q=vec3(cos(phi)*st, 
                    sin(phi)*st, 
                    ct);
        float d1=dot(p,q);
        if(d1>d) 
        {
            d=d1;
            res=vec4(q,d);
        }
    }
    return res;
}

float udRoundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}

vec2 Virus( vec3 p, float atime){
    
    
    
    p = p - vec3(sin(atime+2.0)*.1,sin(atime)*.1+sin(atime)*.02+0.2,0);
    float t=mod(atime,1.5)/1.5;
    p*=1.-0.05*clamp(sin(6.*t)*exp(-t*4.),-2.,2.);

    p.xy *= Rot(0.04*atime);
    p.xz *= Rot(0.06*atime);
    p += sin(p.x+p.z+atime)*.01+sin(p.y+atime)*.042*p.y;
    
    
    float cvwidth = .52;
    
    vec3 r,f;
    vec4 fibo=invsf(normalize(p),35.);
    p += sin(p.x+p.z+atime)*.01+sin(p.y+atime)*.042*fibo.w*1.;
    float sphere = sdSphere(p,cvwidth)  
    
    
    +(- (sin(90.*p.x)*cos(40.*p.z)*sin(90.*p.y))*.06
    - (cos(100.*p.x)*sin(100.*p.z)*sin(40.*p.y))*.06
     - (sin(100.*p.y)*sin(100.*p.z)*sin(40.*p.x))*.06)*0.1;
    
    vec2 d0Vector= vec2(sphere,2.0);
   
    
    vec3 q=p-fibo.xyz;
    vec3 n=normalize(fibo.xyz);
    basis(n,r,f);
    q=vec3(dot(r,q),dot(n,q),dot(f,q));

   
   
   
    q=q-vec3(0,-cvwidth+.05,0);
    
    float d1= sdRoundCone( q, 0.01,0.012 , 0.1);
    
    q=q-vec3(-.03,.12,0.0);
    d1 = smin(sdSphere(q, 0.002)-0.015*snoise(q*83.),d1,.1);
    
  
               
    
    vec2 d1Vector=vec2(d1,3.0);
    
    float noise=0.004*snoise(q*90.);
    
    d1 = smin(sdSphere(q-vec3(-.1,-.112,0.05), 0.0092)-noise,
             sdSphere(q-vec3(.1,-.112,.0), 0.0092)-noise,.0);
    
    d0Vector=opUMin( d0Vector,vec2(d1,4.0),0.02);
    
    d0Vector=opUMin( d0Vector,d1Vector,0.02);
    
    d0Vector.x *= .2;
    
    return d0Vector;
   
}

float cell(vec3 p, float atime){

    vec3 c = mod(abs(p),1.5) - .75;
    c.y += sin(c.z) * .15;
    c.xy *= Rot( c.z*.95) ;
    
    float r = 0.1;
//    r +=  sin(-c.z + 0.01 * c.x + 0.01 * c.y + atime * .04) *.01;
   
   
    return sdSphere(c,r);
}

vec2 Bloodstream (vec3 p, float atime){
    
    p = p - vec3(snoise(p)*sin(atime+2.0)*.165,sin(atime)*snoise(p)*0.02,0.);
    p.z += atime * .9;
    p.xy *= Rot( p.z*.5) ;
    
    
    if (abs(p.x) > 3. || abs(p.y) > 3.) {
       return vec2(100.,-1.0);
    }
    
    float d = 0.;
    
    d = cell( p,  atime);

    
    return vec2(d,5.0);
}

vec2 map(in vec3 p,float atime ){
   
   

    vec2 cv=Virus(p,atime);
//    return cv;
    vec2 b = Bloodstream (p,  atime);
    
    p = Transform(p);
    

    
    float g1 = sdGyroid(p,1.3,.03,1.4);

    float tunel = smax(2.95 - length(p.xy) + .9*cos(3.14159/32.), .75-g1, 1.) - abs(1.5-g1)*.375;
    
    float g2 = sdGyroid(p,10.76,.03,.3);
    float g3 = sdGyroid(p,20.76,.03,.3);
    float g4 = sdGyroid(p,35.76,.03,.3);
    float g5 = sdGyroid(p,60.76,.03,.3);
    
    
    g1 -= g2 * .2 * sin(atime*1.53) * cos(atime*2.34) * p.y ;
    g1 -= g3 * .2;
    g1 += g4 * .1;
    g1 += g5 * .2;
    
    tunel -= g1*.4;
    
    g1 = smin(tunel, g1,0.901); 
    
    
    vec2 vg1 = vec2(g1*.55,1.0);
    
    b = opUMin( b,vg1,.31);
    return opU( cv, b);
}

vec2 RayMarching(vec3 ro, vec3 rd,float time){

    vec2 res = vec2(-1.0,-1.0);

    float tmin = 2.;
    float tmax = 100.0;  
    
    float t = tmin;
    for( int i=0; i<516 && t<tmax; i++ )
    {
        vec2 h = map( ro+rd*t, time );
        if( abs(h.x)<(.001*t))
        { 
            res = vec2(t,h.y); 
            break;
        }
        t += h.x;
    }
    
    return res;
}
 
vec3 calcNormal(in vec3 pos,float time,float quality){
    vec3 n = vec3(0.0);
   for( int i=min(frames,0); i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+quality*e,time).x;
    }    
    return normalize(n);
}

vec3 Background ( vec3 rd){
    vec3 col = vec3(0);
    float y = abs(rd.z)*.5+.5;
    col += y*vec3(1,.4,.1)*1.;
    return col;
}

vec4 render( in vec3 ro, in vec3 rd, float time )
{ 
    
    vec3 col = vec3(0);

    vec2 res = RayMarching(ro,rd,time);
    if(res.y>-0.5){
        
        float d = res.x;
        vec3 p = ro + rd*d;
        
        
        float quality = res.y < 1.5 ?  0.016 : 0.0025;
       
            
        vec3 n = calcNormal(p,time,quality);
        vec3 ref = reflect(rd,n);
        
        vec3 light_pos   = p+vec3( 0.0, .50, 1.0 );vec3 vl = normalize( light_pos - p );
        vec3 specular = vec3( max( 0.0, dot( vl, ref ) ) );
        specular = pow( specular, vec3( 90.0 ) );
        
        p = Transform(p);
       
        
        if(res.y > 4.5) 
        { 
            vec3 light = normalize(vec3(1.0,1.0,0.5));
    
                
            vec3 mat = vec3(0.7, 0.0, 0.0);
            vec3 spec = vec3(1.0) * pow(max(dot(-rd, reflect(-light, n)), .0), 100.0);
            vec3 diff = max(0.0, dot(light, n)) * vec3(1.0);
            vec3 color = mat * (diff + spec + 0.05);
            col = color;
            
        }
        else if(res.y > 3.5)
        { 
        
            float  dif = n.y * .5 + .5;
            col = vec3(.79,0.15,0.0)*2.9*dif;
        }
        else if(res.y > 2.5)
        { 
        
            float  dif = n.y * .5 + .5;
            col += dif ;  
            col *= vec3(.79,0.0,0.0)*dif;
        }
        else if(res.y > 1.5) 
        { 
        
            float  dif = n.y * .5 + .5;
            col += dif*dif;  
            
        }
        else if(res.y > 0.5) 
        { 
            
           float  dif = n.y * .5 + .5;
            col += dif*dif ;  
            
            col *= vec3(0.8,0.02,.05);
            
            
            float g2 = sdGyroid(p,5.76,.03,.1);
            col *= smoothstep(-.1,.1,g2);
            
            
            float crackWidth = -.02 + smoothstep(0.,-.5,n.y)*.04;
            float cracks = smoothstep(crackWidth,-.043,g2);
            
            cracks *= .5 * smoothstep(.2,.5,n.y);
            
            col += cracks*vec3(0.7,0.09,.09)*4.;
            
            
            float g5 = sdGyroid(p-vec3(0,time+.23,0),2.76,.03,5.0);
            col += g5*vec3(0.7,0.,.0)*.24;
            
        }
        
        col = mix(col,Background(rd),smoothstep(0.,10.,d));
        
        col += vec3(1,.4,.1)* 2. * specular; 
        
    }
    
        
    return vec4(col,res.x);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    float t = time;
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = vec2(0.0);//mouse*resolution.xy.xy/resolution.xy;
    
    
    
    vec3 ro = vec3(0, 3, 0.);
    
    ro.yz *= Rot(-m.y*6.2831);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 ta = vec3(0.0,0.,0.4);
    vec3 rd = GetRayDir(uv, ro, ta, 0.8);
    
    vec4 res = render( ro, rd, t );
        
    vec3 col = res.xyz ;
    col *=  1.-dot(uv,uv);
    col = clamp(col, 0.0,1.0);
    col = pow(col,vec3(0.7,0.85,1.0));
    vec2 q = gl_FragCoord.xy/resolution.xy;
    col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.3 );
    
    
    float depth = min(10.0, res.w);
    glFragColor = vec4(col,1.0 - (depth - 0.5) / 2.0);
    
}

