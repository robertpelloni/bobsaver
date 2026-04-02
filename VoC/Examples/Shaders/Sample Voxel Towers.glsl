#version 420

// original https://www.shadertoy.com/view/llG3RD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shader by Zanzlanz ;)
// You can freely use and alter this shader (please give credit of course).

const float worldSize = 150.0;
const float pi = 3.1415926536;
const vec3 skyColor = vec3(22.0/255.0, 86.0/255.0, 129.0/255.0);

vec3 cam;
vec3 camRot;
float tick = 0.0;

// One of my favorite utilities :)
float mod2(float a, float b) {
    float c = mod(a, b);
    return (c < 0.0) ? c + b : c;
}

// For coloring blocks, but current not used
float rand2(vec2 co){
    return fract(sin(dot(co.xy*.01, vec2(25.5254, -15.5254))) * 52352.323);
}

// For block heights
float rand(vec2 co){
    return min(rand2(co)+sin(co.x*.1-co.y*.5+tick*.2)*.1+cos(co.y*.3+co.x*.5+tick*.4)*.1,
               .87+length(vec2(mod2(co.x-cam.x+worldSize*.5, worldSize)-worldSize*.5, mod2(co.y-cam.z+worldSize*.5, worldSize)-worldSize*.5))*.1);
}

vec3 getFG(vec3 co) {
    if(co.y/worldSize*3.0 < rand(vec2(co.x, co.z))) {
        //Uncomment below for randomly colored blocks
        //return vec3(rand(vec2(co.x+co.y+1., co.z+2.)), rand(vec2(co.x+3., co.z+co.y+4.)), rand(vec2(co.x+co.y+5., co.z+co.y+6.)));
    
        return vec3(1.0, 1.0, 1.0);
    }
    return vec3(-1, 0, 0);
}
vec4 raycast(vec3 start, vec3 castSpeedStart) {
    vec3 castSpeed = vec3(castSpeedStart.xyz);
    float skyAmount = castSpeed.y*.4;
    
    vec4 returnValue = vec4(skyColor*skyAmount, 0.0);
    vec3 ray = vec3(start.xyz);
    
    float shadowing = 1.0;
    vec3 currentCast = vec3(floor(ray));
    
    int collideWith = 0;
    
    bool skipLoop = false;
    for(float its=0.0; its<200.0; its++) {
        if(skipLoop) {
            skipLoop = false;
            continue;
        }
        if(currentCast.y<0.0 || currentCast.y>=worldSize*.4) {
            returnValue = vec4(skyColor*skyAmount, 0);
            break;
        }
        
        vec3 inBlock = getFG(vec3(mod(currentCast.x, worldSize), mod(currentCast.y, worldSize), mod(currentCast.z, worldSize)));
        if(inBlock.x != -1.0) {
            float finalShadowing = clamp(shadowing-length(ray-start)/60.0, 0.0, 1.0);
            
            if       (collideWith == 0) finalShadowing *= .5;
            else if(collideWith == 1) finalShadowing *= .7;
            else if(collideWith == 2) finalShadowing *= .3;
            else if(collideWith == 3) finalShadowing *= .8;
              else if(collideWith == 4) finalShadowing *= .6;
            else if(collideWith == 5) finalShadowing *= .4; // Not sure a better way to do this at the moment

            returnValue = vec4(inBlock*finalShadowing+(1.0-finalShadowing)*skyColor*skyAmount, 0.0 );
            break;
        } // Here is also where I used to do reflections and fun stuff... recursively though
        
        // These last three IFs are checking if the ray passes the next voxel plane
        if(castSpeed.x != 0.0) {
            float t = ( floor(currentCast.x+clamp(sign(castSpeed.x), 0.0, 1.0)) -ray.x)/castSpeed.x;
            vec3 cast1Tmp = ray+castSpeed*t;
            if(cast1Tmp.y>=currentCast.y && cast1Tmp.y<=currentCast.y+1.0 && cast1Tmp.z>=currentCast.z && cast1Tmp.z<=currentCast.z+1.0) {
                ray = cast1Tmp;
                currentCast.x += sign(castSpeed.x);
                collideWith = (castSpeed.x>0.0?0:1);
                skipLoop = true;
                continue;
            }
        }
        if(castSpeed.y != 0.0) {
            float t = ( floor(currentCast.y+clamp(sign(castSpeed.y), 0.0, 1.0)) -ray.y)/castSpeed.y;
            vec3 cast1Tmp = ray+castSpeed*t;
            if(cast1Tmp.x>=currentCast.x && cast1Tmp.x<=currentCast.x+1.0 && cast1Tmp.z>=currentCast.z && cast1Tmp.z<=currentCast.z+1.0) {
                ray = cast1Tmp;
                currentCast.y += sign(castSpeed.y);
                collideWith = (castSpeed.y>0.0?2:3);
                skipLoop = true;
                continue;
            }
        }
        if(castSpeed.z != 0.0) {
            float t = ( floor(currentCast.z+clamp(sign(castSpeed.z), 0.0, 1.0)) -ray.z)/castSpeed.z;
            vec3 cast1Tmp = ray+castSpeed*t;
            if(cast1Tmp.y>=currentCast.y && cast1Tmp.y<=currentCast.y+1.0 && cast1Tmp.x>=currentCast.x && cast1Tmp.x<=currentCast.x+1.0) {
                ray = cast1Tmp;
                currentCast.z += sign(castSpeed.z);
                collideWith = (castSpeed.z>0.0?4:5);
                skipLoop = true;
                continue;
            }
        }
    }
    returnValue.w = length(ray-start);
    float val = 1.0-returnValue.w/70.0;
    return vec4(returnValue.xyz*val, 1.0);
}

