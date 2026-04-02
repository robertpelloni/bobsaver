#version 420

// original https://www.shadertoy.com/view/WtV3Rw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define ITERATIONS 2.0
#define AA_SCALE 2.0

//SETTINGS:
#define VIEW_DIST 25.0
#define C vec4(0.2,0.5,0.3,0.3)
//#define C vec4(0.8,0.-0.1,0.9,0.9)

//RESOURCES:
//https://www.cs.cmu.edu/~kmcrane/Projects/QuaternionJulia/paper.pdf

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
vec4 multQuat(vec4 q1, vec4 q2)
{
    vec4 r;
    r.x   = q1.x*q2.x - dot( q1.yzw, q2.yzw );
    r.yzw = q1.x*q2.yzw + q2.x*q1.yzw + cross( q1.yzw, q2.yzw );
    return r;
}

//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
vec4 squareQuat(vec4 q)
{
     vec4 r;
    r.x   = q.x*q.x - dot( q.yzw, q.yzw );
    r.yzw = 2.0*q.x*q.yzw;
    return r;  
}
    
//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
Object map(vec3 pos)
{
    Object o;
    o.difVal = 1.0;
    o.specVal = 50.0;
    o.specKs = 0.01;    
    o.dist = 1000.0;
    
    float ang = time/8.0;
    float r;
    
    pos.xz *= mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
    
    vec4 z = vec4(pos, 0.1);
    vec4 dz = vec4(1, 0, 0, 0);

    float it;
    float minDist = 1000.0;
    float mdX, mdY, mdZ;
    mdX = minDist; mdY = minDist; mdZ = minDist;
    
    vec4 c = C;
    c.w += 0.5*sin(time*2.0);
        
    
    for(float x=0.0; x < 20.0; x++)
    {
        dz = 2.0*multQuat(z,dz);
        z = squareQuat(z) + c;
        
        minDist = min(minDist, length(z - c)); //store minimum distance from starting point
        mdX = min(mdX, abs(z.x));
        mdY = min(mdY, abs(z.y));
        mdZ = min(mdZ, abs(z.z));
        
        if(length(z) > 2.0)
        {
            it = x;
            break;
        }
    }

    //Coloring based off orbits: https://www.iquilezles.org/www/articles/ftrapsgeometric/ftrapsgeometric.htm
    o.color = vec3(0) + vec3(1.0, 0.3, 0.55)*sqrt(minDist);
    o.color += vec3(0.0,0.3,0.3)*sqrt(mdX);
    o.color += vec3(0.0,0.4,0)*sqrt(mdY);
    o.color += vec3(0.0,0.1,0.5)*sqrt(mdZ);
    
    //o.color = vec3(1)-vec3(it/20.0);
    o.dist = 0.5*length(z)*log(length(z)) / length(dz);
    
    return o;
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
            vec3 camEye = vec3(0,0.0,2.2);
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

            vec3 tempCol = vec3(0.25);
            if(res.totalDist < VIEW_DIST)
            {
                tempCol = res.obj.color;
            }

            col += tempCol;

        }
    }
    
    glFragColor = vec4(col/((AA_SCALE*AA_SCALE)),1.0);
}
