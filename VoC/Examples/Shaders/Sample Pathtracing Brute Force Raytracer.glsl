#version 420

//brute force fractal raytracer
//steps along each ray in fixed distance incrememnts
//no distance estimation used

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;
uniform float random1,random2;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//unremark which formula/fractal you want to render
#define Mandelbulb
//#define Benesi1

//unremark which render method you want to use
#define XYZtoRGB
//#define XYZtoRGBandDistance
//#define Distance
//#define dFd
//#define Normal

//how many steps/divisions are made along each ray when looking for the fractal surface
#define RaySteps 500

//how far away the ray starts
#define near 0.0
//how deep the ray goes into space
#define far 3.0

//supersampling - 1=off
#define samplepixels 1

//rotations
#define xrot 150.0
#define yrot 0.0
#define zrot 0.0
//uncomment the following 3 lines to auto-rotate the fractal
//#define xrot time*90.0
//#define yrot time*50.0
//#define zrot time*70.0

//ambient occlusion
//unremark for no fake AO based on orbit traps
//the minorbit and maxorbit settings need to be set for each fractal type
//#define AmbientOcclusion 

#ifdef Mandelbulb
    float Power=8.0;
    float Bailout=4.0;
    int maxiter=12;
    float CameraDistance=3.1;
    #define minorbit 0.2 //higher value make darker crevices
    #define maxorbit 0.7 //lower values make brighter surface
#endif

#ifdef Benesi1
    float Power=2.0;
    float Bailout=20.0;
    int maxiter=8;
    float CameraDistance=3.2;
    #define minorbit 4.0 //higher value make darker crevices
    #define maxorbit 5.0 //lower values make brighter surface
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
    //float ma,mb,mc,md,rx,d,rz,a1,b1,c1;
    
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
    //Benesi1 - http://www.fractalforums.com/3d-fractal-generation/rendering-3d-fractals-without-distance-estimators/msg54192/#msg54192
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Benesi1
        float sr23=sqrt(2./3.);
        float sr13=sqrt(1./3.);
        float nx=z.x*sr23-z.z*sr13;
        float sz=z.x*sr13 + z.z*sr23;
        float sx=nx;
        float sr12=sqrt(.5);
        nx=sx*sr12-z.y*sr12;             
        float sy=sx*sr12+z.y*sr12;
        sx=nx*nx;
        sy=sy*sy;
        float ny=sy;
        sz=sz*sz;
        r2=sx+sy+sz;
        if (r2!=0.) {                                       
            nx=(sx+r2)*(9.*sx-sy-sz)/(9.*sx+sy+sz)-.5;
            ny=(sy+r2)*(9.*sy-sx-sz)/(9.*sy+sx+sz)-.5;
            sz=(sz+r2)*(9.*sz-sx-sy)/(9.*sz+sx+sy)-.5;
        }
        sx=nx;
        sy=ny;
        nx=sx*sr12+sy*sr12;
        sy=-sx*sr12+sy*sr12; 
        sx=nx;
        nx=sx*sr23+sz*sr13;
        sz=-sx*sr13+sz*sr23;                //some things can be cleaned up
        sx=nx;
        float sx2=sx*sx;
        float sy2=sy*sy;                // will be switching code around later       
        float sz2=sz*sz;
        nx=sx2-sy2-sz2;
        r3=2.*abs(sx)/sqrt(sy2+sz2);
        float nz=r3*(sy2-sz2);
        ny=r3*2.*sy*sz;
        z= vec3(nx,ny,nz);
    #endif

    
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
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
        float DEdist,r,closest,localfar,localnear;
        vec3 point,closestpoint;
        bool beeninside;
    
        closestpoint=vec3(100.0,100.0,100.0);

        smallestorbit=100000.0;
        
        localfar=far;
        localnear=near;

        closest=CameraDistance;

        beeninside=false;

        //randomly test between the closest found point and camera
        for(int i=0;i<RaySteps;i++) {
            
            float d = closest*rand(gl_FragCoord.xy*float(i)*random1);
            point = CameraPosition + (localnear+d*(localfar-localnear)) * RayDirection;

            if (isinside(point)) { 
                closest = d; 
                closestpoint = point;
                beeninside=true;
             } else {
                //localnear=d;
            }

        }
        inside=beeninside;
        c=closestpoint;
        dist=closestpoint-CameraPosition;
}

