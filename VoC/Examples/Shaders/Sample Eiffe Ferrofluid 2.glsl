#version 420

//original https://www.shadertoy.com/view/Md23Dz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ferrofluid by eiffie 
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define time2 time*0.2
#define size resolution

// Compute magnetic dipole field value (a vector) at field location samplePt
// for a dipole located at dipolePt, with moment dipoleMt.
// this is the 3d implementation derived from the 2d by Ross Bencina found here:
// https://www.shadertoy.com/view/ld23WR
// http://en.wikipedia.org/wiki/Magnetic_field
// http://en.wikipedia.org/wiki/Dipole#Field_of_a_static_magnetic_dipole
#define PI 3.1415926
vec3 dipoleField( vec3 samplePt, vec3 dipolePt, vec3 dipoleMt )
{
    const float mu_0 = 0.0000012566371; // permeability of free space: http://en.wikipedia.org/wiki/Magnetic_constant
    
    // rr: vector from position of dipole to position of interest
    vec3 rr = samplePt - dipolePt;
  
      // r: is the absolute value of rr: the distance from the dipole
    float r = length(rr);
  
    // r_hat: rr/r the unit vector parallel to rr
    vec3 r_hat = rr / r;
  
      // computed field value
      return (mu_0/(4.0*PI*r*r*r)) * ( (3.0*dot(dipoleMt,r_hat)*r_hat) - dipoleMt );

}

float focalDistance,aperture=0.06,fudgeFactor=0.25,shadowCone=0.75;
vec3 L;
vec3 mcol;
const vec3 lightColor=vec3(1.0,0.5,0.25);
mat3 matPyr(vec3 rot){vec3 c=cos(rot),s=sin(rot);//orient the mat3 (pitch yaw roll)
    return mat3(c.z*c.y+s.z*s.x*s.y,s.z*c.x,-c.z*s.y+s.z*s.x*c.y,-s.z*c.y+c.z*s.x*s.y,c.z*c.x,s.z*s.y+c.z*s.x*c.y,c.x*s.y,-s.x,c.x*c.y);
}
mat3 rmx;
float RRect(in vec3 z, vec4 r){return length(max(abs(z.xyz)-r.xyz,0.0))-r.w;}

vec3 dp1=vec3(0.0),dp2=vec3(2.5);//dipole positions
vec3 dm1=vec3(1.0,0.0,0.0),dm2=vec3(0.0,0.0,1.0);//dipole moments

float fbm(vec3 p) {//this started out as a full fbm like a chunky fluid, it can show nice detail
    p=sin(p*5.0)*0.075; //but this looks more like a fluid with standing magnetic waves
    return p.x+p.y+p.z;
}

float DE(in vec3 z0){
    vec3 z=z0;
    vec3 field=dipoleField(z,dp2,dm2);//the fluid's magnetic field
    field+=dipoleField(z,dp1,dm1);//and the bar magnet's
    field*=200000000.0; //fix the scale so we see it
    float d=length(z-dp1)-2.0;//ferrofluid rest state
    vec3 v=field*field;
    v=sqrt(vec3(v.y+v.z,v.x+v.z,v.x+v.y));//probably a better way to do this
    d+=fbm(z*v);//perturb the surface by the strength of the field
    vec3 z2=(z-dp2)*rmx;
    float d2=RRect(z2,vec4(0.25,0.25,0.5,0.05))*4.0;//just a magnet
    if(d2<d){
        d=d2;
        if(z2.z<0.0)mcol+=vec3(1.0,0.0,0.0);else mcol+=vec3(0.2);
    }else mcol+=vec3(0.3,0.4,0.6)+sin(field*6.6)*0.08;
    return d;
}

float pixelSize;
float CircleOfConfusion(float t){//calculates the radius of the circle of confusion at length t
    return max(abs(focalDistance-t)*aperture,pixelSize*(1.0+t));
}
mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(up)));return mat3(rt,cross(rt,fw),fw);
}
float linstep(float a, float b, float t){return clamp((t-a)/(b-a),0.,1.);}// i got this from knighty and/or darkbeam
//random seed and generator
float randSeed;
float randStep(){//a simple pseudo random number generator based on iq's hash
    return  (0.8+0.2*fract(sin(++randSeed)*43758.5453123));
}

