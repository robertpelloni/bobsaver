#version 420

// original https://www.shadertoy.com/view/4l2yDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//sign 3d portal (one way) single pass 2
//https://www.shadertoy.com/view/lsSGRz

//was a bit messy, cleaned it up a lot.

//one lazy thing here is that it uses n states, buffers
//so it just assumes that it will pass the portal only once per cycle
// at the same spots on he cycle.

//turns few things make an objectID gBuffer more complicated
//than a portal.
//the main problem is measuring a distance gradient trough a portal
//basically doublles the number of measures
//OR
//you first trace the portal, use it as a bounding volume (leaf portal duh)
//and stop parching ON the portal, which adds a trace and +1 step.
// the trace is kinda done heuristically anyways
// , where it suffers lipschitz issies.
// so, this needs an explicit portal tracer as primary BVH.

//todo, needs tracer BV
//to know when a ray passes the portal and when not!
//i tried stuff, and mostly made it worse than better

//spin speed of portal around vertical axis.
#define portalSpinZ time*2.

//smaller steps or simpler geometry for better continuity.
//makes portal a circle.
//#define doGoodLipschitz

//the lazy lipschitz adjustment
#define understepRm .5

#define zFar  400.
#define iterRm 180

#define SPECULAR

//this is shitty occlusion, in a dicsontinuous set, poorly cotained.
#define iterShadow 1

//.x is radius .y is thickness of portal "wall"

#define portalRing vec2(22.,1.)
//#define portalRing vec2(22.,152./resolution.y)
//hairlined /resolution
//because it is a curved thing with bad lipschitz

//glow completely fails along the portal discontinuity
//well, glow is always good ad shwing bad lipschits
//, so it stays as a debugger.
//#define GLOW 1
// Increase for bigger glow effect (which also gets a little bugged...)!
#define GLOW_AMOUNT 9.*portalRing.x/understepRm
//clearly glow was an attempt at hiding discontinuities

//i tried to fix some continuity cases trough the portal
//and made it worse, introcused more discontinuities than it removed.
#define TheHartdWay

/*
todo, this could use bool;if linesegment intersets portal surface,
//even with sign check (portal normal)

//portal surface is defined by;
center, radius, normal

if (line intersetcs plane)
- this is bool, because parallel case is common
- if (intersection distance < line segment length)
- - if (intersection point is inside circle)
- - - portal direction resolve
- - - lets say a portal is a delta_world, but with sign
- - - still need to resolve direction of portal with portal normal
- - - should be sign of dot of directions!
*/

/*
portal gun is one way portals!
a portal bun places 2 one-way portals in 2 different locales.
one way portalsd have some inherent backfacing-problems.
2-way portals do not have that!

lets assume a portal gun places 2 2-way portals.
the front side of one portal
 connects to the back side of the other portal

such doubly-linked portals may change worlds OR locales OR both!
they likely only have a deltaPos and deltaRotation
, linking 2 places in the same "world"

well, actually. "world" is just a "lcale" parameter.
*/

/*
intersecting portal problem:
- includes partially intersecting and coplanar portals)
- excludes portal velocity movement sum problems.

when a ray hits one portal, it must stop ON the portal
- (problem of rounding errors here)
on that point it must intersect with all other portals.
- the [order of portals] is relevant here, resolves catch22 things.
*/

//Find distance to intersection of plane along ray

/*

//plane tracing functions could possibly result in higher recision
// but for now I doubt it much of a difference

//return signed distance of u to plane (n,d)
//[u]=point to measure plane distance to
//[n]=plane normal, length set to 1.
//[m]=plane distance to vec3(0)
float dPlane(vec3 u,vec3 n,float m){return dot(u,n)+m;}

float ass(vec3 n,float m,vec3 u,vec3 t)
{float e=dot(n,t)
;if(e==.0)return .0;//ray is parallel to plane
;float d=-(dot(n,u+m)/e)
;if(d<length(t))return .0;//plane is too far away
;u+=t*e;//u is intersection point
;return 1.;    
}

//return direction of intersection of ray with plane
// 0= no intersection
//+1= intersecting from positive space
//-1= intersection from negative space
float ass2(vec3 u,vec3 t,vec3 n,float m){
 float d0=sign(dot(u  ,n)+m);
 float d1=sign(dot(u+t,n)+m);  
 if (d0!=d1)return d0;//return intersection direction.
 return .0;}//no intersection

*/

