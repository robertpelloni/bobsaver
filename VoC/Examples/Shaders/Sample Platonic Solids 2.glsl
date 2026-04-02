#version 420

// original https://www.shadertoy.com/view/MtV3Dy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Crooks
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// An exercise in platonic geometry with signed distance funcions.
// https://en.wikipedia.org/wiki/Platonic_solid
// SDF
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// http://www.alanzucconi.com/2016/07/01/signed-distance-functions/

#define TWO_PI 6.283185
#define PI 3.14159265359
//Golden mean and inverse -  for the icosohedron and dodecadron
#define PHI 1.6180339887
#define INV_PHI 0.6180339887

struct Ray {
   vec3 origin;
   vec3 direction;
};

struct LightColor {
    vec3 diffuse;
    vec3 specular;
};
    
    
struct Material {
    LightColor  color;
    float shininess;
    float mirror;
    float refractiveIndex;
    float opacity;  
};
    
    
struct MapValue {
    float       signedDistance;
    Material  material;
};

struct Trace {
    float    dist;
    vec3     p;
    vec3 normal;
    Ray      ray;
    Ray reflection;
    Material material;
    bool hit;
};
    

struct PointLight {
    vec3 position;
    LightColor color;
};
    
struct DirectionalLight {
    vec3 direction;
    LightColor color;
};
    
PointLight  light1,light2;

Material blackMat,whiteMat,blueMat,yellowMat;

vec3 rayPoint(Ray r,float t) {
     return r.origin +  t*r.direction;
}

MapValue intersectObjects( MapValue d1, MapValue d2 )
{
    if (d1.signedDistance>d2.signedDistance){
        return    d1 ;
    }
    else {
        d2.material = d1.material;
        return d2;
    }
}

MapValue addObjects(MapValue d1, MapValue d2 )
{
    if (d1.signedDistance<d2.signedDistance) {
        return    d1 ;
    }
    else {
        return d2;
    }
}

MapValue subtractObjects( MapValue A, MapValue B )
{
    //A-B
    if (-B.signedDistance>A.signedDistance){
        B.signedDistance *= -1.0;
        B.material = A.material;
        return    B ;
    }
    else {
       
        return A;
    }
}

