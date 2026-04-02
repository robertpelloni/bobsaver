#version 420

// original https://www.shadertoy.com/view/WsjcWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "ShaderToy Tutorial - Ray Marching for Dummies!" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This shader is part of a tutorial on YouTube
// https://youtu.be/PGtv-dBi2wE

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01
#define MAXITE 32.0

mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }

float rnd(vec2 n){
  return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float mandel(vec2 p)
{    
    float zre=0.; //sin(time)/4.0;
    float zim=0.; //cos(time)/3.0;
    float cre=p.x;
    float cim=p.y;
    float col=0.;

    for(float i=0.;i<MAXITE;i++)
    {
        float dam=zre*zre-zim*zim+cre;
        zim=2.0*zre*zim+cim;
        zre=dam;
        col++;
        if( (zre*zre+zim*zim)>4.0 )
            break;
    }
    
    return (col/MAXITE);
}

float GetDist(vec3 p) {
    float v=mandel(p.xz/6.0);
    vec4 s1 = vec4(p.x,-v,p.z,0.5);
  
    float sphereDist1 =  length(p-s1.xyz)-s1.w;
    float planeDist = p.y;
    
    float d = min(sphereDist1, planeDist);
    return d;    
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
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
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0, 6, 2);
    //lightPos.xz += vec2(sin(time), cos(time))*2.;
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
   // float d = RayMarch(p+n*SURF_DIST*2., l);
    //if(d<length(lightPos-p)) dif *= .1;
    
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    
    vec3 ro = vec3(-2., 6, -7.5);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));

    ro = ro*(rotx(-0.4));
    ro.x=-2.0+4.0*cos(time/2.0);
    ro.z=-7.0+5.0*sin(time/1.5);
    float d = RayMarch(ro, rd);

    vec3 p = ro + rd * d;

    float dif = GetLight(p);
    col = vec3(dif);
    
    glFragColor = vec4(col,1.0);
}