//[n]PlaneNormal
//[m]PlaneDistance (badly explained, distance to what)
//[u]RayOrigin
//[t]RayDirection
//return distacne from origin to intersection.
float gPRxZ(vec3 n,float m,vec3 u,vec3 t){
    return -(dot(n,u+m)/dot(n,t));}

//curDist, curMat , dist,mat
vec2 fUnionMat(vec2 dm,vec2 en){return mix(dm,en,step(en.x,dm.x));}

float boxR(vec3 p,vec3 b)
{return length(max(abs(p)-b,.0));}

float pTorus(vec3 p, vec2 t)
{vec2 q=vec2(length(p.xz)-t.x,p.y);return length(q)-t.y;}

//return polar of carthesian input; carthesian to polar: returned .x=distance to vec2(0); .y=angle in radians
vec2 c2p(vec2 c){return vec2(length(c),atan(c.y,c.x));}
//return carthesian of polar input; polar to carthesian: p.x=distance to vec2(0); p.y=angle in radians
vec2 p2c(vec2 p){return vec2(p.x*cos(p.y),p.x*sin(p.y));}
//lame simple rotation
mat2 r2(float r){float c=cos(r),s=sin(r);return mat2(c,s,-s,c);}

//polar deformation to "star shape" (with bad lipschitz)
vec2 wobble(vec2 u){
#ifdef doGoodLipschitz
 ;return u;
#endif
 ;u=c2p(u);
 ;float a=cos((u.y+time)*13.)*2.
 ;float b=cos((u.y+time)* 5.)*3.
 ;u.x+=mix(a,b,sin(time)*.5+.5)
;return p2c(u);}

float pTorus2(vec3 p, vec2 t){
 p.xy*=r2(portalSpinZ);//we spin locally.
 p.xz=wobble(p.xz);//we deform the gradient into a "star shape"
 return pTorus(p,t);}

float gdo(float w, vec3 p, inout float m)
{vec2 dm=vec2(16.+p.z,1)
;if (w==0.
){dm=fUnionMat(dm,vec2(length(p+vec3(24,22,4))-11.,4.))
 ;dm=fUnionMat(dm,vec2(boxR(  p+vec3(6,-35,4),vec3(4,4,11)),4.))
 ;dm=fUnionMat(dm,vec2(boxR( p+vec3(19,-15,0),vec3(4,4,15)),4.))
 ;dm=fUnionMat(dm,vec2(boxR(p+vec3(-12,20,12),vec3(7     )),4.))
;}else{dm.y=2.
 ;dm=fUnionMat(dm,vec2(boxR(p+vec3( 15,35, 6),vec3(4,12,9 )),5.))
 ;dm=fUnionMat(dm,vec2(boxR(p+vec3(-10,35,10),vec3(15,3,5 )),5.))
 ;dm=fUnionMat(dm,vec2(boxR(p+vec3( 15,-35,6),vec3(12,6,15)),5.))
;}
;dm.x-=1.
;m=dm.y;
;return dm.x;
}
//above is only occluding things
//below also includes non-occluding things 
//fullbright light sources of the same color do not occlude another.
float gd(float w, vec3 p, inout float m)
{vec2 dm=vec2(16.+p.z,1)
;dm.x=gdo(w,p,m);
;dm.y=m
;dm=dm=fUnionMat(dm,vec2(pTorus2(p,portalRing),3.));
;m=dm.y;
;return dm.x;}

vec3 dg(float w, vec3 p){const vec2 e=vec2(.01,0)
;float m;return normalize(vec3( 
(gd(w,p-e.xyy,m)-gd(w,p+e.xyy,m)),
(gd(w,p-e.yxy,m)-gd(w,p+e.yxy,m)),
(gd(w,p-e.yyx,m)-gd(w,p+e.yyx,m))));}

//main problem of this one is that it changes "worlds"
// AFTER calculating step distance!
//[u]=CameraPosition (consant within this raymarcher)
//[t]=rayDirection
//[v]=traversed point alnog ray
//[r]=distance along ray
//[e]=last step length
bool changeWorlds(vec3 u,vec3 t,vec3 v,float r,inout float e){
    ;t.xy*=r2(portalSpinZ)      
    ;u.xy*=r2(portalSpinZ)   
    ;v.xy*=r2(portalSpinZ)//rotare portal over time around .z axis
    
    ;return
length(wobble(v.xz))<portalRing.x//intersection is inside portal-shape
     &&
        (v.xy).y>.0 &&
        (u+t*(r+e)).y<.0;}

