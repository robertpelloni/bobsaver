#version 420

// original https://www.shadertoy.com/view/ll3fWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FAR 60.0
#define DISTANCE_BIAS 0.75

// This is an experiment with the FBM function and raymarching. 
//It's pretty slow so you might need a good machine, but I was pleased with the outcome. 
//The smoke effect was totally unexpected. Without the FBM, its just a simple glow. 

//Use the mouse to change its shape!

// 10 being highest quallity, 4 or 5 lowest.
// not sure how big of difference it makes in preformance
#define QUALITY 8

const float pi = 3.14159265359;

float sdPlane( vec3 p )
{
    return p.y;
}
vec2 mouse2()
{
    vec2 m = mouse*resolution.xy.xy / resolution.xy-.5; 
    m.x *= resolution.x/resolution.y;
    return m;
}

// rand, noise and fbm found various places on shadertoy
float rand(vec2 n){ 
    return fract(sin(dot(n, vec2(17.12037, 5.71713))) * 12345.6789);
}

float noise(vec2 n){
    vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b + d.xx), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 n){
    float sum = 0.0, amp = 1.0;
   
    for (int i = 0; i < QUALITY; i++)
    {
         //n.x -= mouse().x*2.0; // really fun to turn on
         n.x -= time*0.09 + 5.0; // "moving" the mountain
        sum += noise(n) * amp;
        n += n;
        amp *= 0.5;
       
    }
    return sum;
}

// the scene
float map(vec3 rp)
{
 
   float res;
    
   vec3 pos = rp - vec3(0.0, -1.0, 0.0);
  
   pos.y +=cos(pos.x*1.0 + time*0.5)*0.1; // lil extra movement 
   
    
   // just a simple raymarched plane being modulated by the fbm function.
   pos.y += cos(pos.x*1.0) * fbm(vec2(pos))* (mouse2().x);
   pos.y -= cos(pos.z*0.3) * fbm(vec2(pos)) * 0.7;
   
  
   res = pos.y ;
  
   return res;
}

vec3 getNormal(vec3 p)
{
    vec2 e = vec2(0.0035, -0.0035); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

vec3 col(vec3 ro, vec3 rd, vec3 norm, float md, float t)
{
    // Lighting... I know I'm using the lights wrong but its working for now
    vec3 ld = ro + vec3(-1.0, 1.0, 1.0); // light Direction
    float lDist = max(length(ld), 0.001); // Light to surface distance.
    float atten = 1.0 / (1.0 + lDist*0.2 + lDist*lDist*0.1); // light attenuation 
    ld /= lDist;
    // Diffuse
    float diff = max(dot(norm, ld), 0.0);
    
    // specular
    float spec = pow(max( dot( reflect(-ld, norm), -rd ), 0.0 ), 8.0);
    
    //Colors
    vec3 objCol = vec3(0.3, 0.0, 0.0); // brown red
    vec3 glowCol = vec3(0.5, 0.0, 0.0); // red glow color
    vec3 sceneCol;
    
  
    // Get final color
    sceneCol = (objCol*(diff + 0.15) + vec3(1.0, 0.6, 0.2)*spec*1.2) * atten;
    
    // fog
    sceneCol =  mix( sceneCol, vec3(0.0,0.0,0.0), 1.0 - exp( -0.0001*t*t*t ) );
    
    // originaly a glow based on minimum distance,
    //but made a really cool smoke effect with the fbm on the plane
    float glow = smoothstep(0.01, 1.5, 0.0014 / md * t);
    sceneCol += glowCol * glow;
    
    
    return sceneCol;
    
}

void main(void)
{
    vec2 uv = 0.35 * vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y; 
   
    // Ray origin (camera)
     vec3 ro = vec3(0.0, 0.0, 0.0); 
    
    // Ray direction
    vec3 rd = normalize(vec3(uv,2.0));
   
    float t = 12.0; // total distance, starts at 12 to avoid seeing the mountain right in front
    float d; // distance to nearest scene object
    
    float minDist = 999.0; // If a ray hits nothing, this will store how close it came to hitting.
    
    for (int i = 0; i < 80; i++) // raymarch
    {
        d = map(ro + rd*t);
        
        minDist = min(minDist, d); // Getting the minimum distance to an object for this ray
        
        if(abs(d)<0.1) // hit somthing
        {
            minDist = 0.1;
            break;  
        }
        if(t>FAR) // went too far
        {
            minDist = min(minDist, d);
            t = FAR;
            break;
        }
        
        t += d * DISTANCE_BIAS;
    }
    
    vec3 sceneColor = vec3(0.0, 0.0, 0.0); // main color
    
    vec3 norm = getNormal(ro + rd * t); // get normal of hit point
    
    
     // final color with the gamma correction 
    sceneColor = col(ro, rd, norm, minDist, t);
    glFragColor = vec4(sqrt(clamp(sceneColor, 0.0, 1.0)), 1.0);
 
}
