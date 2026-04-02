#version 420

// original https://www.shadertoy.com/view/NlBGDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//***************************************************************//
// Bicomplex Mandelbrot by CMiller (kibitz9)
// A bicomplex mandelbrot sliced in half to show the set inside.
// The interior distance estimate is not accurate hence the banding.
//***************************************************************// 

const float GLOBAL_EPSILON = .0005;
const vec2 GLOBAL_PN = vec2(1,-1);
const vec3 GLOBAL_PN_XYY=GLOBAL_PN.xyy;
const vec3 GLOBAL_PN_YYX=GLOBAL_PN.yyx;
const vec3 GLOBAL_PN_YXY=GLOBAL_PN.yxy;
const vec3 GLOBAL_PN_XXX=GLOBAL_PN.xxx;

const vec3 GLOBAL_PN_XYY_EPS=GLOBAL_PN_XYY*GLOBAL_EPSILON;
const vec3 GLOBAL_PN_YYX_EPS=GLOBAL_PN_YYX*GLOBAL_EPSILON;
const vec3 GLOBAL_PN_YXY_EPS=GLOBAL_PN_YXY*GLOBAL_EPSILON;
const vec3 GLOBAL_PN_XXX_EPS=GLOBAL_PN_XXX*GLOBAL_EPSILON;
const float MAX_DIST = 10.0;

vec4 square(vec4 B){
    //Bicomplex square
    float a=B.x;
    float b=B.y;
    float c=B.z;
    float d=B.w;
    return vec4(
         a* a- b* b- c* c+ d* d
        ,2.* a* b-2.* c* d
        ,2.* a* c-2.* b* d
        ,2.* a* d+2.* b* c
     );
}
vec4 mult(vec4 A, vec4 B){
    //Bicomplex multiplication
    float a=A.x;
    float b=A.y;
    float c=A.z;
    float d=A.w;
    float e=B.x;
    float f=B.y;
    float g=B.z;
    float h=B.w;
    
    return vec4(
        a*e-b*f-c*g+d*h,
        b*e+a*f-d*g-c*h,
        c*e-d*f+a*g-b*h,
        d*e+c*f+b*g+a*h
    );
        
}

vec4 zero = vec4(0,0,0,0);
vec4 two = vec4(2,0,0,0);
vec4 one = vec4(1,0,0,0);

float mb(in vec4 c, in int itr){

    vec4 z=zero;
    vec4 dz=one;
    int a=0; 
    for (;a<itr;a++){

        dz=mult(2.0*z,dz)+1.;
        z=square(z)+c;
      
        float sqrd = dot(z,z);
        if (sqrd>10000.){
            break;
        }
    }
    if (a==itr-1){
        return 0.;
    }
    float lz = length(z);
    float ldz = length(dz);
    float dist = (log(lz)*lz)/ldz;
    
    return dist/2.;
  

}

float map(in vec3 q){

    //return 1.0;
    vec3 p=q;

    float lookDown=.2;
    p=vec3(p.x,p.y*cos(lookDown)+p.z*-sin(lookDown),p.z*cos(lookDown)+p.y*sin(lookDown));

    float rot = 4.25;

    p =vec3(
        p.x*cos(time/rot)+p.z*-sin(time/rot),
        p.y
        ,p.z*cos(time/rot)+p.x*sin(time/rot)
        );

    p=p+vec3(0.,-2.,0.);
    

    
    float m= mb(vec4(p.x-.1,p.y,p.z,0.),100);
    
    //float m2= mb(vec4(-q.y+1.1,q.x-2.5,q.z,0.),20);
    
    
    m=abs(m)-.0001;
    m=max(m,-p.z-0.);
    m=min(m,q.y-.1);
    m=min(m,-q.z+3.);
    //m=min(m,m2);
    
    
    return m;
 }
    
    
    
 
    