float FuzzyShadow(vec3 ro, vec3 rd, float lightDist, float coneGrad, float rCoC){
    float t=0.0,d=1.0,s=1.0;
    ro+=rd*rCoC*2.0;
    //for(int i=0;i<4;i++){
        //if(s<0.1 || t>lightDist)continue;
        float r=rCoC+t*coneGrad;//radius of cone
        d=DE(ro+rd*t)+r*0.5;
        s*=linstep(-r,r,d);
        //t+=abs(d)*randStep();
    //}
    return clamp(0.25+0.75*s,0.0,1.0);
}
vec3 Background(vec3 rd){return lightColor*(pow(max(0.0,dot(rd,L)),4.0));}

void main() {
    randSeed=fract(cos((gl_FragCoord.x+gl_FragCoord.y*117.0+time2*10.0)*473.7192451));
    pixelSize=2.0/size.y;
    float tim=time2-0.5;
    rmx=matPyr(vec3(time2,time2*1.1,time2*1.3));
    dm2=rmx*dm2;
    vec3 ro,rd;
    //if(iMouse.z<0.1){
        dp2=vec3(sin(time2),sin(time2*0.3)*0.5,cos(time2))*(4.25-sin(tim*0.7));
        ro=vec3(sin(tim),sin(tim*0.3)*0.5,cos(tim))*(4.5+sin(tim*0.7));
        rd=lookat(-ro,vec3(0.0,1.0,0.0))*normalize(vec3((2.0*gl_FragCoord.xy-size.xy)/size.y,2.0));
    //}else{    
    //    dp2=vec3(sin(time2),0.5+0.75*sin(time2*2.3),cos(time2));
    //    ro=vec3(sin(tim),1.0,cos(tim))*(3.5+sin(tim*0.7));
    //    rd=lookat(-ro-vec3(0.0,4.0,0.0),vec3(0.0,1.0,0.0))*normalize(vec3((2.0*gl_FragCoord.xy-size.xy)/size.y,2.0));
    //}
    focalDistance=length(ro)-1.0;
    L=normalize(vec3(0.5,0.6,0.4));
    vec4 col=vec4(0.0);//color accumulator
    float t=0.0;//distance traveled, minimum light distance
    for(int i=0;i<78;i++){//march loop
        if(col.w>0.9 || t>10.0)continue;//bail if we hit a surface or go out of bounds
        float rCoC=CircleOfConfusion(t);//calc the radius of CoC
        mcol=vec3(0.0);//clear the color trap
        float d=DE(ro);
        if(d<rCoC){//if we are inside add its contribution
            float g=d-0.51*rCoC;
            vec3 p=ro+rd*g;//back up to border of CoC//-rd*2.0*pixelSize;//
            vec2 v=vec2(rCoC*0.1,0.0);//use normal deltas based on CoC radius
            vec3 N=normalize(vec3(-DE(p-v.xyy)+DE(p+v.xyy),-DE(p-v.yxy)+DE(p+v.yxy),-DE(p-v.yyx)+DE(p+v.yyx)));
            if(N!=N)N=-rd;
            mcol*=0.143;
            vec3 scol=mcol*(0.5+0.5*dot(N,L));
            scol+=pow(max(0.0,dot(reflect(rd,N),L)),16.0)*lightColor;
            scol*=FuzzyShadow(p,L,1.0,shadowCone,rCoC);    
            float alpha=fudgeFactor*(1.0-col.w)*linstep(-rCoC,rCoC,-d);//calculate the mix like cloud density
            col+=vec4(scol*alpha,alpha);//blend in the new color    
        }
        d=fudgeFactor*max(d+0.5*rCoC,rCoC*0.5)*randStep();//add in noise to reduce banding and create fuzz
        ro+=d*rd;//march
        t+=d;
    }//mix in background color
    col.rgb=mix(Background(rd),col.rgb,clamp(col.w,0.0,1.0));

    glFragColor = vec4(clamp(col.rgb,0.0,1.0),1.0);
}
