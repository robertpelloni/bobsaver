#version 420

// original https://www.shadertoy.com/view/lldSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Crooks
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define TWO_PI 6.283185
#define PI 3.14159265359

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
    
PointLight  light1,light2,light3;
DirectionalLight dirLight;

Material blackMat,whiteMat,bluishMat,yellowMat,oscMat,tableMat,tableDarkMat;

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
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

//sdCapsule by iq
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

MapValue plane(vec3 p, vec3 origin, vec3 normal , Material m ){
    vec3 a = p - origin;
    MapValue mv;
    mv.material = m;

    mv.signedDistance = dot(a,normal);
    return mv;
}

float  plane(vec3 p, vec3 origin, vec3 normal){ 
    return dot(p - origin,normal);   
}

float tetrahedron(vec3 p, float d) {
    
    float dn =1.0/sqrt(3.0);

    float mv1 = plane(p,vec3(d,d,d) ,vec3(-dn,dn,dn)) ; 
    float mv2 = plane(p,vec3(d,-d,-d) ,vec3(dn,-dn,dn)) ;
    float mv3 = plane(p,vec3(-d,d,-d) ,vec3(dn,dn,-dn)) ;
    float mv4 = plane(p,vec3(-d,-d,d) ,vec3(-dn,-dn,-dn)) ;

    //max intersects shapes
    //So this is the intersection of four planes.
    return max(max(mv1,mv2),max(mv3,mv4));
}

float octahedron(vec3 p,  float d) {
  
    float mv = tetrahedron(p,d);
    float mv2 = tetrahedron(-p,d);

    return  max(mv,mv2); 
}   

float stellatedOctahedron(vec3 p,  float d) {
  
    float mv = tetrahedron(p,d);
    float mv2 = tetrahedron(-p,d);
    
    //The stellated Octahedron is 
    return  min(mv,mv2); 
}   

bool tileing(vec2 point)
{
    float t = time;
    float h = sqrt(3.0)/2.0;
       vec3 u = vec3(1.0,-0.5,-0.5);
       vec3 v = vec3(0,h,-h);
    
    vec3 n = vec3(0.5);
    
    float scaleFactor = 5.0;
    vec2 q = point*scaleFactor + 0.3*time;
    vec3 p = n + q.x*u +q.y*v;
    
    p = floor(p);
    
    float i = p.x + p.y + p.z;
    float j = p.x  + p.y;
    float k = p.x  + p.z;
    
    float a = mod(i,2.0);
    float b = mod(j,2.0);
    float c = mod(k,2.0);
        
    if (a>0.1)
    {
        return false;
    }
    else {
        if(b>0.1){
           if(c>0.1){
                return false;
            }
            else {
                return true;
            } 
        }
        else {
            return true;
        }
    }
}

bool octTileing3d(vec2 point)
{
    //This pattern takes a slice through a grid of stellated octahedron.
    //I'm fairly sure there are much more effiecient ways to draw this tiling - e.g. with alternating cubes.
    //But I think its interesting to use the geomtry of the stellated octahedron.
    
    float t = time;
    float h = sqrt(3.0)/2.0;
       vec3 u = vec3(1.0,-0.5,-0.5);
       vec3 v = vec3(0,h,-h);
    
    vec3 n = vec3(0.5);
    float scaleFactor = 2.5;
    vec2 q = point*scaleFactor;
    vec3 p = n + q.x*u +q.y*v;
    
    vec3 w = mod(p,1.0);
    w = 2.0*w - vec3(1.0);
    
    float o1 = octahedron(w,1.0);
    float o2 = octahedron(w,0.8);
    float so1 = stellatedOctahedron(v,1.0);
    
    if(o1>0.0){
        //outside octahedron o1
        if(so1>0.0){
            //outside stellatedOctahedron
            return true;
        }
        else{
            //inside stellatedOctahedron
           return false; 
        }  
    }else{
        //inside octahedron o1
        if(o2>0.0){
            //outside octahedron o2
            return true;
        }
        else{
            //inside octahedron o2
            return false;
        }
    }
}

MapValue xzPlane( vec3 p ,float y, Material m)
{
    MapValue mv;
    mv.material = m;
    mv.signedDistance = p.y - y;
    return mv;
}

#define USE_OCTAHEDRAL_PATTERN false