void main(void){
    int xsamp,ysamp;
    float xstep,ystep,rtot,gtot,btot,mx,my,lastdistance,p2dist,p3dist,p4dist,p5dist,p6dist,p7dist;
    vec2 vPos;
    vec3 dist,CameraUpVector,CameraRotation,ViewPlaneNormal,u,v,vcv,scrCoord,SurfaceNormal,p1,p2,p3,p4,p5,p6,p7;
    vec3 N,T,B,L,rO,rD,Ntmp,n,n1,n2;
    float thisr,thisg,thisb,aspect,beta,alpha,amin,amax,bmin,bmax,awidth,bheight,xp,yp,fov,DiffuseFactor;
    vec3 eye,lookat,up,lightpos,diffuse,VectorToLight,E,NdotL;

    vec2 position = vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
    float pw = 1.0/resolution.x; //pixel width
    float ph = 1.0/resolution.y; //pixel height
    
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
            
            //see if closer than backbuffer
            dist = min(dist,texture2D( backbuffer, position ).a*far);

            if (inside==true){
                
            //Normal based color
                #ifdef Normal
                
                    
                    //p1=texture2D( backbuffer,vec2(position.x, position.y)).a;
                    //p2=texture2D( backbuffer,vec2(position.x+pw, position.y)).a;
                    //p3=texture2D( backbuffer,vec2(position.x, position.y+ph)).a;
                    
                    p1=CameraPosition+texture2D(backbuffer,vec2(position.x,position.y)).a*far*RayDirection;
                    p2=CameraPosition+texture2D(backbuffer,vec2(position.x+pw,position.y)).a*far*RayDirection;
                    p3=CameraPosition+texture2D(backbuffer,vec2(position.x,position.y+ph)).a*far*RayDirection;

                    //p1=dist;
                    //p2=texture2D( backbuffer,vec2(position.x+pw, position.y)).a*far;
                    //p3=texture2D( backbuffer,vec2(position.x, position.y+ph)).a*far;

                    vec3 v=p2-p1;
                    vec3 w=p3-p1;
                    vec3 grad;
                    grad.x=(v.y*w.z)-(v.z*w.y);
                    grad.y=(v.z*w.x)-(v.x*w.z);
                    grad.z=(v.x*w.y)-(v.y*w.x);
                    
                    n=normalize(grad);
                    

                    //n=normalize(vec3(s-DE(p-e.xyy),s-DE(p-e.yxy),s-DE(p-e.yyx)));

                    diffuse.x=0.5;
                    diffuse.y=0.5;
                    diffuse.z=0.5;

                    //the vector to the first light
                    VectorToLight=normalize(lightpos-p1);
                    //the vector to the eye
                    E=normalize(eye-p1);
                    //the cosine of the angle between light and normal
                    NdotL=n*VectorToLight;
                    DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
                    //vec3 Reflected=lightpos-2.0*DiffuseFactor*n;
                    // compute the illumination using the Phong equation
                    //0.2 is ambient light - without it shadows are black
                    diffuse=diffuse*max(DiffuseFactor,0.2)*2.0; //scale the light intensity
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
        }
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

    rtot=rtot/float(samplepixels*samplepixels);
    gtot=gtot/float(samplepixels*samplepixels);
    btot=btot/float(samplepixels*samplepixels);

    //store depth in back buffer alpha
    glFragColor=vec4(rtot,gtot,btot,dist/far); 
}

