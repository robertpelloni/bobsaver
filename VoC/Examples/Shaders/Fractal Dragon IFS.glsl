#version 420

// original https://www.shadertoy.com/view/MsBXW3
 
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
// Distance estimation for dragon IFS. by knighty (nov. 2014).
////////////////////////////////////////////////////////////////////////////////

#define DEPTH 15
//The refine step doesn't work well :-/
//#define REFINE_DE
//interior only mode is much faster :-)
#define INTERIOR_ONLY
////////////////////////////////////////////////////////////////////////////////

#define ITER_NUM pow(2., float(DEPTH))
//Bounding radius to bailout. must be >1. higher values -> more accurate but slower (try 1000)
//for raymarching a value of 2 or 4 is enought in principle. A vuale of 1 (when REFINE_DE is undefined) will show the bounding circle and its transformations
#ifdef INTERIOR_ONLY
#define BR2BO 1.
#else
#define BR2BO 64.
#endif
vec2  A0   = vec2(1.,-1.);//1st IFS's transformation similatrity
vec2  F0   = vec2(-1.,0.);//fixed point of 1st IFS's transformation.
vec2  T0; //Translation term Computed in ComputeBC().
float scl0 = length(A0);//scale factor of the 1st IFS's 

//2nd IFS's transformation.
vec2  A1   = vec2(-1.,-1.);
vec2  F1   = vec2(1.,0.);
vec2  T1;
float scl1 = length(A1);

float Findex=0.;//mapping of IFS point to [0,1[
float minFindex=0.;//for colouring
float BR;//Computed in ComputeBC(). Bounding circle radius. The smaller, the better (that is faster) but it have to cover the fractal (actually it have to cover it's images under the transforms)
float BO;//Computed in ComputeBC(). Bailout value. it should be = (BR*s)^2 where s>1. bigger s give more accurate results but is slower.

//Complex multiplication
vec2 Cmult(vec2 a, vec2 b){ return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);}

//Compute bounding circle
void ComputeBC(){
    //Compute bounding circle center w.r.t. fixed points
    float ss0=length(vec2(1.,0.)-A0);
    float ss1=length(vec2(1.,0.)-A1);
    float s= ss1*(1.-scl0)/(ss0*(1.-scl1)+ss1*(1.-scl0));
    vec2 C=F0+s*(F1-F0);
    //Translate the IFS in order to center the bounding circle at (0,0)
    F0-=C;
    F1-=C;
    //Pre-compute translations terms
    T0 = Cmult(vec2(1.,0.)-A0,F0);
    T1 = Cmult(vec2(1.,0.)-A1,F1);
    //Bounding circle radius
    BR = -ss0*length(F0)/(1.-scl0);
    //
    BO = BR*BR*BR2BO;
}

//Computes distance to the point in the IFS which index is the current index.
//lastDist is a given DE. If at some level the computed distance is bigger than lastDist
//that means the current index point is not the nearest so we bail out and discard all
//children of the current index point.
//We also use a static Bail out value to speed things up a little while accepting less accurate DE.
float dragonSample(vec2 p, float lastDist){
    float q=Findex;//Get the index of the current point
    float dd=1.;//running scale
    float j=ITER_NUM;
    for(int i=0; i<DEPTH; i++){
        float l2=dot(p,p);
#ifndef INTERIOR_ONLY
        float temp=BR+lastDist*dd;//this is to avoid computing length (sqrt)
        if(l2>0.001+temp*temp || l2>BO) break;//continue;//continue is too slow here
#else
        if(l2>BO) break;
#endif
        
        //get the sign of the translation from the binary representation of the index
        q*=2.;
        float sgn=floor(q); q=fract(q); j*=.5;
        
        if(sgn==0.){
            p=Cmult(A0,p)+T0;
            dd*=scl0;
        } else {
            p=Cmult(A1,p)+T1;//similarity
            dd*=scl1;
        }
    }
    //update current index. it is not necessary to check the next j-1 points.
    //This is the main optimization
    Findex = ( Findex + j*1./ITER_NUM );
#ifdef REFINE_DE
    for(int i=0; i<DEPTH; i++){
        if(j==1.) break;
        j*=0.5;
        vec2 p0=Cmult(A0,p)+T0, p1=Cmult(A1,p)+T1;
        if(dot(p0,p0)<dot(p1,p1)){p=p0; dd=dd*scl0;}
        else {p=p1; dd=dd*scl1;}
    }
#endif
    float d=(length(p)-1.*BR)/dd;//distance to current point
    if(d<lastDist) minFindex=Findex;
    return min(d,lastDist);
}

void main(void)
{
    float t=time*0.2-.5*3.14159;
    vec2 rot=vec2(cos(t),sin(t));
    A1=Cmult(rot,A0);
    ComputeBC();
    //coordinates of current pixel in object space. 
    vec2 uv = 1.7*BR*(gl_FragCoord.xy-0.5*resolution.xy) / resolution.y;
    //Get an estimate. not necessary, but it's faster this way.
    float d=length(uv)+0.5;
    //refine the DE
    for(int i=0; i<500; i++){//experiment: try other values
    // In principle max number of iteration should be ITER_NUM but we actually
    //do much less iterations. Maybe less than O(DEPTH^2). Depends also on scl.
        d=dragonSample(uv,d);
        if(Findex>=1.) break;
    }
#ifdef INTERIOR_ONLY
    d=max(0.,-d);
#endif
    glFragColor = vec4(pow(abs(d),0.2))*(0.75+0.25*sin(vec4(15.,6.5,3.25,1.)*minFindex));//
}
