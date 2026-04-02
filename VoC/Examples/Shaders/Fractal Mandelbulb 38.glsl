#version 420

// original https://www.shadertoy.com/view/tlVGzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define ITERATIONS 2.0
#define AA_SCALE 1.0

//SETTINGS:
#define VIEW_DIST 2.0

//RESOURCES:
//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
//https://www.iquilezles.org/www/articles/mandelbulb/mandelbulb.htm
//https://www.iquilezles.org/www/articles/ftrapsgeometric/ftrapsgeometric.htm

struct Object
{
     float dist;
    float difVal;
    float specVal;
    float specKs;
    float id;
    
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
    
//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
Object map(vec3 pos)
{
    Object o;
    o.difVal = 1.0;
    o.specVal = 50.0;
    o.specKs = 0.01;    
    o.dist = 1000.0;
    
    float ang = time/8.0;
    float dz = 1.0;
    float r;
    
    pos.xz *= mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
    vec3 z = pos;
    float power = 10.0+4.0*cos(time/8.0);
    float it;
    float minDist = 1000.0;
    float mdX, mdY, mdZ;
    mdX = minDist; mdY = minDist; mdZ = minDist;
    
    for(float x=0.0; x < 4.0; x++)
    {
        vec3 cartPos;
        r = length(z);
        float ang = acos(z.y / r);
        float ang1 = atan(z.x, z.z);
        
        dz = power*pow(r, power-1.0)*dz + 1.0;     
        r = pow(r, power);      
        ang *= power;
        ang1 *= power;
        
        cartPos.x = sin(ang)*sin(ang1);
        cartPos.y = cos(ang);
        cartPos.z = sin(ang)*cos(ang1);
        
        z = pos + (r * cartPos);    
        minDist = min(minDist, length(z - pos)); //store minimum distance from starting point
        mdX = min(mdX, abs(z.x));
        mdY = min(mdY, abs(z.y));
        mdZ = min(mdZ, abs(z.z));

        if(length(z) > 2.0) { it = x; break; }
    }

    //Coloring based off orbits: https://www.iquilezles.org/www/articles/ftrapsgeometric/ftrapsgeometric.htm
    o.color = vec3(0) + vec3(0.55, 0.9, 1.0)*sqrt(minDist);
    o.color += vec3(0.3,0.3,0)*sqrt(mdX);
    o.color += vec3(0.0,0.2,0)*sqrt(mdY);
    o.color += vec3(0.0,0.1,0.2)*sqrt(mdZ);
    
    o.dist = 0.5*length(z)*log(length(z)) / length(dz);
    
    return o;
}
  
MarchRes marchRay(vec3 pos, vec3 dir, float speed)
{
     MarchRes res;
    Object o;
    
    res.totalDist = 0.001;
    res.minDist = 1000.0;

    for(int x=0; x<100; x++)
    {
         res.curRay = pos + (dir*res.totalDist);
        
        o = map(res.curRay);
        
        if(abs(o.dist) < 0.00001)
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
        res.obj = o;
    }
        
    
    return res;
}

void main(void)
{
    float done;
    vec3 col;
    
    //AA based off IQ's implementation in many different shaders
    for(float x=0.0; x<AA_SCALE; x++){
    for(float y=0.0; y<AA_SCALE; y++){
        
    vec2 aaOffset = vec2(x,y);
    vec2 uv = (2.0*(gl_FragCoord.xy+aaOffset/AA_SCALE) - resolution.xy)/resolution.y;
    vec3 camEye = vec3(0,0.0,1.2);
    vec3 dir = normalize(vec3(uv, -1));
    

    float rate = 8.0;
    float camAng = PI/3.5;
    float camAngPos = camAng;

    mat2 rotCam = mat2( vec2(cos(camAng), -sin(camAng)), vec2(sin(camAng), cos(camAng)) );
    mat2 rotCamPos = mat2( vec2(cos(camAngPos), -sin(camAngPos)), vec2(sin(camAngPos), cos(camAngPos)) );

    camEye.xz = rotCamPos * camEye.xz;
    dir.xz = rotCam * dir.xz;
    
    MarchRes res = marchRay(camEye, dir, 1.0);
    vec3 pos = res.curRay;  
    
    vec3 tempCol = vec3(0);
    if(res.totalDist < VIEW_DIST)
    {
        tempCol = res.obj.color;
    }else{
        //no object, no need to run AA
        done = 1.0;
         break;   
    }
    col += tempCol;

    }
        if(done > 0.0)
            break;
    }
    
    glFragColor = vec4(col/(AA_SCALE*AA_SCALE),1.0);
}
