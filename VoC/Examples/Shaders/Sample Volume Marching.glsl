#version 420

// original https://www.shadertoy.com/view/lljcR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//noise
float h11(float n){return fract(sin(n)*43758.5453);}
float noise(in vec3 x){vec3 p=floor(x),f=fract(x)
;f=f*f*(3.-2.*f);float n=p.x+p.y*57.+113.*p.z
;return mix(mix(mix(h11(n+  .0),h11(n+  1.),f.x),
                mix(h11(n+ 57.),h11(n+ 58.),f.x),f.y),
            mix(mix(h11(n+113.),h11(n+114.),f.x),
                mix(h11(n+170.),h11(n+171.),f.x),f.y),f.z);}
const mat3 m=mat3(0,8,6,-8,3,-4,-6,-4, 6 )*.1;//fbm rotation matrix
float fbm(vec3 p){float f=.5*noise(p)
;p*=m*2.02;f+=.25*noise(p)
;p*=m*2.03;f+=.125*noise(p)
;return f;}

//distanceFieldGadient that we volume march trough
float gdVolume(vec3 p){return.1-length(p)*.05+fbm(p*.3);}

//I could define everything as a very dense cloud
//and volume march it, but that seems inefficient.
//doing deferred shading of cloud and npn-cloud (special cases) 
//is not much simpler though, or is it
//yes the second approah is simpler, more flexible and more hacky.

//Volume marching iterations, outer and inner loop
//outerLoop<=64 samples along viewRay
//innerLoop<= 6 samples along LightDirection
#define iterMarchVolume vec2(64,6)

//(orange) color of least scattered light in (earths) athmosphere
//depends on pollution
#define clAmbi vec4(.9,.6,.1,1)
//(bue sky color) color of most scattered light in (earths) athmosphere
#define cDiff vec4(1.-clAmbi.xyz,1)
//HDR usually over-ambolidies this to white.
//ie, even the red ammount of scattered light is (nearly)maxed.
#define clDiff vec4(pow(cDiff.xyz,vec3(cos(time*.5+.5))),1)

//brightness scale of lit parts of cloud
#define cloudBright 90.
//brightness scale of occluded parts of cloud
#define cloudDark 60.
//aboove 2 values also scale the .rgb of orangeBlue scatter.

//return color of volumeMarching (trough a cloud)
//[u]RayOrigin
//[t]RayDirection
//[s]SunlightDirection (parallel, infinite distance)
vec4 MarchVolume(vec3 u,vec3 t,vec3 s){
;t=normalize(t);//save>sorry
;vec4 c=vec4(0)//return vaslue
;const vec2 stepn=vec2(40,20)/iterMarchVolume;//2 loop params
;float a=1.,b=110.//diminishing accumulator//absorbtion
;for(float i=.0;i<iterMarchVolume.x;i++)
{;float d=gdVolume(u)
 ;if(d>0.)
 {;d=d/iterMarchVolume.x
  ;a*=1.-d*b
  ;if(a<=.01)break
  ;float Tl=1.
  ;for(float j=.0;j<iterMarchVolume.y; j++)
  {;float l=gdVolume(u+normalize(s)*float(j)*stepn.y)
   //todo, also calculate occlusion of a non-clud distance field.
   ;if(l>0.)
    Tl*=1.-l*b/iterMarchVolume.x
   ;if(Tl<=.01)break;}
  ;c+=clDiff*cloudDark*d*a//light.diffuse
  ;c+=clAmbi*cloudBright*d*a*Tl;//light.ambbience
 ;}
 ;u+=t*stepn.x;}    
;return max(c,(cDiff*cDiff));//;return c
;}

void main(void) {
vec2 u=gl_FragCoord.xy;
;u=u.xy/resolution.xy
;u=u*2.-1.
;u.x *= resolution.x/ resolution.y;
;vec2 mo
;mo=vec2(time*.1,cos(time*.25)*3.)
;vec3 org=25.*normalize(vec3(cos(2.75-3.*mo.x),.7-(mo.y-1.0),sin(2.75-3.*mo.x)))
;vec3 ta=vec3(0,1,0)
;vec3 ww=normalize(ta-org)
;vec3 uu=normalize(cross(ta,ww))
;vec3 vv=normalize(cross(ww,uu))
;vec3 di=normalize(u.x*uu+u.y*vv+1.5*ww)
;vec3 s=vec3(1,0,0)//sinLightDirection
;glFragColor=MarchVolume(org,di,s);

}