vec3 getSurfaceNormal( in vec3 p, float epsilon ) // for function f(p)
{
  
    return normalize(
        GLOBAL_PN_XYY*map(p+GLOBAL_PN_XYY_EPS) +
        GLOBAL_PN_YYX*map(p+GLOBAL_PN_YYX_EPS) +
        GLOBAL_PN_YXY*map(p+GLOBAL_PN_YXY_EPS) +
        GLOBAL_PN_XXX*map(p+GLOBAL_PN_XXX_EPS) 
    
    );
}

void rayMarch(
    in vec3 origin, 
    in vec3 ray, 
    in float epsilon,
    in float maxSteps,
   
    out vec3 marchPoint,
    out float marchPointDist,
    out float stepsTaken

){
    
  
    
    stepsTaken = 0.0;
    marchPoint=origin;
    float h = map(marchPoint);
    while (h>epsilon&&stepsTaken++<maxSteps&&h<MAX_DIST){
        marchPoint+=ray*h;       
        h=map(marchPoint);
    }   
    marchPointDist=h;
}

float softShadowBalanced(vec3 surface, vec3 light, float radius, float maxDist){
   
    
      
    vec3 surfaceToLight = light-surface;
    float distanceToLight=length(surfaceToLight);
    float maxDist2 = min(maxDist,distanceToLight);
    vec3 ray =normalize(surfaceToLight);
    float artifactCompensation = 2.0;
    float minDist = .001;//think about this.
    
    float travelled = minDist;
    float xx=1.0;
    while (travelled < maxDist2){
    
        float ratioTravelled=travelled/distanceToLight;
        
       
        float relativeRadius=ratioTravelled*radius;
        
        float dist=map(surface+ray*travelled);
         
        if (dist<-relativeRadius){
            return 0.0;
        }
        float relativeDiameter=relativeRadius*2.0;
        
        float dist2=dist+relativeRadius;
        xx = min(xx,dist2/relativeDiameter);
        
       
        float artifatCompensation2 = artifactCompensation*clamp(relativeRadius/dist,0.,1.);
        travelled +=max(abs(dist/artifactCompensation),minDist);
        
        
    }
       
   return xx;
    

    
}

vec3 power(vec3 vec, float power){
    return vec3(pow(vec.x,power),pow(vec.y,power),pow(vec.z,power));
}

void calcLight(
    in vec3 surfacePoint, 
    in float shineAtPosition,
    in vec3 lightPosition,
    in vec3 observationPosition,
    in vec3 lightColor,
    in float lightBrightness,
    in vec3 surfaceNormal,
    in float epsilon,
    out vec3 diffuse, 
    out vec3 specular){
    
 
     
    vec3 col0 = lightColor;
    
    
    vec3 surfaceToLight=lightPosition-surfacePoint;
    vec3 normalToLight=normalize(surfaceToLight);
    
    float oneOverDistToLightSquared = lightBrightness/dot(surfaceToLight,surfaceToLight);
    
    
    
    float dp = dot(normalToLight,surfaceNormal);
 
    dp=max(dp,0.0);

    
    diffuse=dp*lightColor*oneOverDistToLightSquared;
    
    
    vec3 rayToObs=normalize(observationPosition-surfacePoint);
    vec3 avg = normalize(normalToLight+rayToObs);
    float spec = dot(avg,surfaceNormal);
    spec = max(spec,0.0);
    
    spec = pow(spec,shineAtPosition);

    specular=lightColor*spec*oneOverDistToLightSquared;
    
    float shadowAdjust = 1.0;
    

    if (true){
        float s = softShadowBalanced(surfacePoint,lightPosition,5.0, 500.); 
        diffuse*=s*shadowAdjust;
        specular*=s*shadowAdjust;
    }
 
}

