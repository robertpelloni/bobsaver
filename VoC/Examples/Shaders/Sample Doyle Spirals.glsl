#version 420

// original https://www.shadertoy.com/view/4tffDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Doyle Spirals. Port from fragmentarium shader done a long time ago.
//Links:
//http://www.josleys.com/show_gallery.php?galid=265
//http://www.josleys.com/article_show.php?id=3
//http://klein.math.okstate.edu/IndrasPearls/cusp.pdf
//Public domain

//WIP:
//ToDo: Antialiasing

#define PI 3.14159

//Constants
//These control the shape of the spiral
const int P = 7;
const int Q = 17;//should be at least 3

//Want do do an inversion?
const bool DoInversion = true;//false;
//Inversion center
const vec2 InvCenter = vec2(.7,0.);
//Inversion radius squared
const float InvRadius = 1.;

//to change the radius of the discs
float SRadScl = 1.;

const float DRadius=0.7, Width=1.4, Gamma=2.2;
//const vec3 BackgroundColor = vec3(1.);
//const vec3 CurveColor = vec3(0.);

//Initialisations
//all the initialization calculations done here could be (and should be) done in the host program.

//Global variables
float lambda,ca,sa,lscl;
float aaScale;
float Angle=60.;
vec2 csa;

mat2 Mat,iMat;
vec4 rads, xps, yps;

//given an etimated z find the solution to Doyle spiral equations using Newton-Raphson method
//The equations are:
//r=(exp(2*z.x)-2*exp(z.x)*cos(z.y)+1)/(exp(z.x)+1)
//r=(exp(2*zt.x)-2*exp(zt.x)*cos(zt.y)+1)/(exp(zt.x)+1)
//r=(exp(2*z.x)-2*exp(z.x)*exp(zt.x)*cos(z.y-zt.y)+exp(2*zt.x))/(exp(z.x)+exp(zt.x))
//z.x*p=zt.x*q
//z.y*p+2*PI=zt.y*q; In reality it should be:z.y*p+2*k*PI=zt.y*q; k is in Z set; I haven't esplored other values of k than 1
//z corresponds to similarity 'a' and zt to similarity 'b'
//a=exp(z); and b=exp(zt); because these are complex numbers :)
vec2 solve(vec2 z){
    //Newton-Raphson method
    float k=float(P)/float(Q);
    for(int i=0; i<2;i++){//2 iterations are usually sufficient: the convergence is very fast. especially when P o=and/or Q are relatively big
        float lb=z.x*k, tb=z.y*k+2.*PI/float(Q);
        float ra=exp(z.x),rb=exp(lb),ca=cos(z.y),cb=cos(tb),cab=cos(z.y-tb);
        //compute function values
        vec3 v=vec3((ra*ra-2.*ra*ca+1.)/((ra+1.)*(ra+1.)),
                         (rb*rb-2.*rb*cb+1.)/((rb+1.)*(rb+1.)),
                         (ra*ra-2.*ra*rb*cab+rb*rb)/((ra+rb)*(ra+rb)));
        vec2 f=v.xy-v.yz;
        //compute jacobian
        vec3 c=2.*vec3( ra/((ra+1.)*(ra+1.)), k*rb/((rb+1.)*(rb+1.)), (1.-k)*ra*rb/((ra+rb)*(ra+rb)) );
        vec3 v0= c*vec3( (1.+ca)*(ra-1.)/(ra+1.), (1.+cb)*(rb-1.)/(rb+1.), (1.+cab)*(ra-rb)/(ra+rb) );
        vec3 v1= c*sin(vec3(z.y,tb,z.y-tb));
        mat2 J = mat2(0.);
        J[0]=v0.xy-v0.yz; J[1]=v1.xy-v1.yz;
        //compute inverse of J
        float idet=1./(J[0][0]*J[1][1]-J[0][1]*J[1][0]);
        mat2 iJ=-J;
        iJ[0][0]=J[1][1];
        iJ[1][1]=J[0][0];
        //next value
        z-=idet*( iJ*f);
    }
    return z;
}

