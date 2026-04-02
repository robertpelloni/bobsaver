#version 420

// original https://www.shadertoy.com/view/dscyD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

const int MAX_MARCHING_STEPS=255;
const float MIN_DIST=0.;
const float MAX_DIST=100.;
const float PRECISION=.001;
const float EPSILON=.0005;
const float PI=3.14159265359;

const int FLOOR_ID=1;
const int CURTAINS_ID=2;
const int CEILING_ID=3;
const int LAMP_ID=4;
const int SOFA_ID=5;
const int BULB_ID=6;

const vec2 lamp=vec2(1.,.9);

struct Surface{
  float sd;
  int id;
};

float max2(vec2 v){return max(v.x,v.y);}

mat2 rotate2d(float theta){
  float s=sin(theta),c=cos(theta);
  return mat2(c,-s,s,c);
}

Surface sMin(Surface s1,Surface s2){
  if(s1.sd<s2.sd){
    return s1;
  }
  return s2;
}

float sdBox(in vec2 p,in vec2 b)
{
  vec2 d=abs(p)-b;
  return length(max(d,0.))+min(max(d.x,d.y),0.);
}

float sdBox(vec3 p,vec3 b){
  vec3 q=abs(p)-b;
  return length(max(q,0.))+min(max(q.x,max2(q.yz)),0.);
}

float sdPlane(vec3 p,vec3 n,float h)
{
  return dot(p,n)+h;
}

float sdRoundBox(vec3 p,vec3 b,float r)
{
  vec3 q=abs(p)-b;
  return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;
}

Surface sLamp(vec3 p){
  float radius=length(p.xz-vec2(4.,6.));
  float stem=max(p.y-.5,radius-.1);
  float con = max(p.y - 2., max(.5 - p.y, radius - .1 - .4 * p.y));
  float cone = max(p.y - 1.5, max(.5 - p.y, .5 * (radius - .1 - pow(p.y - .5, 2.))));

  Surface support = Surface(min(stem, con), LAMP_ID);
  Surface bulb = Surface(length(p - vec3(4.0, 1.5, 6.)) - 0.5, BULB_ID);
  return sMin(support, bulb);
}

float sdSofa(vec3 p){
  p.x=abs(p.x);
  float box1=sdRoundBox(p+vec3(0.,1.,0.),vec3(3.,1.,1.),1.);
  float box2=sdRoundBox(p-vec3(.5,0.,-1.5),vec3(2,3.,.1),1.);
  float box3=sdRoundBox(p-vec3(3.5,0.,.5),vec3(.01,1.5,1.),.9);
  
  return min(box1,min(box2,box3));
}

Surface scene(vec3 p){
  Surface floor=Surface(p.y+8.5,FLOOR_ID);
  Surface room=Surface(-sdBox(p-vec3(0.,0.,5.),vec3(60.,30.,20.)),CEILING_ID);
  Surface wall1=Surface((-p.x-.3*sin(p.z*4.)-.2*sin(p.z*8.)+8.)*.6,CURTAINS_ID);
  Surface wall2=Surface((p.z+.3*sin(p.x*4.)-+.2*sin(p.x*8.)+13.)*.6,CURTAINS_ID);
  
  Surface lamp1=sLamp(p-vec3(-13.,0,-15.));
  Surface lamp2=sLamp(p-vec3(1.5,0,-15.));
  
  Surface sofa1=Surface(sdSofa(p-vec3(-2.,-7,-8.)),SOFA_ID);
  Surface sofa2=Surface(sdSofa(p-vec3(-15.,-7,-8.)),SOFA_ID);
  
  Surface co=sMin(floor,room);
  co=sMin(co,wall1);
  co=sMin(co,wall2);
  co=sMin(co,lamp1);
  co=sMin(co,lamp2);
  co=sMin(co,sofa1);
  co=sMin(co,sofa2);
  
  return co;
}

