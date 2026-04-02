#version 420

// original https://www.shadertoy.com/view/Dlf3DB

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Recursive Glass RT by Kastorp
//  tentative to implement glass raytracing recursion using stack 
// 
// the original version with macro is faster https://www.shadertoy.com/view/mtlGW7
// but this version allows double ray depth (and almost total reflection).
// Probably reusing stackdata output as input I could gain more fps 
//------------------
// Credits:
//   recursion logic from https://www.shadertoy.com/view/MsXyRM 
//   rendering from https://www.shadertoy.com/view/4s2Gz3
//   model from https://www.shadertoy.com/view/ltsfzN
//-------------------------------------

int SCENE= -1;  //0=DODECAHEDRON,1=ICOSAHEDRON,  2=TRUNCATED ICOSAHEDRON. -1=all
//#define BUMPY
#define AUTOCAM
#define SPIN
#define DEPTH 8 //ray depth  (try with 18 to simulate total internal reflections)

// rotate camera
#define PI 3.141592653
#ifdef AUTOCAM
#define anglex2 (sin(time*0.3)*0.4)
#define angley2 (time*0.2-0.4)
#else
 #define anglex2  (0.5 - mouse*resolution.xy.y/resolution.y)*PI*1.2
 #define angley2  -mouse*resolution.xy.x/resolution.x*PI*2.0
#endif

vec3 campos;
vec3 dir;
int side; // 1 for ray outside glass,  -1 for ray inside glass
float gTravel;
vec3 gNormal;
float travelMax,travelMin;
vec3 normalMax,normalMin;
 

//from https://www.shadertoy.com/view/4s2Gz3
vec3 sky()
{
    vec3 sunDir = normalize(vec3(0.0,0.3,1.0));
    float f = max(dir.y,0.0);
    vec3 color = 1.0-vec3(1,0.85,0.7)*f;
    color *= dir.z*0.2+0.8;    
    if (dot(sunDir,dir)>0.0)
    {
     f = max(length(cross(sunDir,dir))*10.0,1.0);        
     color += vec3(1,0.9,0.7)*40.0/(f*f*f*f);
    }
    return color;    
}

vec3 backGround()
{
    //return abs(dir)*2.-max(dir,vec3(0)).zxy +min(dir,vec3(0)).yzx;
     if (dir.y>=0.0) return sky();
     vec3 raypos2 = campos - dir*(campos.y / dir.y);
    float fog = exp(length(raypos2)/-8.0);
     return sky()*(1.0-fog);// +texture(iChannel0,raypos2.xz*1.).rgb *fog;
}

vec3 rotatex(vec3 v,float anglex)
{
    float t;
    t =   v.y*cos(anglex) - v.z*sin(anglex);
    v.z = v.z*cos(anglex) + v.y*sin(anglex);
    v.y = t;
    return v;
}

vec3 rotcam(vec3 v)
{
    float t;
    v = rotatex(v,anglex2);
    
    t = v.x * cos(angley2) - v.z*sin(angley2);
    v.z = v.z*cos(angley2) + v.x*sin(angley2);
    v.x = t;
    return v;
}

//from https://www.shadertoy.com/view/4s2Gz3
// a ray hits a surface surfaceside shows weather it hit from the rear or front of the plane 
void update(float surfaceside,float travel,vec3 normal)
{
    if (surfaceside<0.0)
    {
        if (travelMax<travel)
        {
            travelMax = travel;
            normalMax = normal;
        }
    }
    else
    {
        if (travelMin>travel)
        {
            travelMin = travel;
            normalMin = normal;
        }
    }
}

//from https://www.shadertoy.com/view/4s2Gz3
void hitPlane(vec3 normal,float shift) // check ray-plane intersection. Planes are infinte large
{
#ifdef SPIN
    float angle = fract(time*0.25);
    angle = min(angle*1.5,1.0);
    
    normal = rotatex(normal,angle*PI*2.0);        // rotate object
#endif
    shift += normal.y*1.0;         // and shift up from the ground height
    
    float distFromPlane = dot(normal,campos) - shift;
    float travel = -distFromPlane / dot(normal,dir);
    update(dot(normal,dir),travel,normal);
}

//from https://www.shadertoy.com/view/4s2Gz3
void startObj()
{
    travelMax = -1e35;
    travelMin = 1e35;
}

//from https://www.shadertoy.com/view/4s2Gz3
void endObj()
{
//    if (travelMax<travelMin)     // enable this for nonconvex objects
    {
        if (side>0)
        {
            if (travelMax<travelMin && travelMax>0.0 && travelMax<gTravel)
            {
                gTravel = travelMax;
                gNormal = normalMax;
            }
        }
        else
        {
            if (travelMin>0.0 && travelMin<gTravel)
            {
                gTravel = travelMin;
                gNormal = -normalMin;
            }
        }
    }
}

//from https://www.shadertoy.com/view/4s2Gz3
vec3 glassColorFunc(float dist) // exponentially turn light green as it travels within glass (real glass has this prorperty)
{
    if(side>0) return vec3(1,1,1);
    //dist*=2.;
    return vec3(exp(dist*-0.4),exp(dist*-0.05),exp(dist*-0.2));
}