void init() {
    //find estimate
    //notice that for big P and/or Q the packing will look just like hexagonal one
    //if we take the centers of all packed circles in log-polar plane we will get almost a triangular array
    //That's why I'm using log-polar plane
    //notice also the link to drost effect ;)
    //Someone already noticed that before: http://gimpchat.com/viewtopic.php?f=10&t=3941
    vec2 v=vec2(-float(P)+float(Q)*0.5,float(Q)*sqrt(3.)*0.5);
    float vd=1./length(v);
    float scl=2.*PI*vd;
    vec2 z=scl*vd*v.yx;
    z=solve(z);
    float k=float(P)/float(Q);
    vec2 zt=vec2(z.x*k,z.y*k+2.*PI/float(Q));
    Mat[0]=z;Mat[1]=zt;
    iMat=-Mat;
    iMat[0][0]=Mat[1][1]; iMat[1][1]=Mat[0][0];
    iMat*=1./(Mat[0][0]*Mat[1][1]-Mat[0][1]*Mat[1][0]);
    float ra=exp(z.x),rb=exp(zt.x),ca=cos(z.y);
    float rs=sqrt((ra*ra-2.*ra*ca+1.)/((ra+1.)*(ra+1.)));//radius of the circle centered at (1,0)
    rs*=SRadScl;//for some variations
    rads=rs*vec4(1., ra, rb, ra*rb);//radius for the 4 circles in the fundamental domain
    xps=vec4(1.,ra*ca,rb*cos(zt.y),ra*rb*cos(z.y+zt.y));//Their x coordinates
    yps=vec4(0.,ra*sin(z.y),rb*sin(zt.y),ra*rb*sin(z.y+zt.y));//y
}

//End initialisations

vec4 CDoyle(vec2 z){
    vec2 p=z;
    //transform to the plane log-polar
    p=vec2(log(length(p)), atan(p.y,p.x));
    //transform into the "oblique" base (defined by z and zt in vinit() function above)
    vec2 pl=iMat*p;
    //go to the losange defined by z and zt (as defined in vinit())
    vec2 ip=floor(pl);
    pl=pl-ip;
    //back to log-polar plane
    pl=Mat*pl;
    //scale and delta-angle
    float scl=exp(pl.x-p.x),angle=pl.y-p.y;
    //the original z is scaled and rotated using scl and angle
    z*=scl;
    float c=cos(angle),s=sin(angle);
    z.xy=z.xy*mat2(vec2(c,-s),vec2(s,c));//tourner z
    //distances to the spheres that are inside the fundamental domain
    vec4 vx=vec4(z.x)-xps;
    vec4 vy=vec4(z.y)-yps;
    //vec4 vz=vec4(z.z);
    vec4 dists=sqrt(vx*vx+vy*vy)-rads;
    //take the minimal distance
    float mindist=min(min(dists.x,dists.y),min(dists.z,dists.w));
    if(mindist>0.) return vec4(vec3(-0.1),0.);
    //which is the nearest sphere
    bvec4 bvhit=equal(dists,vec4(mindist));
    int mindex=int(dot(vec4(bvhit),vec4(0.,1.,2.,3.)));
    const mat4 set=mat4(vec4(0.,0.,0.,0.),vec4(1.,0.,1.,0.),vec4(0.,1.,1.,0.),vec4(1.,1.,2.,0.));
    vec3 minprop=set[mindex].xyz;
    vec3 bc=vec3(ip,ip.x+ip.y)+minprop;
    bc=bc/vec3(P,Q,max(float(abs(P-Q)),1.));
    bc-=floor(bc);
    
    return vec4(bc,mindist);//serves for the coloring
}

float coverageFunction(float t){
    //this function returns the area of the part of the unit disc that is at the rigth of the verical line x=t.
    //the exact coverage function is:
    //t=clamp(t,-1.,1.); return (acos(t)-t*sqrt(1.-t*t))/PI;
    //this is a good approximation
    return 1.-smoothstep(-1.,1.,t);
    //a better approximation:
    //t=clamp(t,-1.,1.); return (t*t*t*t-5.)*t*1./8.+0.5;//but there is no visual difference
}

float coverageLine(float d, float lineWidth, float pixsize){
    d=d*1./pixsize;
    float v1=(d-0.5*lineWidth)/DRadius;
    float v2=(d+0.5*lineWidth)/DRadius;
    return coverageFunction(v1)-coverageFunction(v2);
}

vec3 color(vec2 p) {
    if(DoInversion){
        p=p-InvCenter;
        float r2=dot(p,p);
        p=(InvRadius/r2)*p+InvCenter;
    }
    float ang = time * 0.25;
    float c = cos(ang), s = sin(ang);
    mat2 rot = mat2(vec2(c,-s), vec2(s,c));
    vec4 col = CDoyle(rot*p);
    col.rgb = sin(2.*PI*col.rgb+.0)*0.5+0.5;
    return col.rgb;//pow(0.9*col, vec3(.42));
}

void main(void)
{
    const float scaleFactor=1.4;
    vec2 uv = scaleFactor*(gl_FragCoord.xy-0.5*resolution.xy) / resolution.y;
    SRadScl = sin(time)*0.05+0.95;
    init(); 
    glFragColor = vec4(color(uv),1.0);
}