void main(void) {
    vec2 f2 = vec2(gl_FragCoord.x, resolution.y-gl_FragCoord.y);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    tick = time;
    
    cam.x = worldSize/2.0+sin(tick/worldSize*14.0*pi)*10.0;
    cam.y = worldSize-100.0;
    cam.z = worldSize/2.0+tick*8.0;
    
    camRot = vec3(sin(tick/worldSize*22.0*pi)*.5+.5, 0.0, sin(tick/worldSize*14.0*pi)*.5);
    
    vec3 castDir = vec3(0, 0, 0);
    vec3 cast1 = vec3(cam+.5);
    vec3 cast2 = vec3(0, 0, 0);

    // Getting raycast speed based on the pixel in the frustrum
    castDir.x = f2.x/resolution.y*5.0-(resolution.x-resolution.y)/2.0/resolution.y*5.0-.5*5.0;
    castDir.y = (.5-f2.y/resolution.y)*5.0;
    castDir.z = 3.0;

    // Rotating camera in 3D
    cast2.x = castDir.x*(cos(camRot.y)*cos(camRot.z))+castDir.y*(cos(camRot.z)*sin(camRot.x)*sin(camRot.y)-cos(camRot.x)*sin(camRot.z))+castDir.z*(cos(camRot.x)*cos(camRot.z)*sin(camRot.y)+sin(camRot.x)*sin(camRot.z));
    cast2.y = castDir.x*(cos(camRot.y)*sin(camRot.z))+castDir.y*(cos(camRot.x)*cos(camRot.z)+sin(camRot.x)*sin(camRot.y)*sin(camRot.z))-castDir.z*(cos(camRot.z)*sin(camRot.x)-cos(camRot.x)*sin(camRot.y)*sin(camRot.z));
    cast2.z = -castDir.x*(sin(camRot.y))+castDir.y*(cos(camRot.y)*sin(camRot.x))+castDir.z*(cos(camRot.x)*cos(camRot.y));
 
    vec3 castResult = raycast(cast1, cast2).xyz;
    
    glFragColor = vec4(clamp(castResult, 0.0, 1.0), 1.0);
}
