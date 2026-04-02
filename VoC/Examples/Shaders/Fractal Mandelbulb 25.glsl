#version 420

// original https://www.shadertoy.com/view/3tXXzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Pi 3.14159265359
#define ViewStart 1.6
#define ViewEnd 4.4

#define HQ

#ifdef HQ
int CameraRaySteps = 255;
int ShadowRaySteps = 64;
float MaxTransparency = .95;
#else
int CameraRaySteps = 128;
int ShadowRaySteps = 32;
float MaxTransparency = .7;
#endif

vec3 DirCam = normalize(vec3(-1, 0, 0));
vec3 PosCam = vec3(3.0, 0, .0);
float FocalLength = 1.0;

vec3 LightColor = vec3(1.5);
vec3 LightPos;

float Density = 25.0;
float Anisotropy = .2;
vec3 VolumeColor = vec3(.1, .15, .2);

float Power;

vec3 powV(vec3 v, float p){
    return vec3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
}

float maxV(vec3 v){
    return max(max(v.x, v.y), v.z);
}

bool insideShape(vec3 pos) {
    vec3 z = pos;
    float r;
    float zr;
    float sinTheta;
    float phi;
    float theta;
    for(int i = 0; i < 4; i++) {
        r = length(z);
        if(r>1.3) break;
        theta = acos(z.z/r)*Power;
        phi = atan(z.y,z.x)*Power;
        sinTheta = sin(theta);
        z = pow(r,Power)*vec3(sinTheta*vec2(cos(phi), sin(phi)), cos(theta)) + pos;
    }
    return r < 1.0 && r > .65;
}

float henyeyGreenstein(vec3 pos, vec3 dir){
    float cosTheta = dot(dir, normalize(LightPos-pos));
     return Pi/4.0 * (1.0-Anisotropy*Anisotropy) / pow(1.0 + Anisotropy*Anisotropy - 2.0*Anisotropy*cosTheta, 3.0/2.0);
}

vec3 lightReceived(vec3 pos){
    
    float LightDist = length(LightPos-pos);
    vec3 LightDir = normalize(LightPos-pos);
    
    float stepSize = LightDist / float(ShadowRaySteps);
    vec3 absorption = vec3(1.0);
    
    for(int i = 0; i < ShadowRaySteps; i++){
        if(insideShape(pos)){
            absorption *= powV(vec3(1)-VolumeColor, stepSize*Density);
        }
        pos += LightDir * stepSize;
    }
    return absorption*LightColor / (LightDist*LightDist);
}

vec3 rayColor(vec3 pos, vec3 dir){
    float hg = henyeyGreenstein(pos, dir);
    vec3 color;
    
    float stepSize = (ViewEnd-ViewStart) / float(CameraRaySteps);
    vec3 absorption = vec3(1.0);
    
    for(int i = 0; i < CameraRaySteps; i++){
        if(length(LightPos-pos) <.05) return 200.0*absorption*LightColor + color;
        if(insideShape(pos)){
            color += VolumeColor*absorption*lightReceived(pos)*hg*stepSize*Density;
            absorption *= powV(vec3(1)-VolumeColor, stepSize*Density*hg);
        }
        pos += dir * stepSize;
        if(maxV(absorption) < 1.0-MaxTransparency) break;
    }
    return color;
}

vec4 projectRay(vec2 posOnScreen){
    
    vec3 camX = vec3(-DirCam.y, DirCam.x, 0);
    vec3 camY = cross(camX, DirCam);
    vec3 sensorX = camX * (posOnScreen.x/length(camX));
    vec3 sensorY = camY * (posOnScreen.y/length(camY));
    vec3 centerSensor = PosCam - DirCam * FocalLength;
    vec3 posOnSensor = centerSensor + sensorX + sensorY;
    vec3 newDir = normalize(PosCam - posOnSensor);
    
    vec3 color = rayColor(PosCam + newDir*ViewStart, newDir);
    return vec4(log(color + vec3(1.0)), 1.0);    //reduces clipping and desaturates bright colors
}

vec3 rotateZ(vec3 p, float angle){
    return vec3(cos(angle) * p.x + sin(angle) * p.y,
                -sin(angle) * p.x + cos(angle) * p.y,
                p.z);
}

void main(void) {
    
    //quick animation ...
    DirCam = rotateZ(DirCam, -time/3.0);
    PosCam = rotateZ(PosCam, -time/3.0);
    Power = abs(cos(time/5.0)) * 7.0 + 1.0;
    LightPos = vec3(cos(time/2.0), -sin(time/2.0), cos(time/1.0)) * 1.25;
    
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.0)/resolution.y;
    glFragColor = projectRay(uv);
}
