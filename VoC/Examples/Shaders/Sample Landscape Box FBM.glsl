#version 420

// original https://www.shadertoy.com/view/7s3SDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define lin2sRGB(x) ( x <= .0031308 ? (x)*12.92 : 1.055*pow(x,1./2.4) - .055 )

const float ANIM_SPEED=5.;

const float SEED=3.42;

const int MAX_STEP=50;
const float MIN_DIST=.0001;
const float MAX_DIST=80.;

struct Light{
    vec3 pos;
    float intensity;
    vec3 color;
};

struct Hit{
    float dist;
    vec4 objId;
    vec3 pos;
    vec3 normal;    
};

//  from DAVE HOSKINS
vec3 N13_(float p) {
    p=p*SEED;
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float hash1( vec2 p )
{
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float hash1( float n )
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

vec2 hash2( vec2 p ) 
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    float n = 111.0*p.x + 113.0*p.y;
    return fract(n*fract(k*n));
}

float tri(in float x){return abs(fract(x)-.5);}
vec3 tri3(in vec3 p){return vec3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}
                                 

float triNoise3d(in vec3 p, in float spd)
{
    float z=1.4;
    float rz = 0.;
    vec3 bp = p;
    for (float i=0.; i<=3.; i++ )
    {
        vec3 dg = tri3(bp*2.);
        p += (dg+time*spd);

        bp *= 1.8;
        z *= 1.5;
        p *= 1.2;
        
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
    }
    return rz;
}

float getzoffset(){
   return time/ANIM_SPEED;
}

mat2 rotate2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

float map01(float min,float max, float val){
    return val=clamp((val-min)/(max-min),0.,1.);
}

 

//from https://www.iquilezles.org/www/articles/smin/smin.htm
vec2 sminN( float a, float b, float k, float n )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    float m = pow(h, n)*0.5;
    float s = m*k/n; 
    return (a<b) ? vec2(a-s,m) : vec2(b-s,m-1.0);
}

float computeId(vec3 p,vec3 rep){
   
    return dot(floor((rep*.5+p)/rep),vec3(1.,10.,100.));
    
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
float sph( vec3 i, vec3 f, vec3 c )
{
    // random radius at grid vertex i+c (please replace this hash by
    // something better if you plan to use this for a real application)
    vec3  p = 17.0*fract((i+c)*0.3183099+vec3(0.11,0.17,0.13));
    float w = fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
    float r = 0.7*w*w;
    return sdBox(f-c,vec3( r));//*(.5+.5*sin(time)))); 
}

// https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
float sdBase( in vec3 p )
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    return min(min(min(sph(i,f,vec3(0,0,0)),
                       sph(i,f,vec3(0,0,1))),
                   min(sph(i,f,vec3(0,1,0)),
                       sph(i,f,vec3(0,1,1)))),
               min(min(sph(i,f,vec3(1,0,0)),
                       sph(i,f,vec3(1,0,1))),
                   min(sph(i,f,vec3(1,1,0)),
                       sph(i,f,vec3(1,1,1)))));
}

// https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
vec2 sdFbm( in vec3 p, in float d )
{
    // rotation and 2x scale matrix
    const mat3 m = mat3( 0.0,  1.60,  1.20,
                        -1.23,  0.72, -0.96,
                        -1.20, -0.76,  1.28 );
    vec3  q = p;
    float t = 0.0;
    float s = 2.*(.6+.4*(sin(p.z*.5)*sin(p.x*.5)));
     int ioct = int(floor(12.*(.5+.5*sin(time))));
    for( int i=0; i<10; i++ )
    {
        if( d>s*.5) break; // early exit
       // if( s<th ) break;      // lod
        
        float n = s*sdBase(q);
        n = smax(n,d-0.1*s,0.2*s);
        d = smin(n,d      ,0.2*s);
        q = m*q;
        s = 0.415*s;

        t += d; 
        q.z += -2.33*t*s; // deform things a bit
    }
    return vec2( d, t );
}   

