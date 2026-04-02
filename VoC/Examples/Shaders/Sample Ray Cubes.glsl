#version 420

// original https://www.shadertoy.com/view/fdtGW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 10.0
#define MAX_STEPS 20

#define TWOPI     6.283185307179586476925286766559
#define HALFPI     1.5707963267948966192313216916398
#define TORAD     0.01745329251994329576923690768489

///  3 out, 2 in...
vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float getDistanceBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

mat4 getRotationX(const float fRadians)
{
    mat4 m;
     float fC = cos(fRadians);
    float fS = sin(fRadians);
    m[0] = vec4(1.0f,    0.0f,    0.0f, 0.0f);
    m[1] = vec4(0.0f,    fC,        fS, 0.0f );
    m[2] = vec4(0.0f,    -fS,    fC, 0.0f);
    m[3] = vec4(0.0f,0.0f,0.0f,1.0f);
    return m;
}

mat4 getRotationY(const float fRadians)
{       
    mat4 m;
    float fC = cos(fRadians);
    float fS = sin(fRadians);
    m[0] = vec4(fC,    0.0f,    -fS, 0.0f );
    m[1] = vec4(0.0f,    1.0f,    0.0f, 0.0f );
    m[2] = vec4(fS,    0.0f,    fC, 0.0f);
    m[3] = vec4(0.0f,0.0f,0.0f,1.0f);
    return m;
}

mat4 getRotationZ(const float fRadians)
{
mat4 m;
    float fC = cos(fRadians);
    float fS = sin(fRadians);
    m[0] = vec4(fC,    fS,        0.0f, 0.0f);
    m[1] = vec4(-fS,    fC,        0.0f, 0.0f );
    m[2] = vec4(0.0f,    0.0f,    1.0f, 0.0f);
    m[3] = vec4(0.0f,0.0f,0.0f,1.0f);
    return m;
}

mat4 getBoxTransform( vec3 rot, vec3 loc )
{
    mat4 mx = getRotationX(rot.x);
    mat4 my = getRotationY(rot.y);
    mat4 mz = getRotationZ(rot.z);
    
    mat4 m = mx * my * mz;    
    m[3] = vec4( loc, 1.0 );
    
    return m;
}

#define NUM_BOXESX 5
#define NUM_BOXESY 4

float GetD( vec3 pos )
{
    float d = MAX_DIST;
    
    const float boxWiggleSpeed = 3.0;
    
    for( int boxIndexY = 0; boxIndexY < NUM_BOXESY; ++boxIndexY)
    {
        for( int boxIndexX = 0; boxIndexX < NUM_BOXESX; ++boxIndexX)
        {
            //get a rotation matrix for the box, transfom the position around the box

            vec3 boxRand = hash32( vec2(boxIndexX+1,boxIndexY+1) );
                
            vec3 vecRot = vec3(time*0.3) * vec3(1.0, 1.11321, 0.977874 ) + vec3(boxIndexX,boxIndexY,0) * vec3(0.44654,0.6212,0.511112);

            mat4 boxTransform = getBoxTransform( vecRot, vec3(0,0,0) );
            
            vec3 boxPos = vec3( vec4(pos + vec3(boxIndexX*2, boxIndexY*2, sin(boxWiggleSpeed*time*boxRand.x)*0.25) ,1) * boxTransform );
            
            vec3 boxScale = vec3( mix( 1.0, 1.33, sin(time*boxRand.y*0.9867133)*0.5+0.5));
            d = min( d, getDistanceBox( boxPos, boxScale ) - 0.0125);
        }
    }
    return d;
}

float DoRay( vec3 co, vec3 vd )
{
    vec3 p = co;
    float dc = 0.0;
        
    for( int i=0; i < MAX_STEPS; i++)
    {      
        float ds = GetD(p);
        //move up ray
        dc += ds;
        p += vd * ds;
        if( ds < 0.01 || dc > MAX_DIST )
        {         
            break;
        }        
    }
    
    return dc;
}

