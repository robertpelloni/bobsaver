#version 420

// original https://www.shadertoy.com/view/WdVSzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "ShaderToy Tutorial - Ray Marching Primitives" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This shader is part of a tutorial on YouTube
// https://youtu.be/Ff0jJyyiVyw

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

//Torus function
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

//Sphere function
float sdSphere( vec3 p, float s1 )
{
   vec4 s = vec4(0, s1, 9, s1);
   return  length(p-s.xyz)-s.w;   
}
//Box function
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}
//Triprism function
float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}
//Cone function
float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

///-----------------------------------------

// Distance Functions
//float sdBox( vec3 p, vec3 b ) {
//    vec3 d = abs(p) - b;
//    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
//}

float dSphere(vec3 p, float r) {
    return length(p) - r;
}

float dSphereCenter(vec3 p) {
    return dSphere(p - vec3(0.0, 1.0, -0.5), 1.0);
}

float dSphereLeft(vec3 p) {
    return dSphere(p - vec3(2.5, 1.0, 0.0), 1.0);
}

float dBar(vec2 p, float width) {
    vec2 d = abs(p) - width;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) + 0.01 * width;
}

float dCrossBar(vec3 p, float x) {
    float bar_x = dBar(p.yz, x);
    float bar_y = dBar(p.zx, x);
    float bar_z = dBar(p.xy, x);
    return min(bar_z, min(bar_x, bar_y));
}

float dMengerSponge(vec3 p) 
{
    float d = sdBox(p, vec3(1.0));
    //float d = sdSphere (p-vec3(0.0), 3.0);
    
    float one_third = 1.0 / 3.0;
    for (float i = 0.0; i < 4.0; i++) {
        float k = pow(one_third, i);
        float kh = k * 0.5;
        d = max(d, -dCrossBar(mod(p + kh, k * 2.0) - kh, k * one_third));
    }
    return d;
}

float dMengerSpongeRight(vec3 p) {
    //return dMengerSponge(p - vec3(-2.5, 1.0, 0.0));
    return dMengerSponge(p - vec3(-1.0, 1.0, 0.0));
}

///--------------------------------------------

//Coordinate positioning of each shape
float GetDist(vec3 p) {    

     
    float planeDist = p.y;
    float dm1, dm2,dm3,dm4;
    float d;
    
    d=1000.0;
    d=min(d,planeDist);
    //d = min(d, sp ); 
    
    
    
    dm1=dMengerSponge(p-vec3(0.,2.0,-1.0));
    dm2=dMengerSponge(p-vec3(0.,2.0,3.0));
    dm3=dMengerSponge(p-vec3(0.,2.0,6.0));
    dm4=dMengerSponge(p-vec3(0.,2.0,15.0));
    
    d=min(d, dm1);
    d=min(d, dm2);
    d=min(d, dm3);
    d=min(d, dm4);
    
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.2;
    //Determines size of shadow
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    //Texture of white and black in image
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0, 5, 6);
    //Determine movement of light ex. shadow and light direction and diffusion
    lightPos.xz += vec2(sin(time), cos(time)*2.);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d<length(lightPos-p)) dif *= .1;
    
    return dif;
}

float GetLightPos(vec3 p, vec3 lpos) {
    
    vec3 lightPos1 = vec3(0, 5, 6);
    //Determine movement of light ex. shadow and light direction and diffusion
    lightPos1.xz += vec2(sin(time), cos(time)*2.);
    vec3 l1 = normalize(lightPos1-p);
    vec3 n1 = GetNormal(p);
    
    float dif1 = clamp(dot(n1, l1), 0., 1.);
    float d1 = RayMarch(p+n1*SURF_DIST*2., l1);
    if(d1<length(lightPos1-p)) dif1 *= .1;
    
    
    vec3 lightPos2 =lpos;
    //Determine movement of light ex. shadow and light direction and diffusion
    lightPos2.xz += vec2(0.0, cos(time)*2.);
    vec3 l2 = normalize(lightPos2-p);
    vec3 n2 = GetNormal(p);
    
    float dif2 = clamp(dot(n2, l2), 0., 1.);
    float d2 = RayMarch(p+n2*SURF_DIST*2., l2);
    if(d2<length(lightPos2-p)) dif2 *= .1;
    
    return (dif1+dif2)/2.0;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    //Color of each object
    //vec3 ro = vec3(0, 2, 0);
    
    vec3 ro = vec3(0, 2, 5.1+10.0*sin(time*0.5));
    vec3 rd = normalize(vec3(uv.x-.15, uv.y-.2, 1));

    float d = RayMarch(ro, rd);
    
    vec3 p = (ro + rd * d );
    
    
    float dif = GetLightPos(p, ro);
    col = vec3(dif);
    
    
    glFragColor = vec4(col,1.0);
    //Background color is white
}
