#version 420

//brute force fractal raytracer
//steps along each ray in fixed distance incrememnts
//no distance estimation used

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;

out vec4 glFragColor;

//unremark which formula/fractal you want to render
#define Mandelbulb
//#define TNS50

//unremark which render method you want to use
#define XYZtoRGB
//#define XYZtoRGBandDistance
//#define Distance
//#define dFd
#define Normal

//how many steps are made along each ray when looking for the fractal surface
#define RaySteps 1000000

//supersampling - 1=off
#define samplepixels 1

//rotations
#define xrot 140.0
#define yrot 0.0
#define zrot 0.0
//uncomment the following 3 lines to auto-rotate the fractal
//#define xrot time*90.0
//#define yrot time*50.0
//#define zrot time*70.0

//ambient occlusion
//unremark for no fake AO based on orbit traps
//the minorbit and maxorbit settings need to be set for each fractal type
#define AmbientOcclusion 

#ifdef Mandelbulb
    float Power=8.0;
    float Bailout=4.0;
    int maxiter=4;
    float CameraDistance=3.4;
    #define minorbit 0.5 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

#ifdef TNS50
    float Power=5.0;
    float Bailout=24.0;
    int maxiter=5;
    float CameraDistance=5.0;
    #define minorbit 0.5 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

//global variables
bool inside=false;
vec3 z,c,CameraPosition,RayDirection;
float smallestorbit,stepsize;
float PI=3.14159265;
float pidiv180=PI/180.0;

void Rotate2(in float Rx, in float Ry, in float Rz, in float x, in float y, in float z, out float Nx, out float Ny, out float Nz) {
    float TempX,TempY,TempZ,SinX,SinY,SinZ,CosX,CosY,CosZ,XRadAng,YRadAng,ZRadAng;
    XRadAng=Rx*pidiv180;
    YRadAng=Ry*pidiv180;
    ZRadAng=Rz*pidiv180;
    SinX=sin(XRadAng);
    SinY=sin(YRadAng);
    SinZ=sin(ZRadAng);
    CosX=cos(XRadAng);
    CosY=cos(YRadAng);
    CosZ=cos(ZRadAng);
    TempY=y*CosY-z*SinY;
    TempZ=y*SinY+z*CosY;
    TempX=x*CosX-TempZ*SinX;
    Nz=x*SinX+TempZ*CosX;
    Nx=TempX*CosZ-TempY*SinZ;
    Ny=TempX*SinZ+TempY*CosZ;
}

void Rotate(in float Rx, in float Ry, in float Rz, in float x, in float y, in float z, in float ox, in float oy, in float oz, out float Nx, out float Ny, out float Nz){
    Rotate2(Rx,Ry,Rz,x-ox,y-oy,z-oz,Nx,Ny,Nz);
    Nx=Nx+ox;
    Ny=Ny+oy;
    Nz=Nz+oz;
}

//performs one z=z^p+c iteration
void Iterate(inout vec3 z,in vec3 c) {
    vec3 tmpz;
    float h,r,r1,r2,r3,s,f,g,a,b,m,n,th,ph,r2p,x1,y1,z1,cosph;
    float ma,mb,mc,md,rx,d,rz,a1,b1,c1;
    
    ///////////////////////////////////////////////////////////////////////////
    //Mandelbulb
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Mandelbulb
        r=length(z);
        
        #ifdef AmbientOcclusion
            if (r<smallestorbit) { smallestorbit=r; }
        #endif

        th=atan(z.y,z.x)*Power;
        ph=asin(z.z/r)*Power;
        r2p=pow(r,Power);
        z.x=r2p*cos(ph)*cos(th);
        z.y=r2p*cos(ph)*sin(th);
        z.z=r2p*sin(ph);
        z+=c;
    #endif

   
    ///////////////////////////////////////////////////////////////////////////
    //TNS50: miscellaneous variants of triplex multiplication
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TNS50
      r1 = z.x;
      r2 = z.y;
      r3 = z.z;
      for ( n=0; n < Power; n++ )
      {
        x1 = z.x; y1 = z.y; z1 = z.z;
        z.x = x1*r3 - y1*r2 + z1*r1;
        z.y = x1*r2 + y1*r3 + z1*r1;
        z.z = x1*r3 + y1*r1 + z1*r2;
     }
      z += c;
    #endif
    
}