//https://www.shadertoy.com/view/ltsfzN
// i=0..11 dodecahedron normals
//   divided into 6 pairs: 0-3, 1-2, 4-7, 5-6, 9-10, 8-11
// i=12..32 icosahedron normals
//  divided into 5 tetrahedra groups: 12-17-23-29, 13-19-20-27, 14-18-22-24, 15-16-21-30, 25-26-28-31
vec3 getNormal(int i) {
    int block = i / 4;
    vec3 signs = sign(vec3(i & ivec3(4, 2, 1)) - 0.1);
    
    if (block > 5) return 0.5774 * signs;
    
    vec3 r = signs * (block < 3 ? vec3(0.0, 0.5257, 0.8507) : vec3(0.0, 0.9342, 0.3568));
    return vec3(r[block % 3], r[(block + 2) % 3], r[(block + 1) % 3]);    
}      

void hitObject() // trace the mesh
{
    startObj();
    if(SCENE<0) SCENE=int(time/5.)%3;
    int i1=0,i2=12; //dodecahedron as twelve planes intersection
    if(SCENE>=1) i2=32;
    if(SCENE==1) i1=12;    
    for(int i=min(frames,i1);i<i2;i++) hitPlane(getNormal(i),.7*(i < 12 ? 1.0 : 0.975));
    endObj();    
}

vec3 glassBG() //necessary if DEPTH<18 
{
   // return vec3(10,0,0); 
    return vec3(.3,.8,.7);
}

void bumpit()
{
#ifdef BUMPY
    gNormal.x += sin(campos.x*30.0)*0.007;
    gNormal.y += sin(campos.y*30.0)*0.007;
    gNormal.z += sin(campos.z*30.0)*0.007;
    gNormal = normalize(gNormal);
#endif
}

vec3 trace() // recursive RayTracing - optimized version
{    
    #define ITERS (DEPTH*4) //max number of stack operations
     
    int cycle=0; //cycle counter; each ray has 4 cycles

    struct ray{ 
        int i,    // ray depth
            t,    // type: 1=object 2:exterior
            p;    // recursion completion 0=no ray, 1=refraction ray, 2=both
        float fr, // fresnel 
              gT; // glass travel
        vec3 s,   // light sum
             oP,  // hit position
             rD;  // reflect dir
    }; 
      
    ray stack[DEPTH];  
    const int CALL=1, RETURN=0; 
    
    //initialization
    int z=0;        //current depth
    int mode=CALL;    //call mode     
    stack[0] = ray(1,1,0,0.,0.,vec3(0),vec3(0),vec3(0));  //initial ray
     
    do {    
       if (mode==CALL) { 
           int zn=z+1;         
           if (!(length(dir)<1.01) || !(length(dir)>0.99)) {stack[z].s=vec3(0);mode = RETURN; }          
           if(stack[z].t!=1) {stack[z].s=backGround(); mode = RETURN; }
           else if(stack[z].i>=DEPTH) {stack[z].s=glassBG(); mode = RETURN; }
           else {
                gTravel=1e35;
                hitObject(); 
                if (gTravel>1e34) {stack[z].t=2; stack[z].s=backGround();mode = RETURN; }
                else{
                    campos += dir * gTravel;
                    bumpit();                  
                    stack[z].gT = (gTravel);                    
                    stack[z].oP = campos;                    
                    stack[z].rD=reflect(dir,gNormal);
                    dir = refract(dir,gNormal,side>0 ? 1.0/1.52 : 1.52); 
                    float t = clamp(1.0+dot(gNormal,side>0?-stack[z].rD : dir),0.0,1.0);    
                    stack[z].fr = 0.1 + (t*t*t*t*t)*0.9;                    
                    side *=-1;                                                   
                    stack[zn].i=stack[z].i+1;
                    stack[zn].t=stack[z].i<=1?1:2; //refraction is internal on first ray, and otherwise external
                    stack[zn].s=vec3(0.);
                    stack[zn].p=0;
                    z=zn;                   
                }
           }
       } else { //mode == RETURN
            int zp=z-1;
            if (z<=1) return stack[z].s;
            else if(stack[zp].t!=1 ){               
                stack[zp].s +=stack[z].s; 
                z=zp;
            }
            else if(stack[zp].p==0 ){ 
                stack[zp].p++; 
                stack[zp].s+=stack[z].s*(1.0-stack[zp].fr); 
                side *=-1;
                campos = stack[zp].oP;  
                dir = stack[zp].rD;                 
                stack[z].s = vec3(0);
                stack[z].t=stack[zp].i<=1?2:1;//reflection is external on first ray, and otherwise internal
                stack[z].p=0;
                mode = CALL;                
            }
            else if(stack[zp].p>=1 ){ 
                stack[zp].p++; 
                stack[zp].s+=stack[z].s*stack[zp].fr;
                stack[zp].s*=glassColorFunc(stack[zp].gT);
                z=zp;                
            }
         }
    } while(cycle++<ITERS ); 

    return vec3(-1.);        
}

#define R resolution.xy
void main(void)
{    
    campos = vec3(0,1.0,0)-rotcam(vec3(0,0,2));
    dir = normalize(rotcam(vec3((gl_FragCoord.xy -R*.5)/R.y,1)));
    side = 1;    
    glFragColor = vec4((trace()*min(time/5.0,1.0)),1.0); 
}
