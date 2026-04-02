#version 420

// original https://www.shadertoy.com/view/tty3W1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define VIEW_DIST 15.0
#define PI 3.14159265359
#define AA_SCALE 2.0
#define MODE_LIT

//Got this while messing around with a box fold and rotations... I'm sure people of have don't similar things but I'm satisfied
//I was able to arrive to this on my own :)

vec3 color;

float random(vec2 p)
{
    p *= 100.0;
    p = floor(p);
    
     return mod(sin(p.x*p.y)*65213.943 + cos(p.y*p.x+1.0)*21235.364, 1.0);   
}

float map(vec3 p)
{
    p.x = -abs(p.x);
    p.z = abs(p.z);
    float ang = -(9.34+time) * (PI/25.0);
    mat2 rot = mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
    mat2 rot1 = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
    p.xz = rot * p.xz;
    p.yz = rot1 * p.yz;
    p.y = -abs(p.y);
    p.x = -abs(p.x);
    //p.z = abs(p.z);
    
    float dz = 1.0;
    float minD = 1000.0;
    float minDy = minD;
    float minDz = minD;
    float minDx = minD;
    vec3 z = p;
    float L = 2.0;
    float Ly = 2.0;
    float Lz = 2.0;
    
    for(int x=0; x<20; x++)
    {
        if (z.x>L) { z.x = 2.0*L-z.x; } else if (z.x<-L) { z.x = -2.0*L-z.x; }
        if (z.y>L) { z.y = 2.0*Ly-z.y; } else if (z.y<-Ly) { z.y = -2.0*Ly-z.y; }
        if (z.z>L) { z.z = 2.0*Lz-z.z; } else if (z.z<-Lz) { z.z = -2.0*Lz-z.z; }
        
        float x1 = float(x);
        z.yz = mat2(cos(PI/4.), -sin(PI/4.), sin(PI/4.), cos(PI/4.)) * z.yz;
        z.xz = mat2(cos(PI/2.), -sin(PI/2.), sin(PI/2.), cos(PI/2.)) * z.xz;
        
        z = z*(2.0) + normalize(z);
        dz = dz*2.0 + 1.0;
        
        minD = min(minD, length(z-p));
        minDy = min(minDy, abs(z.y - p.y));
        minDz = min(minDz, abs(z.z - p.z));
        minDx = min(minDx, abs(z.x - p.x));
    }
    
    color = vec3(0.71, 0.31, 0.21) * 0.5  * sqrt(minDy)/sqrt(minD) + vec3(0., 0.01, 0.2) * sqrt(minDz)/sqrt(minD)
        + vec3(0.0, 0.1, 0.0) * sqrt(minDx)/sqrt(minD);
    color = color*2.5;
    #ifdef MODE_LIT
    color /= 2.5;
    #endif
    return abs(length(z)/abs(dz));
}

vec3 estNormal(vec3 p)
{
    float e = 0.001;
     float x = map(p + vec3(e,0,0)) - map(p - vec3(e,0,0));  
    float y = map(p + vec3(0,e,0)) - map(p - vec3(0,e,0));  
    float z = map(p + vec3(0,0,e)) - map(p - vec3(0,0,e));  
    return normalize(vec3(x,y,z));
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 cam = vec3(0,0,14.0-sin(time/10.0));
    vec3 dir = vec3(uv, -1);
    vec3 col = vec3(0);
    
    float ang = time/10.0;
    //cam.xz = mat2(cos(ang), -sin(ang), sin(ang), cos(ang))*cam.xz;
    //dir.xz = mat2(cos(ang), -sin(ang), sin(-ang), cos(-ang))*dir.xz;
    
    float td = 0.0;
    vec3 p;
    #ifdef AA_SCALE
    float done = 0.0;
    for(float aaX = -AA_SCALE; aaX < AA_SCALE; aaX++) {
    for(float aaY = -AA_SCALE; aaY < AA_SCALE; aaY++) {      
    uv = (2.0*(gl_FragCoord.xy + (vec2(aaX, aaY)/AA_SCALE)) - resolution.xy) / resolution.y;
    dir = vec3(uv, -1);
    #endif
    for(int x=0; x<100; x++)
    {
        p = cam + dir*td; 
        float d = map(p);
        
        if(abs(d) <= 0.01 || td > VIEW_DIST)
            break;
        
        td += d;
    }
    
    if(td <= VIEW_DIST){
        #ifdef MODE_LIT
        color = color*0.55*dot(vec3(0,10,10), estNormal(p));
        #endif
        col += color;
    }else{
        float fr = length(fract(100.0*uv) - vec2(0.5));
        float val = 1.0-smoothstep(0.0, 0.5, fr);
        float timeMod = 5.0*random(uv-32.0)+cos(time*(1.0+4.0*random(uv-22.0)));
        col = mix(vec3(0), timeMod*vec3(step(0.996, random(uv))), val);
        #ifdef AA_SCALE
        done++;
        break;
        #endif
    }
        
    #ifdef AA_SCALE
    }
    if(done > 0.0)
        break;
    }
    
    if(done <= 0.0)
        col /= float((2.0*AA_SCALE) * (2.0*AA_SCALE));
    #endif
        
    glFragColor = vec4(col, 1);
}