Hit getDist(vec3 p,bool checkplane){
  /*  p=p+vec3(0,0,getzoffset());
    p.xz*=rotate2D(time/30.);
    p+=vec3(0,0,-getzoffset());*/
    float objId=1.;
    vec3 col=vec3(1.);
    float dist=MAX_DIST;
    dist=min(dist,p.y+.2);
    dist=min(dist,sdFbm(p,dist).x);
    if(checkplane){
    float delta=triNoise3d(p,.2)*.01;//(dist)/3.;
    dist=min(dist,p.y+.1+delta);
    if(p.y<-(.099-2.*delta))
        objId=2.;
    }
  //  dist=smin(dist,length(p-vec3(0,1.,2.-getzoffset()))-1.5,1.);
    return Hit(dist,vec4(objId,col),vec3(0),vec3(0));
}

Hit getDist(vec3 p){
    return getDist(p,true);
}

vec3 getNormal(vec3 pos){
    vec2 e=vec2(.0001,0);
    float dist=getDist(pos).dist;
    vec3 n=vec3(
        dist-getDist(pos-e.xyy).dist,
        dist-getDist(pos-e.yxy).dist,
        dist-getDist(pos-e.yyx).dist);
    return normalize(n);
}

Hit rayMarch(vec3 o,vec3 ray,float speed){
    float totalDist=0.;
    Hit hit;
    
    
    for(int i=0;i<MAX_STEP;i++){
        vec3 p=o+totalDist*ray;
        hit=getDist(p);
        totalDist+=hit.dist*speed;
        if(hit.dist<MIN_DIST*speed||totalDist>MAX_DIST) break ;
    }
    if(totalDist<MAX_DIST){
        vec3 pos=o+ray*totalDist;
        return Hit(totalDist,hit.objId,pos,vec3(0.));
    }
    else{
        return Hit(totalDist,vec4(-1),vec3(0),vec3(MAX_DIST));
    }
    
}

Hit rayMarch(vec3 o,vec3 ray){
 return rayMarch(o,ray,1.);
}

float softshadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;

    for( float t=MIN_DIST; t<MAX_DIST; )
    {
        float h = getDist(ro + rd*t,false).dist;
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

float computeao(vec3 ro, vec3 rd)
 {
    //return 1.;
    float tot = 0.;

    float fact = 1.0;
    for (float i = 0.; i < 5.; i++)
    {

        float hr = 0.01 + 0.01 *i;
        vec3 p = ro + rd * hr;
        float d = getDist(p,false).dist;
        float ao = clamp((d*5.), 0.0, 1.0);

        tot += ao * fact;
        fact *= 0.75;
    }

    tot = 1.0 - clamp(tot*4., 0.1, .8);
    return tot;
 }

vec2 getmousePos(){
    return(vec2(sin(time),.4+.6*cos(time)));
   // return ((mouse*resolution.xy.xy-.5*resolution.xy)/resolution.y);

}

vec3 computeLighting(vec3 hitPos,vec3 n,vec3 ray){

  float zoffset=getzoffset();
  vec3 sunpos=vec3(getmousePos()*20.,30.-getzoffset());
  vec3 suncolor=mix(vec3(1.),vec3(.9,.4,.1),dot(normalize(sunpos),vec3(0,1,0)));
  vec3 sunDir=normalize(sunpos-hitPos);
float occ = computeao( hitPos, n );
float sha = softshadow( hitPos+n*.01, sunDir,20.);
float sun = clamp( dot( n, sunDir ), 0.0, 1.0 );
float sky = clamp( 0.5 + 0.5*n.y, 0.0 ,1.0 );
float ind = clamp( dot( n, normalize(sunDir*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );

vec3 lin  = sun*suncolor*sha;//pow(vec3(sha),vec3(1.0,1.2,1.5));
        lin += sky*vec3(0.16,0.20,0.28)*occ;
        lin += ind*vec3(0.40,0.28,0.20)*occ;

       return lin;
}

vec4 render(vec3 ray,Hit hit){

 
    
  //  Hit hit=rayMarch(ro,ray);
    hit.normal=getNormal(hit.pos);//hit.objId.x!=2. && hit.objId.x!=-1.?getNormal(hit.pos):vec3(0,1.,0);//normalize(vec3(1.*(.5+.5*cos(hit.pos.x*10.)),1.*(.5+.5*sin(hit.pos.z*100.)),1.*(.5+.5*-cos(hit.pos.x*10.))));

    

        vec3 sunpos=vec3(getmousePos()*40.,30.-getzoffset());

    
    float fogAmount = 1.0 - exp( -hit.dist*.2 );
    float sunAmount = max( dot(normalize(sunpos), vec3(0,1.,0) ), 0. );
    vec3  fogColor  = mix( vec3(0.8,0.4,0.3), 
                           vec3(.15,0.4,0.8), 
                           pow(min(sunAmount*(2.-dot(normalize(vec3(0,-sunpos.y,0)),ray))*5.,1.),8.)) ;
    
    vec3 saveray=ray;
    
    
    
    vec3 colSphere;
    
    //vec3 fog=vec3(.2,.3,.9);
//   fog=mix(fog/10.,fog,sunincident);
//    fog*=(map01(0.,4.,hit.pos.z+getzoffset()));
    //only compute reflexion on close objects
    
    if(hit.objId.x>-1.){
     //   if(hit.objId.x!=2.)hit.normal*=-1.;
        vec3 col=computeLighting(hit.pos,hit.normal,saveray);
        vec3 colsp;
        if(hit.objId.x<2.){
            colsp=colsp=mix(vec3(.8,.7,.5),vec3(.35,.62,.2),dot(hit.normal,vec3(0,1.,0)));
        }
        else
            colsp=vec3(.1);
       colSphere=vec3(colsp*col);
    }
    else{
    //    olddist=hit.dist;
        colSphere=vec3(triNoise3d(saveray*.8*vec3(.3,1.,1.),.02))*.7;
        fogAmount=1.-saveray.y*2.;
        }
    colSphere=mix( colSphere, fogColor, fogAmount);
    colSphere*=min(dot(normalize(sunpos), vec3(0,1.,0) )*10.+.2,1.);
    return vec4(colSphere,1.);

   // return colSphere;
}

void main(void)
{
  
    
     vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t=time/ANIM_SPEED;
    
    vec2 mousePos=getmousePos();
    
    float zoffset=getzoffset();
    
    //camera model from https://www.youtube.com/watch?v=PBxuVlp7nuM
    vec3 camera=vec3(0,.3,10.-zoffset);//-20.*(1.+sin(t)));
    vec3 lookAt=vec3(0,-.7,-zoffset);
    float zoom=1.;
    vec3 f=normalize(camera-lookAt);
    vec3 r=cross(vec3(0,1.,0),f);
    vec3 u=cross(f,r);
    
    vec3 c=camera-f*zoom;
    vec3 i=c+uv.x*r+uv.y*u;
    vec3 ray=normalize(i-camera);
    
    
    float fresnel=0.;
    float olddist=-1.;
    Hit h=rayMarch(camera,ray);
    glFragColor=render(ray,h);
    if(h.objId.x>1. && h.dist<5.5){
   
        vec3 n=getNormal(h.pos);
                
        ray=reflect(ray,n);
        float fresnel=1.-dot(n,ray);
        h=rayMarch(h.pos+n*.001,ray,3.);

    glFragColor+=render(ray,h)*pow(map01(.2,.8,fresnel),5.);
    }
   //gamma correction
    glFragColor.r=lin2sRGB(glFragColor.r);
    glFragColor.g=lin2sRGB(glFragColor.g);
    glFragColor.b=lin2sRGB(glFragColor.b);
    
    
}