//[n]PlaneNormal
//[u]RayOrigin
//[t]RayDirection
//return distacne from origin to intersection.
float gPRxZ(vec3 n,vec3 u,vec3 t){
    return -(dot(n,u)/dot(n,t));}
float gPRxZ(vec2 n,vec2 u,vec2 t){
    return -(dot(n,u)/dot(n,t));}
//second life wiki geometric
//
//calculate intersection of ray from [a] to [m.xy] 
//and plane with notmal [n] and distance [d]to vec2(0)
//from there move AWAY from [a]
//, in the direction of the surface normal, by [c]
//return that point "BEHIND" the intersection point.
vec3 pointBehindBound(vec3 n,float d,vec3 a,vec3 b,float c){
 n=normalize(n);//save
 vec3 i=a+(b-a)*gPRxZ(n,a+n*d,(b-a));
 i-=n*sign(dot(a,n)+d)*c;//stop a little bit behind the plane.
 //i+=normalize(b-a)*c;//same, but point is on ray [m]
 return i;}
vec2 pointBehindBound(vec2 n,float d,vec4 m,float c){
 n=normalize(n);//save
 vec2 i=m.zw+(m.xy-m.zw)*gPRxZ(n,m.zw+n*d,(m.xy-m.zw));
 i-=n*sign(dot(m.zw,n)+d)*c;//stop a little bit behind the plane.
 //i+=normalize(m.xy-m.zw)*c;//same, but point is on ray [m]
 return i;}
//this is intended tor teleporters
//, where 4 permutations of "normal" and "distance" are relevant.
/*
example use:
 vec2 planeNormal=normalize(vec2(1,5));
 float planeDist=-1.;   
 c.g=dot(u,planeNormal)-1.+planeDist;//draw signed boundary
 vec2 intersect=pointBehindBound(planeNormal,planeDist,m,.5);
 c.b=length(u-intersect)-.5;//draw blue around "intersect"
*/

//oh wow, whos idea is it to make a raymarcher routine with a portal
//that accumulates a distance to a camera
//wehen the portal makes that distance all but eulidean!
//
//get world,rayOrigin,rayDirection
//r.x distance gets a birt skewed when passing portals.
//u is the real ray position to be returned

#ifdef TheHartdWay

//get world,rayOrigin,rayDirection
vec4 raymarch(float w,inout vec3 u,inout vec3 t)
{vec4 r=vec4(0,0,w,1000.)//return vec4(distance,materialId,world,glow)
;vec3 v;//we need u for a final return on t!
//;vec3 x=u;
;bool bb=false;
;for(int i=0;i<iterRm;i++
){
 ;if(!bb)v=u+t*r.x//move v along ray. //can not be delayed (easily)
 ;float e=gd(r.z,v,r.y)*understepRm
 #ifdef GLOW
  ;if(r.y==3.)r.w=min(r.w,e)
 #endif
 ;bb=changeWorlds(u,t,v,r.x,e);
 ;if(bb
 ){

  ;v=pointBehindBound(vec3(vec2(0,-1)*r2(-portalSpinZ),0),.0,v,v-t,
                      .001
                     //5.1
                    //  mouse*resolution.xy.x*10./resolution.x-5.  
                     );
  //e= makes t somehow worse:
  //;e=gd(r.z,v,r.y)*understepRm;//needs new measure on other side of portal!
  ;if(gd(r.z,v,r.y)*understepRm<-.1)break;
   // e=.0001;
        ;r.z=mod(r.z+1.,2.);//swap worlds
 ;}
 r.x+=e
;}
;t*=r.x
;u+=t
;r.y=mix(0.,r.y,step(r.y,zFar))//seems to have no effect
;return vec4(r.x,r.y,r.z,r.w);}

#else

vec4 raymarch(float w,inout vec3 u,inout vec3 t)
{vec4 r=vec4(0,0,w,1000.)//return vec4(distance,materialId,world,glow)
;for(int i=0;i<iterRm;i++
){
 ;vec3 v=u+t*r.x//vector from [cameraOrigin] to [point]
 ;float e=gd(r.z,v,r.y)*understepRm
 #ifdef GLOW
  ;if(r.y==3.)r.w=min(r.w,e)
 #endif 
 ;if(changeWorlds(u,t,v,r.x,e)){
   r.z=mod(r.z+1.,2.)//swap worlds
 ;}    
 ;r.x+=e
;}
;t*=r.x
;u+=t
;r.y=mix(0.,r.y,step(r.y,zFar))//seems to have no effect
;return vec4(r.x,r.y,r.z,r.w);}