//iterate the formula to determine if the passed point is inside the fractal
bool isinside(vec3 c){
    float lengthz;
    int itercount;
    z=c;

    //next line is a simple sphere to test
    //if (length(z)<1.0) { inside=true; } else { inside=false; }

    
    inside=true;
    for(int i=0;(i<maxiter);i++) {
        
        itercount=i;

        Iterate(z,c);
        
        lengthz=length(z);
        
        
        if (lengthz>Bailout) { 
        inside=false;
        break;
      }
    }
    
    return inside;
}
  
//walks the ray and sets dist to how far the fractal surface is
void BruteForceDistance(inout vec3 dist,in float startdistance){
        float f=startdistance;
        
        smallestorbit=100000.0;

        //step along the ray - break when inside the fractal
        for(int i=0;i<RaySteps;i++){
            f+=stepsize*float(i);
            c=CameraPosition+RayDirection*f;
            dist=c-CameraPosition; 
            if (isinside(c)==true) { break; }
            if (length(c)>Bailout) { break; }
    }
}

void main(void){
    int xsamp,ysamp;
    float xstep,ystep,rtot,gtot,btot,mx,my,lastdistance,p2dist,p3dist,p4dist,p5dist,p6dist,p7dist;
    vec2 vPos;
    vec3 dist,CameraUpVector,CameraRotation,ViewPlaneNormal,u,v,vcv,scrCoord,SurfaceNormal,p1,p2,p3,p4,p5,p6,p7;
    vec3 N,T,B,L,rO,rD,Ntmp,n,n1,n2;
    float thisr,thisg,thisb,aspect,beta,alpha,amin,amax,bmin,bmax,awidth,bheight,xp,yp,fov,DiffuseFactor;
    vec3 eye,lookat,up,lightpos,diffuse,VectorToLight,E,NdotL;

    lightpos=vec3(-25.0,-25.0,10.0);
    
    lookat=vec3(0.0,0.0,0.0);
    eye=vec3(0.0,0.0,1.0)*CameraDistance;
    up=vec3(0.0,1.0,0.0);
    fov=35.0;
        
    //construct the basis
    N=normalize(lookat-eye);
    T=normalize(up);
    B=cross(N,T);
    aspect=resolution.x/resolution.y;
    beta=tan(fov*pidiv180)/2.0;
    alpha=beta*aspect;
    amin=-alpha;
    amax=alpha;
    bmin=-beta;
    bmax=beta;
    awidth=amax-amin;
    bheight=bmax-bmin;
    xstep=awidth/resolution.x;
    ystep=bheight/resolution.y;
    
    rtot=0.0;
    gtot=0.0;
    btot=0.0;

    dist=vec3(0.0,0.0,0.0);

    for (xsamp=0;xsamp<samplepixels;xsamp++) {
        for (ysamp=0;ysamp<samplepixels;ysamp++) {
            
            //x and y locations
            //these are the coordinates the ray will go through in 3d space
            xp=(gl_FragCoord.x/resolution.x)*awidth-abs(amin)+(xstep*float(xsamp)/float(samplepixels))-xstep*0.5;
            yp=bheight-(gl_FragCoord.y/resolution.y)*bheight-abs(bmin)+(ystep*float(ysamp)/float(samplepixels))-ystep*0.5;

            //set ray direction vector
            rD=normalize(xp*T+yp*B+N);
            //ray origin - starts from the eye location
            rO=eye;
            //rotations
            Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
            Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
            //light rotates with camera
            //Rotate(xrot,yrot,zrot,lightpos.x,lightpos.y,lightpos.z,0.0,0.0,0.0,lightpos.x,lightpos.y,lightpos.z);
            
            CameraPosition=rO;
            RayDirection=rD;

            stepsize=CameraDistance*2.0/float(RaySteps);
            
            BruteForceDistance(dist,0.0);
            lastdistance=length(dist);
            
            if (inside==true){
                
            //Normal based color
                #ifdef Normal
                
                    p1=c;

                    //epsilon value
                    //float eps=xstep/samplepixels*2.0;
                    //float eps=0.001;
                    float eps=xstep/samplepixels;
                       

                    lastdistance=length(c-rO);
    
                    rD=normalize(xp*T+yp*B+N);
                    rD.x-=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    CameraPosition=rO;

                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    //BruteForceDistance(dist,0);
                    p2=c;
                
                    rD=normalize(xp*T+yp*B+N);
                    rD.x+=float(eps);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    //BruteForceDistance(dist,0);
                    p3=c;

                    rD=normalize(xp*T+yp*B+N);
                    rD.y-=float(eps);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    //BruteForceDistance(dist,0);
                    p4=c;
                
                    rD=normalize(xp*T+yp*B+N);
                    rD.y+=float(eps);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    //BruteForceDistance(dist,0);
                    p5=c;

                    rD=normalize(xp*T+yp*B+N);
                    rD.z-=float(eps);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    //BruteForceDistance(dist,0);
                    p6=c;
                
                    rD=normalize(xp*T+yp*B+N);
                    rD.z+=float(eps);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    //BruteForceDistance(dist,0);
                    p7=c;

                    vec3 grad;
                    grad.x=(p3.x*p3.x+p3.y*p3.y+p3.z*p3.z)-(p2.x*p2.x+p2.y*p2.y+p2.z*p2.z);
                    grad.y=(p5.x*p5.x+p5.y*p5.y+p5.z*p5.z)-(p4.x*p4.x+p4.y*p4.y+p4.z*p4.z);
                    grad.z=(p7.x*p7.x+p7.y*p7.y+p7.z*p7.z)-(p6.x*p6.x+p6.y*p6.y+p6.z*p6.z);
                    n=normalize(grad);
                    
                    diffuse.x=0.2;
                    diffuse.y=0.2;
                    diffuse.z=0.2;

                    //the vector to the first light
                    VectorToLight=normalize(lightpos-p1);
                    //the vector to the eye
                    E=normalize(eye-p1);
                    //the cosine of the angle between light and normal
                    //NdotL=n*VectorToLight;
                    NdotL = vec3(dot(VectorToLight,n));
                    DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
                    // compute the illumination using the Phong equation
                    //0.2 is ambient light - without it shadows are black
                    //diffuse=diffuse*max(DiffuseFactor,0.1)*2.0; //scale the light intensity
                    diffuse=diffuse*DiffuseFactor;
                    
                    
                    rtot+=diffuse.x;
                    gtot+=diffuse.y;
                    btot+=diffuse.z;

                #endif

                //XYZ to RGB mappping
                #ifdef XYZtoRGB
                    rtot+=float(abs(c.x));
                    gtot+=float(abs(c.y));
                    btot+=float(abs(c.z));
                #endif
                
                //XYZ color and distance shading
                #ifdef XYZtoRGBandDistance
                    rtot+=(1.0-abs(length(dist)/CameraDistance))+float(abs(c.x)/2.0);
                    gtot+=(1.0-abs(length(dist)/CameraDistance))+float(abs(c.y)/2.0);
                    btot+=(1.0-abs(length(dist)/CameraDistance))+float(abs(c.z)/2.0);
                #endif

                //distance shading
                #ifdef Distance
                    rtot+=(1.0-abs(length(dist)/CameraDistance));
                    gtot+=(1.0-abs(length(dist)/CameraDistance));
                    btot+=(1.0-abs(length(dist)/CameraDistance));
                #endif

                //normal based - causes 2x2 pixels
                #ifdef dFd
                    vec3 n=normalize(cross(dFdx(c),dFdy(c)));
                    rtot+=n.x;
                    gtot+=n.y;
                    btot+=n.z;
                #endif
                
            } else {
                //background color
                rtot+=0.1;
                gtot+=0.1;
                btot+=0.1;
            }
//ambient occlusion based on min dist
                #ifdef AmbientOcclusion
                    if (smallestorbit<minorbit) { smallestorbit=minorbit; }
                    if (smallestorbit>maxorbit) { smallestorbit=maxorbit; }
                    smallestorbit=(smallestorbit-minorbit)/(maxorbit-minorbit);
                    rtot*=smallestorbit;
                    gtot*=smallestorbit;
                    btot*=smallestorbit;
                #endif

        }
    }
               
    rtot=rtot/float(samplepixels*samplepixels);
    gtot=gtot/float(samplepixels*samplepixels);
    btot=btot/float(samplepixels*samplepixels);

    glFragColor=vec4(rtot,gtot,btot,1.0); 
}

