#version 420

// original https://www.shadertoy.com/view/wtGGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

//SETTINGS:
#define VIEW_DIST 65.0
#define ITERATIONS 7
#define AA_SCALE 2.0

struct Object
{
     float dist;
    float difVal;
    float specVal;
    float specKs;
    float normEps;
    
    vec3 color;
    vec3 normal;
};

struct MarchRes
{
     float totalDist;
    float minDist;

    vec3 curRay;
    Object obj;
};
    
struct Light
{
    float intensity;
    vec3 color;
    vec3 pos;  
};

//Credits to knighty for discovering this!
Object map(vec3 p)
{
    Object o;
    o.color = vec3(0);
    o.difVal = 1.0;
    o.specVal = 50.0;
    o.specKs = 0.01;
    
    o.dist = 1000.0;
    o.normEps = 0.001;
    
    float it;
    float len;
    
    float minD = 1000.0;
    vec3 minXYZ = vec3(minD);
    float angBox = 0.0;
    
    vec3 Offset = vec3(0,0,-0.1);
    
    
    p.yz = mat2(cos(PI/2.0), -sin(PI/2.0), sin(PI/2.0), cos(PI/2.0))*p.yz;
    p.y = -1.+mod(p.y, 4.0);
    p.x = -3.0 + mod(p.x, 13.5);

    vec3 or = p;
    vec3 ap = p + 1.0;
    vec3 CSize = vec3(1.,1,1.3);
    //vec3 CSize = vec3(4.4,2.0,0.5);
    //vec3 CSize = vec3(2.0,1.0,0.3);
    float Size = 1.;
    float DEoffset = 0.;
    float DEfactor = 1.5;
    vec3 C = vec3(-0.62,-0.015,-0.025);
    //vec3 C = vec3(-0.8,0.1,0.2);
    //vec3 C = vec3(-0.04,0.14,-0.5);
    vec4 orbitTrap = vec4(1000);
    
    for(int i=0; i < ITERATIONS; i++){
        if(ap == p) break;
        ap=p;
        p=2.*clamp(p, -CSize, CSize)-p;
      
        float r2=dot(p,p);
        orbitTrap = min(orbitTrap, abs(vec4(p,r2)));
        float k=max(Size/r2,1.);
        p*=k;DEfactor*=k;
      
        p+=C;
        orbitTrap = min(orbitTrap, abs(vec4(p,dot(p,p))));
        minD = min(minD, length(p-or));
        minXYZ = min(minXYZ, abs(p - or));
    }
    
    float dist = abs(0.5*abs(p.z-Offset.z)/DEfactor-DEoffset);

    if(dist < o.dist){
        o.dist = dist;
        o.specVal = 10.0;
        o.specKs = 0.5;
        //o.color = vec3(.1, .533, .631)*orbitTrap.x + vec3(0.0,0.3,0)*orbitTrap.w;// + vec3(0.3)*minXYZ.y;
        o.color = vec3(.718, .533, .431)*orbitTrap.x + vec3(0.2,0.1,0)*orbitTrap.w;// + vec3(0.3)*minXYZ.y;
        //o.color = mix(vec3(0.6, 0.4, 0.2), vec3(0.1)*0.4, fbm(pos*500.0));
    }    
    return o;
}

vec3 calcNormal(vec3 pos, float ep)
{
    return normalize(vec3(map(pos + vec3(ep, 0, 0)).dist - map(pos - vec3(ep, 0, 0)).dist,
                        map(pos + vec3(0, ep, 0)).dist - map(pos - vec3(0, ep, 0)).dist,
                        map(pos + vec3(0, 0, ep)).dist - map(pos - vec3(0, 0, ep)).dist));                                
}