MapValue tableTop( vec3 p ,float y, Material m1,Material m2)
{
     Material  m;
    //Draw a pattern on the table top by taking a 2d slice through a 3d checkerboard.
   
    bool patternValue;
    
    if(USE_OCTAHEDRAL_PATTERN){
        //This is slow, but its nice that the pattern is based on the geometry of the stellated octahedron. 
        patternValue = octTileing3d(p.xz);
    }
    else {
        //Similar pattern, but faster.
        patternValue = tileing(p.xz);
    }
    
    if(patternValue){
        m = m1;
    }
    else {
       m = m2 ;
    }
    
  return xzPlane( p ,y, m);
}

MapValue cubeFrame(vec3 p, float d,float thickness, Material m){
    
    MapValue mv;
    mv.material = m;

    float r = d*thickness;
    float dt = sdCapsule(  p, vec3(d,d,d),vec3(-d,d,d), r );
    
    //min adds shapes
    dt = min(dt,  sdCapsule(  p, vec3(-d,d,d),vec3(-d,-d,d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(-d,-d,d),vec3(d,-d,d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(d,-d,d),vec3(d,d,d), r ));

    dt = min(dt,  sdCapsule(  p, vec3(d,d,-d),vec3(-d,d,-d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(-d,d,-d),vec3(-d,-d,-d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(-d,-d,-d),vec3(d,-d,-d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(d,-d,-d),vec3(d,d,-d), r ));

    dt = min(dt,  sdCapsule(  p, vec3(d,d,-d),vec3(d,d,d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(-d,d,-d),vec3(-d,d,d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(-d,-d,-d),vec3(-d,-d,d), r ));
    dt = min(dt,  sdCapsule(  p, vec3(d,-d,-d),vec3(d,-d,d), r ));

    mv.signedDistance = dt;

    return mv;
}

MapValue stellatedOctahedron(vec3 p,float d, Material m) {
  return MapValue(stellatedOctahedron(p,d),m); 
}

vec3 orbit(float t){
    return vec3(sin(t),0.0,cos(t));
}

void setMaterials() {
    vec3 specular = vec3(1.0); 
    float shininess = 16.0;
    whiteMat = Material(LightColor(0.95*vec3(1.0,1.0,1.0),0.3*vec3(1.0,1.0,1.0)) ,shininess ,0.75,1.0,1.0);
    tableDarkMat = Material(LightColor(vec3(0.2,0.2,0.35),vec3(0.33,0.33,0.31)) ,shininess ,0.75,1.0,1.0);   
}

///////////////////////////////////////////////////////////////
//------------------- Map the scene -------------------------//

MapValue map(vec3 p){
    
   float t  = time;
   mat3 rotate = rotationMatrix(orbit(0.2*t),0.67*t);
   vec3 q = rotate*p;
    
   MapValue objects = stellatedOctahedron(q,0.5,whiteMat);
   //Add a frame to show how the stellated octahedron is embedded in a cube
   objects = addObjects(objects,cubeFrame(q,0.5,0.04,whiteMat));
   //patterned tabletop
   objects = addObjects(objects,tableTop(p,-1.0,whiteMat,tableDarkMat));
   //add a  roof to reflect off
   objects = addObjects(objects,xzPlane(-p,-2.0,whiteMat));
    
   return objects;
}

////////////////////////////////////////////////////////////
//------------------- Raytracing -------------------------//

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
  //  light3 = PointLight(vec3(1.5*cos(1.6*time),0.15+ 0.15*sin(2.9*time),1.5*sin(1.6*time)),LightColor(vec3(0.6),specular));
    //dirLight = DirectionalLight(normalize(vec3(0.0,1.0,0.0)),LightColor(vec3(0.1),vec3(0.5)));
} 

vec3 lighting(in Trace trace){
    vec3 color = vec3(0.01,0.01,0.1);//ambient color
        
    color += pointLighting(trace, light1);
    color += pointLighting(trace, light2) ;
   // color += pointLighting(trace, light3) ;
    //color += directionalLighting(trace, dirLight);
    
    return color;
}

vec3 render(vec2 p){
    vec3 viewpoint = vec3(-1.0,1.7,-2.3);
    
    vec3 lookAt = vec3(0.0,-0.1,0.0);
    
      Ray ray = cameraRay(viewpoint,lookAt,p,2.4);
    vec3 color = vec3(0.0);
    float frac = 1.0;
   
    float d = 0.0;
    float maxDistance = 10.0;
    for(int i = 0; i<3; i++) {
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