void main(void)
{

    vec3 eye = vec3(0.0,0.0,-.5);
    vec3 lense = vec3(0.0,0.0,.5);
    float xxx = 0.;
    vec3 cameraPosition = vec3(0.,2.,-(6.+xxx)+sin(time/10.)*xxx);
    float specAmt = 0.0;

    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float epsilon1 = .002;
    
   
    vec3 objColor=vec3(1,1,1);
  
    vec2 ar = (gl_FragCoord.xy/resolution.x)
        -vec2(.5,resolution.y/(2.0*resolution.x));
    vec3 lenseIntersection = vec3(ar,lense.z);
    
    vec3 ray = normalize(lenseIntersection-eye);
   
    
    float stepsTaken;
    vec3 finalPosition;
    float finalDistance;

    float maxSteps = 4000.0;
    
    rayMarch(eye+cameraPosition,ray,epsilon1,maxSteps,finalPosition,finalDistance,stepsTaken);
    
  
    
    float objectShine=7.;
    
    
    vec3 diffuse1;
    vec3 specular1;

    vec3 diffuse2;
    vec3 specular2;

    vec3 diffuse3;
    vec3 specular3;

    vec3 diffuse4;
    vec3 specular4;
    if (finalDistance<epsilon1){
    

        finalPosition = finalPosition+(ray*epsilon1*-2.0);
        vec3 normal = getSurfaceNormal(finalPosition,epsilon1);
        
       
        
        float lightBrightness = 1400.;
        float specMult = 2.0;
        
        calcLight(
            finalPosition,
            objectShine,
            vec3(60.0,80.0,-80.0),//lightposition
            eye+cameraPosition,//observation position
            vec3(.5,.5,1)*.5,//light color
            lightBrightness*20.,//light bright
            normal,
            epsilon1,
            diffuse1,
            specular1
        );
        
        /*
         calcLight(
            finalPosition,
            objectShine,
            vec3(-60.0,80.0,-80.0),//lightposition
            eye+cameraPosition,//observation position
            vec3(.6,.5,0.)*.5,//light color
            lightBrightness*4.,//light bright
            normal,
            epsilon1,
            diffuse2,
            specular2
        );
        */
        /*
        calcLight(
            finalPosition,
            objectShine,
            vec3(-60.0,30.0,-40.0),//lightposition
            eye+cameraPosition,//observation position
            vec3(.5,1.,.1)*.5,//light color
            lightBrightness*1.,//light bright
            normal,
            epsilon1,
            diffuse2,
            specular2
        );
        */
        /*
        calcLight(
            finalPosition,
            objectShine,
            vec3(130.0,30.0,-480.0),//lightposition
            eye+cameraPosition,//observation position
            vec3(1.,.9,.3)*.5,//light color
            lightBrightness*5.,//light bright
            normal,
            epsilon1,
            diffuse3,
            specular3
        );
        */
        
        
        /*
        calcLight(
            finalPosition,
            objectShine,
            vec3(0.0,10.0,-5.0),//lightposition
            eye+cameraPosition,//observation position
            vec3(1.,.8,.5)*.5,//light color
            lightBrightness/20000.,//light bright
            normal,
            epsilon1,
            diffuse4,
            specular4
        );
    */
    
    
        vec3 col1=objColor*max(diffuse1,0.0);
        col1+=specular1*specMult;
        
        //vec3 col2=objColor*max(diffuse2,0.0);
       // col2+=specular2*specMult;
        
        //vec3 col3=objColor*max(diffuse3,0.0);
        //col3+=specular3*specMult;
        
        //vec3 col4=objColor*max(diffuse4,0.0);
        //col4+=specular4*specMult;
        
        
      
        
        //vec3 colFinal = min(col1+col2,1.0);
        //vec3 colFinal = min(col1+col2+col3+col4,1.);
        vec3 colFinal = min(col1,1.);
        colFinal=power(colFinal,.9);
        glFragColor = vec4(colFinal,1.0);
        
    }
    else{
        glFragColor = vec4(.2,0,0,1.0);

    }
    
    
    
    
    
}