#endif

#if iterShadow>0
//yeah, this shadow function is pretty defunct.
//world,lightsource,lightDirection
float shadow(float world, vec3 from, vec3 increment)
{
    const float minDist = 1.0;
    
    float res = 1.0;
    float t = 1.0;
    for(int i = 0; i < iterShadow; i++) {
        float m;
        float h = gd(world, from + increment * t,m);
        if(h < minDist)
            return 0.0;
        
        res = min(res, 4.0 * h / t);
        t += 1.4;
    }
    return res;}
#endif

#define sat(a) clamp(a,0.,1.)
#define u5(a) ((a)*.5+.5)

vec3 getPixel(float w,vec3 u,vec3 t){
;vec4 c=raymarch(w,u,t);
;vec3 n = dg(c.z,u)
;vec3 lightPos = -normalize(u + vec3(0,0,-4))
;float dif = u5(max(.0,dot(n,-lightPos)))
,s= 
#if iterShadow>0
 u5(shadow(c.z, u,lightPos))
#else
 1.
#endif
,spe=.0
#ifdef SPECULAR
 ;if (dot(n,-lightPos)>.0)spe=pow(max(.0,dot(reflect(-lightPos,n),normalize(-t))),5.)
#endif
//gBuffer materialId resolve
;vec3 m=vec3(0)
;if(c.y==1.
){m=mix(vec3(1,.1,.2),vec3(1,.3,.6),sin(u.x)*sin(u.y))
  *sat((100.-length(u.xy))/100.);
}else if(c.y==2.
){m=mix(vec3(.1,.2,1),vec3(.5,.5,1),sin(u.x))
 *sat((100.-length(u.xy))/100.);
}else if(c.y==3.)m=vec3(1,1,1)
;else if(c.y==4.)m=(fract(u.x/3.0)<.5?vec3(1,.1,.2):vec3(1,.3,.6))
;else if(c.y==5.)m=(fract(u.x/3.0)<.5?vec3(.1,.4,1):vec3(.4,.6,1))    
;return mix(vec3(0,1,0),(m*dif+vec3(spe))*s, sat(c.w/GLOW_AMOUNT));
;}

//basic most intuitive "look at" camera"
//[u]=relative ScreenPosition.xy range [-1..1] u=vec2(0) is central
//[t]=camera looking direction=Target-CamPosition
vec3 camLookAt(vec2 u,vec3 t){t=normalize(t)
;vec3 o=normalize(cross(t,vec3(0,0,1)));
;vec3 l=normalize(cross(o,t));//2times normalize(cross()) is slow.
;return normalize(u.x*o+u.y*l+2.5*t );}

void main(void)
{
vec2 p=gl_FragCoord.xy;
p=p.xy/resolution.xy
;p=-1.0+2.0*p
;p.x*=-resolution.x/resolution.y
//;vec2 mo=mouse*resolution.xy.xy/resolution.xy;

;float d=50.,tim=time*.5
;vec3 t=vec3(cos(tim)*8.
            ,sin(tim+2.)*12.,4.)//cam target
;vec3 u=vec3(50.+cos(tim)*d
                ,sin(tim)*d*1.5,4.);//cam position
;t=camLookAt(p,t-u);
//aw man, the transition between worlds is a scripted timer.
;float w;
;if(cos(-time/4.)>.0)w=.0;else w=1.
;glFragColor=vec4(getPixel(w,u,t),1);}
 
/*
on "4d"
-
the "w" parameter is basically a 4th dimension
, here it is a boolean (for implicity) 
  but it could be generalized to a float.
Than it would be an "ease in" to how 4d space works
 and how i4d space can be used to simulate portals.
-
eg: rotations in 4d are double-quaterions=octonions.
just like you measure the distance to two 3d gradients (double 3d space)
, when they overlap, due to a portal that connects them.
eeg: 4d rotations are not necessarily coplanar
, 4d rotations are more likely fibrations around a torus surface.
-
eg: the camera moves in 1 circle trough 4d space
, which is 2 overlapping circles in 3d space.
this is actually a problem for root solving polinomials of degree higher than 5.
- - you must do 2 full rotations to return to your origina position.
- - this ambiguity makes it impossibly 
- -  to analytically solve polynomials of degree higher than 4
*/
