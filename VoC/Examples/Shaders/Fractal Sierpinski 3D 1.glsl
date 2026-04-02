#version 420

// original https://www.shadertoy.com/view/4lSXW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Render
const int   MaxSteps        = 64;   //maximum steps when raymarching
const float MaxDistance     = 10.;  //maximum distance from distance field(stops rays from going to nothing)
const float Epsilon         = 0.001;//distance below epsilon is counted as a hit
const float BackStep        = 0.002;//backstep away from surface when reflecting (shadows,reflections)
const float Delta           = 0.01;  //delta used for normal calculation
const float Occlusion       = 0.1;  //Occlusion distance until there is none

//Fractal
const int   Iterations      = 8;
const float Thickness       = 1.414;//sqrt(2)

//Lighting
const vec3  SkyColor        = vec3(.55,.66,1.);
const vec3  SunVector       = vec3(0.577);//normalize(vec3(1));
const vec3  SunColor        = vec3(1);
const float SunSize         = 0.01;
const float SunSharpness    = 1.1;

//Structures
struct Ray{
    vec3 Position;
    vec3 Direction;
};

//Fractal code
float Fractal(vec3 z){
    for(int n=0;n < Iterations;n++) {
       if(z.x+z.y<0.) z.xy = -z.yx;
       if(z.x+z.z<0.) z.xz = -z.zx;
       if(z.y+z.z<0.) z.zy = -z.yz;    
       z = z*2.-1.;
    }
    return (length(z)-Thickness) * pow(2., float(-Iterations)); 
}

//Raymarching
float getSceneDistance(vec3 pos){   
    return Fractal(pos);
}

//Normal Calculation
const vec3 deltax = vec3(Delta,0,0);
const vec3 deltay = vec3(0,Delta,0);
const vec3 deltaz = vec3(0,0,Delta);
vec3 getNormal(vec3 p){
    float d = getSceneDistance(p);
    return normalize(vec3(
        getSceneDistance(p+deltax)-d,
        getSceneDistance(p+deltay)-d,
        getSceneDistance(p+deltaz)-d
    ));
}

Ray RayMarch(Ray iRay){
    for (int i=0;i<MaxSteps;i++){
        float dis = getSceneDistance(iRay.Position);
        
        if(abs(dis)<Epsilon) break;
        if(dis>=MaxDistance) break;
        
        iRay.Position += iRay.Direction*dis;
    }
    return iRay;
}

vec3 getSkyColor(vec3 dir){
    return mix(
        SkyColor,
        SunColor,
        pow(SunSize/dot(dir-SunVector,dir-SunVector),SunSharpness)
    );  
}

vec3 getPixelRayColor(Ray iRay){
        
        iRay = RayMarch(iRay);

        float iRaySceneDistance = getSceneDistance(iRay.Position);

        if(iRaySceneDistance<Epsilon){
            vec3 Color = vec3(1);
            
            vec3 Normal = getNormal(iRay.Position);
            
            Ray ShadowRay = Ray(
                iRay.Position+Normal*BackStep,
                SunVector
            );
            ShadowRay = RayMarch(ShadowRay);       
            float ShadowRaySceneDistance = getSceneDistance(ShadowRay.Position);
            if(ShadowRaySceneDistance<MaxDistance){//Filthy trick but perfect shadows be aware
                Color *= .5;
            }
            
            float Diffuse = dot(Normal,SunVector)*.25+.75;
            
            float AmbientOcclusion = abs(getSceneDistance(iRay.Position+Normal*(Occlusion+Epsilon))/(Occlusion+Epsilon));
                  AmbientOcclusion = clamp(AmbientOcclusion,0.75,1.);
                
            return Color*Diffuse*AmbientOcclusion;
               
            
        }else{
            
             return getSkyColor(iRay.Direction); 
            
        }

}

void main(void) {
    vec2 ScaledPixelPos = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y/2.;

    //Camera
    float theta = (cos(time/3.)*.5+.7)*2.;
    float phi = time/2.;
    //if(mouse*resolution.xy.z>0.){
    //    theta           = mouse*resolution.xy.y/resolution.y*3.14;
    //    phi             = mouse*resolution.xy.x/resolution.x*6.28;
    //}
    vec3  CameraPosition  = normalize(vec3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi)))*4.;
    vec3  CameraLook      = vec3(0,0,0);
    vec3  CameraDirection = normalize(CameraLook-CameraPosition);
    vec3  CameraRight     = normalize(cross(vec3(0,1,0), CameraDirection));
    vec3  CameraUpward    = cross(CameraDirection, CameraRight);
    
    Ray PixelRay = Ray(
        CameraPosition,
        normalize(CameraDirection+CameraRight*ScaledPixelPos.x+CameraUpward*ScaledPixelPos.y)
       );

    glFragColor = vec4(getPixelRayColor(PixelRay),1.0);
}
