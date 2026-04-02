#version 420

// original https://www.shadertoy.com/view/XsXBWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//parent: https://www.shadertoy.com/view/ltXGWS

//ended up warping the df() distanceField 
//..within the rm() Raymarch function.

//radius (and thickness)
//...of (a mix of a sphere and a cylinder) that bounds the volume.
#define radius 3.
//that volume then gets "filled with" 
//...honeycomb-tesselation holes (or spheres).

//displace the distance Field by DISPLACE*honeycomb
//(and not just textures it), intended range [-1..1]
//remove for better performance
#define DISPLACE 1.
//With small DISPLACE, a lot of camera positions 
//...are inside the signed distance field (negative distance)

//uncomment to toggle between boolean [difference] or [intersect]
//#define intersection
//above gets pretty much obsoleted by [HoleScaling]

//size of holes (or spheres)=distance_to_surface*HoleScaling
#define HoleScaling 1.2
//range [-0.5 .. -2.0] OR range [0.5 .. 2.0]
//HoleScaling outside that rande is too bad for lipschitz continuity.

//larger reciprocalCellScale make holes smaller
#define reciprocalCellScale 2.
//honeycomb scaling == 1/reciprocalCellScale

//for performance:

//maximum raymarch steps.
#define rmItteratons 255

//its almost strange how a larger epsilon looks better.
//...with a honeycomb displacement
#define eps 1e-3

//scale raymarch steps by ReciprocalLipschitz
#define ReciprocalLipschitz .3
//lipschitsConstant=abs(firstDerivative(x));
//global (or local) lipschitsConstant is not defined for point x,
//...but is the max() of ANY x,range [a..b] or range [-inf...+inf].
//Multiplying raymarchStepDistances by
//...the reciprocal of an ESTIMATION of a global lipschitsConstant
//...is the lazy way to avoid overestimation of raymarch step distances.

//the smart solution would be "automatic differenciation" 
//...returning you the exact lipschitzConstant for every step.

//return 3d honeycomb, distance to closest "white tile" of checkerboard tiling
float cells(vec3 p){p=fract(p/2.)*2.;p=min(p,2.-p );    
 return min(length(p),length(p-1.));}

//return distance field. actually, rm() modifies this A LOT
float df(vec3 p){float a=1.5-length(p.xy);
 float b=(length(p.xz)-abs(p.y)+.4);
 float r=min(a,b*.2);return r;}

//raymarch, return position were ray hits surface
vec3 rm(vec3 o,vec3 d,out float h){float m=(cos(time*.61*.1)*.5+.5);
 for(int i=0;i<rmItteratons;i++){h=length(o)-radius;float a=df(o);
  h=mix(a,max(h,a),m);//first displacement
  #ifdef DISPLACE
   float displace=h;
   #ifdef intersection
    displace=max(h,+(h+(cells(o*reciprocalCellScale)-.7)*HoleScaling)*ReciprocalLipschitz);//lipschitsConstant==5.0?                
    //above does intersection: [h AND     h+cells()] max(a,+b)
   #else
    //below does difference:   [h AND NOT h+cells()] max(a.-b)
    displace=max(h,-(h+(cells(o*reciprocalCellScale)-.7)*HoleScaling)*ReciprocalLipschitz);//lipschitsConstant==5.0?                
   #endif
   h=mix(h,displace,DISPLACE);//sedond displacement
  #endif
  o+=d*h;if(h<eps)return o;}return o;}

//return RayPos for [U]FragmentPos,and set [d]RayDirection
vec3 cam(vec2 U,out vec3 d){
 vec2 h=resolution.xy/2.;
 d=normalize(vec3(U.xy-h,h.y*2.));
 vec2 r=vec2(0);//2 rotations around 2 axes
 //if(mouse*resolution.xy.z >.0)r+=vec2(-2,3)*(mouse*resolution.xy.yx/h.yx-1.);//mouse cam
 //else r.y=time*.3;//auto cam
    r.y=time*.3;//auto cam
 vec2 c=cos(r),s=sin(r);
 d.yz=vec2(-1,1)*d.zy*s.x+d.yz*c.x;//2d rotation
 d.xz=vec2(1,-1)*d.zx*s.y+d.xz*c.y;//2d rotation
 return vec3(-c.x*s.y,s.x,-c.x*c.y)*8.;
}

void main(void) {
 vec3 d,p=cam(gl_FragCoord.xy,d);//camera [o]origin [d]direction [U]gl_FragCoord                                          
 float h=0.;p=rm(p,d,h);//raymarch [h]distanceToSurface
 #ifndef intersection
  if(h<eps){//conditional only makes sense for intersection
 #endif
  vec3 a=step(.5,fract(p*reciprocalCellScale/2.0-.25));
  vec3 b=vec3(cells(p*reciprocalCellScale)/1.3);
 glFragColor.rgb=mix(a,b,sin(time)*.2+.8);}
 #ifndef intersection
  }
 #endif

// Ben Quantock 2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