//iq
vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayDir,   // camera to point vector
               in vec3  sunDir )  // sun light direction
{
    float fogAmount = 1.05 - exp( -distance*0.15 );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( vec3(0.5,0.6,0.7), // bluish
                           vec3(0.5,0.6,0.7), 
                           pow(sunAmount,8.0) );
    return mix( rgb, fogColor, fogAmount );
}
    
MarchRes marchRay(vec3 pos, vec3 dir, float speed)
{
     MarchRes res;
    Object o;
    
    res.totalDist = 0.001;
    res.minDist = 1000.0;

    for(int x=0; x<250; x++)
    {
         res.curRay = pos + (dir*res.totalDist);
        
        o = map(res.curRay);
        
        if(abs(o.dist) < 0.001)
        {
            res.obj = o;
            break;
        }
        else if(res.totalDist >= VIEW_DIST) break;
           
        
        if(o.dist < res.minDist) res.minDist = o.dist;
        res.totalDist += o.dist*speed;
    }
    
    if(res.totalDist < VIEW_DIST)
    {
        o.normal = calcNormal(res.curRay, o.normEps);
        
        res.obj = o;
    }
        
    
    return res;
}

vec3 calcDiffuseLight(Object o, Light l, vec3 pos)
{
    vec3 dir = normalize(l.pos - pos);
    float val = clamp(dot(o.normal, dir), 0.0, 30.0);
    float oVal = val;

    vec3 col = (o.color) * l.intensity * l.color * val * o.difVal;   
    return col;
}

vec3 calcSpecLight(Object o, Light l, vec3 pos, vec3 camPos)
{
     vec3 dir = normalize(l.pos - pos);  
    vec3 viewDir = normalize(camPos - pos);
    vec3 specR = 2.0*clamp( dot(o.normal, dir), 0.0, 1.0) * o.normal - dir;
    float spec = clamp( dot(viewDir, specR), 0.0, 1.0);

    vec3 col = o.specKs*l.intensity*(l.color*pow(spec, o.specVal));
    return col;
}

void main(void)
{
    float done;
    vec3 col;
    
    for(float x=0.0; x<AA_SCALE; x++){
    for(float y=0.0; y<AA_SCALE; y++){
        
    vec2 aaOffset = vec2(x,y);
    vec2 uv = (2.0*(gl_FragCoord.xy+aaOffset/AA_SCALE) - resolution.xy)/resolution.y;
    vec3 camEye = vec3(4.0,-5.0,2.0-0.6*time);
    vec3 dir = normalize(vec3(uv, -1));
    

    float rate = 8.0;
    float camAng = PI/5.0;
    float camAngPos = camAng;
    float camAngX = mouse.y*resolution.xy.y/20.0;
    
    mat2 rotCam = mat2( vec2(cos(camAng), -sin(camAng)), vec2(sin(camAng), cos(camAng)) );
    dir.xz = rotCam * dir.xz;
    
    Light light;
    light.intensity = 2.0;
    light.pos = vec3(22, -0.3, 50);
    light.color = vec3(1);    
   
    
    Light lightSky;
    lightSky.intensity = 3.1;
    lightSky.pos = vec3(0, 3, 0);
    lightSky.color = vec3(0.1, 0.1, 0.2);
    
    MarchRes res = marchRay(camEye, dir, 1.0);
    vec3 pos = res.curRay;  
    
    vec3 tempCol = vec3(0);
    if(res.totalDist < VIEW_DIST)
    {
        tempCol = res.obj.color;
        tempCol = calcDiffuseLight(res.obj, light, pos);
        tempCol += calcSpecLight(res.obj, light, pos, camEye);
    }else{
        tempCol = applyFog(4.0*tempCol, res.totalDist, pos, light.pos);
        col += tempCol;
        done = 1.0;
         break;   
    }
    tempCol = applyFog(tempCol, res.totalDist, pos, light.pos);
    col += tempCol;

    }
        if(done > 0.0)
            break;
    }
    
    glFragColor = vec4(col/(AA_SCALE*AA_SCALE),1.0);
}