mat3 rotationMatrix(vec3 axis, float angle)
{
    //http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

float  plane(vec3 p, vec3 origin, vec3 normal){ 
   return dot(p - origin,normal);   
}

float  doubleplane(vec3 p, vec3 origin, vec3 normal){ 
   return max(dot(p - origin,normal),dot(-p - origin,normal));   
}

MapValue plane(vec3 p, vec3 origin, vec3 normal , Material m ){
 
  MapValue mv;
  mv.material = m;
   
  mv.signedDistance = plane(p,origin,normal);
  return mv;
}

MapValue sphere(vec3 p, float radius, Material m) {
  MapValue mv;
  mv.material = m;
  mv.signedDistance =length(p) - radius;
  return mv;
}

MapValue xzPlane( vec3 p ,float y, Material m)
{
  MapValue mv;
  mv.material = m;
  mv.signedDistance = p.y - y;
  return mv;
}

//////////////////////////////////////////////////////////
//---------------Platonic solids -----------------------//
//////////////////////////////////////////////////////////

//cube by iq
MapValue cube( vec3 p, float d , Material m)
{
  MapValue mv;
  mv.material = m;
 
  mv.signedDistance = length(max(abs(p) -d,0.0));
  return mv; 
}

MapValue tetrahedron(vec3 p, float d, Material m) {
    
  MapValue mv;
  mv.material = m;
 
  float dn =1.0/sqrt(3.0);
  
   //The tetrahedran is the intersection of four planes:
    float sd1 = plane(p,vec3(d,d,d) ,vec3(-dn,dn,dn)) ; 
    float sd2 = plane(p,vec3(d,-d,-d) ,vec3(dn,-dn,dn)) ;
     float sd3 = plane(p,vec3(-d,d,-d) ,vec3(dn,dn,-dn)) ;
     float sd4 = plane(p,vec3(-d,-d,d) ,vec3(-dn,-dn,-dn)) ;
  
    //max intersects shapes
    mv.signedDistance = max(max(sd1,sd2),max(sd3,sd4));
  return mv; 
}

MapValue octahedron(vec3 p,  float d, Material m) {
 
  //The octahedron is the intersection of two dual tetrahedra.  
  MapValue mv = tetrahedron(p,d,m);
  MapValue mv2 = tetrahedron(-p,d,m);
  
  mv = intersectObjects(mv,mv2);
    
  return mv; 
}   

MapValue alternativeOctahedron(vec3 p,  float d, Material m) {
   //Alternative construction of octahedran.
   //The same as for a terahedron, except intersecting double planes (the volume between two paralell planes). 
    
    MapValue mv;
    mv.material = m;
 
    float dn =1.0/sqrt(3.0);
    float sd1 = doubleplane(p,vec3(d,d,d) ,vec3(-dn,dn,dn)) ; 
    float sd2 = doubleplane(p,vec3(d,-d,-d) ,vec3(dn,-dn,dn)) ;
     float sd3 = doubleplane(p,vec3(-d,d,-d) ,vec3(dn,dn,-dn)) ;
     float sd4 = doubleplane(p,vec3(-d,-d,d) ,vec3(-dn,-dn,-dn)) ;
    
    mv.signedDistance = max(max(sd1,sd2),max(sd3,sd4));
  return mv; 
}   

MapValue dodecahedron(vec3 p,  float d, Material m) {
  
    MapValue mv;
    mv.material = m;

    //Some vertices of the icosahedron.
    //The other vertices are cyclic permutations of these, plus the opposite signs.
    //We don't need the opposite sign because we are using double planes - two faces for the price of one. 
    vec3 v = normalize(vec3(0.0,1.0,PHI));
    vec3 w = normalize(vec3(0.0,1.0,-PHI));
       
    //The dodecahedron is dual to the icosahedron. The faces of one corespond to the vertices of the oyther.
    //So we can construct the dodecahedron by intersecting planes passing through the vertices of the icosohedran.
    float ds = doubleplane(p,d*v,v);
    //max == intesect objects
    ds = max(doubleplane(p,d*w,w),ds); 

    ds = max(doubleplane(p,d*v.zxy,v.zxy),ds);
    ds = max(doubleplane(p,d*v.yzx,v.yzx),ds);

    ds = max(doubleplane(p,d*w.zxy,w.zxy),ds);
    ds = max(doubleplane(p,d*w.yzx,w.yzx),ds);
    
    mv.signedDistance = ds;
  
       
    return mv; 
}   

MapValue icosahedron(vec3 p,  float d, Material m) {
  
      MapValue mv;
      mv.material = m;
      float h=1.0/sqrt(3.0);
    
    
    //Same idea as above, using the vertices of the dodecahedron
    vec3 v1 = h* vec3(1.0,1.0,1.0);
    vec3 v2 = h* vec3(-1.0,1.0,1.0);
    vec3 v3 = h* vec3(-1.0,1.0,-1.0);
    vec3 v4 = h* vec3(1.0,1.0,-1.0);
   
    vec3 v5 = h* vec3(0.0,INV_PHI,PHI);
    vec3 v6 = h* vec3(0.0,INV_PHI,-PHI);
    
    float ds = doubleplane(p,d*v1,v1);
    //max == intesect objects
     ds = max(doubleplane(p,d*v2,v2),ds);
    ds = max(doubleplane(p,d*v3,v3),ds); 
    ds = max(doubleplane(p,d*v4,v4),ds);
    ds = max(doubleplane(p,d*v5,v5),ds); 
    ds = max(doubleplane(p,d*v6,v6),ds);
    
    //plus cyclic permutaions of v5 and v6:
    ds = max(doubleplane(p,d*v5.zxy,v5.zxy),ds); 
    ds = max(doubleplane(p,d*v5.yzx,v5.yzx),ds);
    ds = max(doubleplane(p,d*v6.zxy,v6.zxy),ds);
    ds = max(doubleplane(p,d*v6.yzx,v6.yzx),ds);
    
    mv.signedDistance = ds;
    
      return mv;
}   

//////////////////////////////////////////////////////////////

void setMaterials() {
    float t  = time;
    float s = 0.4*(1.0+sin(t));
    vec3 specular = vec3(0.3); 
    float shininess = 16.0;
    blackMat = Material(LightColor(vec3(0.0,0.0,0.01),vec3(0.1,0.1,0.1)) ,35.0,0.75,1.0,1.0);
    whiteMat = Material(LightColor(vec3(1.0),vec3(1.0)) ,shininess ,0.75,1.0,1.0);
    blueMat = Material(LightColor(vec3(0.3,0.3,0.75),vec3(0.3,0.3,1.0)) ,shininess ,0.75,1.0,1.0);
    yellowMat = Material(LightColor(vec3(0.8,0.8,0.4),vec3(0.9,0.9,0.2)) ,shininess ,0.75,1.0,1.0);
}

vec3 orbit(float t){
    return vec3(sin(t),0.0,cos(t));
}

/////////////////////Map the sceane/////////////////////////////////////////////

MapValue map(vec3 p){
   float t  = time;
   mat3 R = rotationMatrix(orbit(0.2*t),0.67*t);
   float r = 0.8; 
    
   MapValue objects = sphere(p,0.3,blackMat);
   
   // Add the five platonic solids
   objects = addObjects(objects,cube( R*(p + r*orbit(t)),0.25,whiteMat));
   objects = addObjects(objects,tetrahedron(R*(p + r*orbit(t+ TWO_PI*0.2)),0.25,whiteMat));
   objects = addObjects(objects,octahedron(R*(p + r*orbit(t+ TWO_PI*0.4)),0.35,whiteMat));
   objects = addObjects(objects,dodecahedron(R*(p + r*orbit(t+ TWO_PI*0.6)),0.25,whiteMat));
   objects = addObjects(objects,icosahedron(R*(p + r*orbit(t+ TWO_PI*0.8)),0.25,whiteMat));
   
   //add a floor and a cieling
   objects = addObjects(objects,xzPlane(p,-0.75,blueMat));
   objects = addObjects(objects,xzPlane(-p,-2.0,yellowMat));
    
   return objects;
}

///////////////////////////Raytracing////////////////////////////////////////

vec3 calculateNormal(vec3 p) {
    float epsilon = 0.001;
    
    vec3 normal = vec3(
                       map(p +vec3(epsilon,0,0)).signedDistance - map(p - vec3(epsilon,0,0)).signedDistance,
                       map(p +vec3(0,epsilon,0)).signedDistance - map(p - vec3(0,epsilon,0)).signedDistance,
                       map(p +vec3(0,0,epsilon)).signedDistance - map(p - vec3(0,0,epsilon)).signedDistance
                       );
    
    return normalize(normal);
}

Trace castRay(in Ray ray, float maxDistance){
    float dist = 0.01;
    float presicion = 0.001;
    vec3 p;
    MapValue mv;
    bool hit = false;
    for(int i=0; i<64; i++){
        p = rayPoint(ray,dist);
           mv = map(p);
         dist += 0.5*mv.signedDistance;
        if(mv.signedDistance < presicion)
        {
          hit = true; 
            break;
        } 
         if(dist>maxDistance) break;
       
    }
    return Trace(dist,p,p,ray,ray,mv.material,hit);
}

Trace traceRay(in Ray ray, float maxDistance) {
    Trace trace = castRay(ray,maxDistance);
    trace.normal = calculateNormal(trace.p);
    trace.reflection = Ray(trace.p,reflect(ray.direction, trace.normal));

    return trace;
}

float castShadow(in Ray ray, float dist){
    Trace trace = castRay(ray,dist);
    float maxDist = min(1.0,dist);
    float result = trace.dist/maxDist;
   
    return clamp(result,0.0,1.0);
}

Ray cameraRay(vec3 viewPoint, vec3 lookAtCenter, vec2 p , float d){ 
    vec3 v = normalize(lookAtCenter -viewPoint);
    
    vec3 n1 = cross(v,vec3(0.0,1.0,0.0));
    vec3 n2 = cross(n1,v);  
        
    vec3 lookAtPoint = lookAtCenter + d*(p.y*n2 + p.x*n1);
                                    
    Ray ray;
                    
    ray.origin = viewPoint;
       ray.direction =  normalize(lookAtPoint - viewPoint);
    
    return ray;
}

vec3 diffuseLighting(in Trace trace, vec3 lightColor,vec3 lightDir){
    float lambertian = max(dot(lightDir,trace.normal), 0.0);
      return  lambertian * trace.material.color.diffuse * lightColor; 
}

vec3 cookTorranceSpecularLighting(in Trace trace, vec3 lightColor,vec3 L){
    //https://en.wikipedia.org/wiki/Specular_highlight#Cook.E2.80.93Torrance_model
    //https://renderman.pixar.com/view/cook-torrance-shader
    
    
    vec3 V = -trace.ray.direction;

    vec3 H = normalize(L + V);
    
    float NdotH = dot(trace.normal, H);
    float NdotV = dot(trace.normal, V);
    float VdotH = dot(V ,H );
    float NdotL = dot(trace.normal , L);
    
    float lambda  = 0.25;
    float F = pow(1.0 + NdotV, lambda);
    
    float G = min(1.0,min((2.0*NdotH*NdotV/VdotH), (2.0*NdotH*NdotL/VdotH)));
    
    
   // Beckmann distribution D
    float alpha = 5.0*acos(NdotH);
    float gaussConstant = 1.0;
    float D = gaussConstant*exp(-(alpha*alpha));
    
    
    float c = 1.0;
    float specular = c *(F*D*G)/(PI*NdotL*NdotV);
    
    
    return specular * trace.material.color.specular * lightColor;
}

vec3 pointLighting(in Trace trace, PointLight light){
    vec3 lightDir = light.position - trace.p;
    float d = length(lightDir);
      lightDir = normalize(lightDir);
   
      vec3 color =  diffuseLighting(trace, light.color.diffuse, lightDir);

    color += cookTorranceSpecularLighting(trace, light.color.specular, lightDir);

    float  attenuation = 1.0 / (1.0 +  0.1 * d * d);
    float shadow = castShadow(Ray(trace.p,lightDir),d);
    color *= attenuation*shadow;
    return  color;
}

vec3 directionalLighting(Trace trace, DirectionalLight light){

    vec3 color =  diffuseLighting(trace, light.color.diffuse, light.direction);
    
    color += cookTorranceSpecularLighting(trace, light.color.specular, light.direction);
    
    float shadow = castShadow(Ray(trace.p,light.direction),3.0);
    color *= shadow;
    return  color;
}

void setLights(){
      float  time = time;
    vec3 specular = vec3(1.0);
      light1 = PointLight(vec3(cos(1.3*time),1.0,sin(1.3*time)),LightColor( vec3(1.0),specular));
      light2 = PointLight(vec3(0.7*cos(1.6*time),1.1+ 0.35*sin(0.8*time),0.7*sin(1.6*time)),LightColor(vec3(1.0),specular)); 
} 

vec3 lighting(in Trace trace){
    vec3 color = vec3(0.01,0.01,0.2);//ambient color     
    color += pointLighting(trace, light1);
    color += pointLighting(trace, light2) ;

    return color;
}

float rayDistance(Ray r,vec3 p){
    vec3 v = r.origin - p;
    return length(v - dot(v,r.direction)*r.direction);
}

vec3 render(vec2 p){
    vec3 viewpoint = vec3(-1.0,1.9,-2.3);
    
    vec3 lookAt = vec3(0.0,-0.15,0.0);
    
      Ray ray = cameraRay(viewpoint,lookAt,p,2.4);
    vec3 color = vec3(0.0);
    float frac = 1.0;
   
    float d = 0.0;
    float maxDistance = 7.0;
    for(int i = 0; i<2; i++) {
        Trace trace = traceRay(ray,maxDistance);
        
         if(i==0) d = trace.dist;
        maxDistance -= trace.dist;
        color += lighting(trace)*(1.0 - trace.material.mirror)*frac;
        if(!trace.hit) break;
        
        frac *= trace.material.mirror;
        if(frac < 0.1 || maxDistance<0.0) break;
        ray = trace.reflection;
    }
       
    
   
       return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
      setLights();
    setMaterials();
    
       vec3 colorLinear =  render(p);
    float screenGamma = 2.2;
    vec3 colorGammaCorrected = pow(colorLinear, vec3(1.0/screenGamma));
    glFragColor = vec4(colorGammaCorrected,1.0);
}