vec3 GetN( vec3 surf_pos )
{
    float ds = GetD( surf_pos );
    float du = GetD( surf_pos - vec3(0.01,0.00,0.00));  
    float dv = GetD( surf_pos - vec3(0.00,0.01,0.00));
    float dw = GetD( surf_pos - vec3(0.00,0.00,0.01));
    
    vec3 n = ds - vec3(du,dv,dw);
    return normalize(n);
}

vec3 Light( vec3 surf_pos, vec3 light_pos, vec3 world_normal, vec3 lightCol )
{
    vec3 surf_to_light = light_pos - surf_pos;
    float light_dist = length(surf_to_light);
    surf_to_light = normalize(surf_to_light);
    float I = max( 0.0, dot( world_normal , surf_to_light ));
    
    float Imag = max(1.0,1.0/(light_dist * light_dist));
            
    return lightCol * I * Imag;
}

vec3 LightShad( vec3 surf_pos, vec3 light_pos, vec3 world_normal, vec3 lightCol )
{
    vec3 surf_to_light = light_pos - surf_pos;
    float light_dist = length(surf_to_light);
    surf_to_light = normalize(surf_to_light);
    float I = max( 0.0, dot( world_normal , surf_to_light ));
    
    float Imag = max(1.0,1.0/(light_dist * light_dist));
    
    float shad_surf_dist = DoRay( surf_pos + (world_normal * 0.02), surf_to_light );    
    if( shad_surf_dist < MAX_DIST && shad_surf_dist < light_dist )
    {
        I = 0.03;
    }
        
    return lightCol * I * Imag;
}

vec3 Diff( vec3 p, vec3 n)
{
    vec3 col = vec3(0.0);//texture( iChannel0, vec2(p.xz) ).xyz;
    
    return col;
    
}

    
    
void main(void)
{
    vec3 ambientLight = vec3(0.05,0.05,0.1);
    vec3 lightCol = vec3(0.95,0.9,0.8);
    vec3 light_pos = vec3(-3,3,6);
    
    float specularPower = 120.0;
    vec3 specularCol = lightCol;
    
    vec3 cameraPos = vec3( 0.0, 0.0, 6.0 );
    vec3 cameraLookAt = vec3(0.0, 0.0, 0.0);
    vec3 cameraOffset = vec3(-4.0,-2.,0); //move the camera once rather than move every box

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-(0.5*resolution.xy))/resolution.y;
    
    float t = time;
    
    //Camera
    float scalex = 1.0;
    float scaley = 1.0;
 
    vec3 camz = normalize(cameraLookAt-cameraPos);
    vec3 sidex = normalize(cross( camz, vec3(0.0, 1.0, 0.0) ));
    vec3 up = normalize(cross( sidex, camz ));
    vec3 raydir = normalize( camz + (sidex * uv.x * scalex) + (up * uv.y * scaley) );
         
    cameraPos += cameraOffset;
     
    //Position
    float d = DoRay( cameraPos, raydir );
    vec3 surf_pos = cameraPos + (raydir * d);
      
    vec3 world_normal = GetN(surf_pos);
    
    
    vec3 col = vec3(0);
               
    //Light
    col += LightShad( surf_pos, light_pos, world_normal,  lightCol );
    
    //Ambient
    col += ambientLight;
               
    //specular
    {
        vec3 surf_to_light = light_pos - surf_pos;
        float light_dist = length(surf_to_light);
        surf_to_light = normalize(surf_to_light);
        float spec = 0.0;
        vec3 refl = reflect( -surf_to_light, world_normal );
        spec = max(0.0, dot( refl, -raydir ));
        col += vec3(pow( spec, specularPower )) * specularCol;
    }
 
     //depth visualize
      //col = vec3(d/MAX_DIST);
    
    //if the ray went past our max, just set to black, otherwise we can get some artefacts
    if(d >= MAX_DIST)
        col = vec3(0);
                    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