Surface rayMarch(vec3 ro,vec3 rd){
  float depth=MIN_DIST;
  Surface d;
  
  for(int i=0;i<MAX_MARCHING_STEPS;i++){
    vec3 p=ro+depth*rd;
    d=scene(p);
    depth+=d.sd;
    if(d.sd<PRECISION||depth>MAX_DIST)break;
  }
  
  d.sd=depth;
  
  return d;
}

vec3 calcNormal(in vec3 p){
  vec2 e=vec2(1,-1)*EPSILON;
  return normalize(
    e.xyy*scene(p+e.xyy).sd+
    e.yyx*scene(p+e.yyx).sd+
    e.yxy*scene(p+e.yxy).sd+
    e.xxx*scene(p+e.xxx).sd);
  }
  
mat3 camera(vec3 cameraPos,vec3 lookAtPoint){
    vec3 cd=normalize(lookAtPoint-cameraPos);
    vec3 cr=normalize(cross(vec3(0,1,0),cd));
    vec3 cu=normalize(cross(cd,cr));
    
    return mat3(-cr,cu,-cd);
  }
  
vec3 phong(vec3 lightDir,vec3 normal,vec3 rd,vec3 col){
    // ambient
    float k_a=.7;
    vec3 i_a=col;
    vec3 ambient=k_a*i_a;
    
    // diffuse
    float k_d=.5;
    float dotLN=clamp(dot(lightDir,normal),0.,1.);
    vec3 i_d=vec3(1.);
    vec3 diffuse=k_d*dotLN*i_d;
    
    // specular
    float k_s=.9;
    float dotRV=clamp(dot(reflect(lightDir,normal),-rd),0.,1.);
    vec3 i_s=vec3(1,1,1);
    float alpha=10.;
    vec3 specular=k_s*pow(dotRV,alpha)*i_s;
    
    return ambient+diffuse+specular;
  }
  
vec3 applyLightning(vec3 p,vec3 rd,Surface d){
    vec3 col=vec3(0.);
    if(d.sd>MAX_DIST){
      col=vec3(0.);// ray didn't hit anything
    }else{
      vec3 normal=calcNormal(p);// surface normal
      
      vec3 lightPosition=vec3(0,3,-4);
      vec3 lightDirection=normalize(lightPosition-p);
      
      vec3 lightPosition1=vec3(-13.,5.,-10.);
      vec3 lightDirection1=normalize(lightPosition1-p);
      
      if(d.id==FLOOR_ID){
        p.xz/=4.;
        p.x=abs(mod(p.x,1.)-.5);
        float a=mod(p.z-p.x,.5);
        if(a<.25)col=vec3(.1,0.,0.);
        else col=vec3(1.);
      }else if(d.id==CURTAINS_ID){
        col=vec3(1.,0.,0.);
      }else if(d.id==CEILING_ID){
        col=vec3(1.);
      }else if(d.id==LAMP_ID){
        col=vec3(1.);
      } else if (d.id == BULB_ID) {
        col = vec3(1.,1.,0.);
      }
      
      col=.3*phong(lightDirection,normal,rd,col);
      col+=.3*phong(lightDirection1,normal,rd,col);
    }
    
    return col;
}

void main(void)
{

    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 mouseUV=mouse*resolution.xy.xy/resolution.xy;
    
    vec3 col=vec3(0);
    vec3 lp=vec3(0);// lookat point
    vec3 ro=vec3(0,0,10.);// ray origin that represents camera position
    
    float cameraRadius=2.;
    ro.yz=ro.yz*cameraRadius*rotate2d(mix(-PI/8.,PI/8.,mouseUV.y));
    ro.xz=ro.xz*rotate2d(mix(-PI/16.,PI/8.,mouseUV.x+.2*sin(time * 2.)))+vec2(lp.x,lp.z);
    
    vec3 rd=camera(ro,lp)*normalize(vec3(uv,-1));// ray direction
    
    Surface d=rayMarch(ro,rd);// signed distance value to closest object
    
    vec3 p=ro+rd*d.sd;// point on surface found by ray marching
    col=applyLightning(p,rd,d);
    
    glFragColor=vec4(col,1.);
}
