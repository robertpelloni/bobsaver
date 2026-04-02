#version 420

// original https://www.shadertoy.com/view/tljcRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

# define INTERSECTED 0
# define TOO_FAR 1
# define TOO_MANY_STEPS 2
# define PI 3.1415926538
/******************************************************************************/

float waterFunction(in vec3 pos, in float time){
    const int size = 6;
    vec3 vecs[size] = vec3[](
        vec3(1,2, 0.2),
        vec3(0.5,0.5, 0.1),
        vec3(-1.,0.2, 0.1),
        vec3(0.,-0.5, 0.5),
        vec3(2.,-2., 0.01),
        vec3(-2.,5., 0.01)
    );
    float waveHeight = 0.;
    for(int i=0; i<size; i++) {
        // The speed of waves on water is independent on amplitude or wavelength.
        waveHeight += sin(pos.x*vecs[i].x+pos.z*vecs[i].y+time*length(vecs[i].xy))*vecs[i].z;
    }
    return waveHeight;
}

float sdWater(in vec3 pos){
    float waveHeight = waterFunction(pos, time);
    
    float heightDiff = pos.y - waveHeight;
    float maxSlope = 1.;
    float nextDist = sqrt(heightDiff*heightDiff / (maxSlope*maxSlope + 1.));
    if(heightDiff < 0.){
        nextDist = -nextDist;
    }
    
    return max(nextDist,heightDiff-2.);
}

void sdWaterNormal(in vec3 pos, inout vec3 normal, inout float sd){
    sd = sdWater(pos);
    vec2 e = vec2(0.01, 0.);
    normal = normalize(sd - vec3(
        sdWater(pos - e.xyy),
        sdWater(pos - e.yxy),
        sdWater(pos - e.yyx)
    ));
}

float sdSphere(in vec3 pos, in vec3 center, in float radius){
       return length(pos-center) - radius;
}

void sdSphereNormal(in vec3 pos, in vec3 center, in float radius, inout vec3 normal, inout float sd){
    sd = sdSphere(pos, center, radius);
    vec2 e = vec2(0.01, 0.);
    normal = normalize(sd - vec3(
        sdSphere(pos - e.xyy, center, radius),
        sdSphere(pos - e.yxy, center, radius),
        sdSphere(pos - e.yyx, center, radius)
    ));
}

float marchWorld(
    inout vec3 pos, inout vec3 dir,
    inout float dist, in float maxDist, in float minDist, out float nearest,
    inout int numSteps, in int maxNumSteps,
    inout vec3 color, out vec3 normal, out int returnCode
){
    float colorFrac = 1.;
    float transparency = 0.75;
    vec3 backgroundColor = vec3(0.1,0.2,0.5);
    vec3 sphereColor = vec3(0,0,0);
    vec3 waterColor = vec3(0,0,0.5);
    vec3 lightDir = normalize(vec3(1,1,1));
    nearest = maxDist;
    
    vec3 spherePosition = vec3(0,0,20);
    spherePosition.y = waterFunction(spherePosition, time-0.5)+5.;
    float sphereRadius = 4.;
    for(int i=0; i<maxNumSteps; i++) {
        float sdToWater = sdWater(pos);
        float sdToSphere = sdSphere(pos, spherePosition, sphereRadius);
        float sd = min(sdToWater, sdToSphere);
        if(sd < nearest){
            nearest = sd;
        }
        
        numSteps++;
        if(dist + sd + minDist > maxDist){
            // Fill the remaining color.
            color = mix(color, backgroundColor, colorFrac);
            sd = maxDist-dist-sd-minDist;
            dist += sd;
            pos += dir*sd;
            
            returnCode = TOO_FAR;
            return sd;
        }
        if(sd <= minDist){
            if(sdToWater < sdToSphere){
                sdWaterNormal(/*in vec3 pos=*/pos, /*inout vec3 normal=*/normal, /*inout float sd=*/sd);
                color = mix(color, waterColor*dot(lightDir, normal), colorFrac);
                colorFrac *= transparency;
                if(dot(normal, dir) < 0.){
                    dir = reflect(dir, normal);
                    sd = max(sd, minDist*2.);
                }
            }else{
                sdSphereNormal(
                    /*in vec3 pos=*/pos, /*in vec3 center=*/spherePosition, /*in float radius=*/sphereRadius,
                    /*inout vec3 normal=*/normal, /*inout float sd=*/sd
                );
                color = mix(color, sphereColor*dot(lightDir, normal), colorFrac);
                colorFrac *= transparency;
                
                if(dot(normal, dir) < 0.){
                    dir = reflect(dir, normal);
                    sd = max(sd, minDist*2.);
                }
            }
        }
        dist += sd;
        pos += dir*sd;
    }
    
    // Fill the remaining color.
    color = mix(color, backgroundColor, colorFrac);
    
    //
    returnCode = TOO_MANY_STEPS;
    return -1.;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    vec3 camPos = vec3(0.2, 3., 0.);
    vec3 viewDir = normalize(vec3(uv.x, uv.y, 1.));
    
    vec3 col = vec3(0.);
    vec3 pos = camPos;
    float dist = 0.;
    float maxDist = 1000.*100.;
    float minDist = 0.01;
    int numSteps = 0;
    int maxNumSteps = 400;
    vec3 normal;
    int returnCode;
    float nearest;
    
    marchWorld(
        /*vec3 pos=*/camPos, /*vec3 dir*/viewDir,
        /*float dist=*/dist, /*float maxDist=*/maxDist, /*float minDist=*/minDist, /*out float nearest=*/nearest,
        /*int numSteps=*/numSteps, /*int maxNumSteps=*/maxNumSteps,
        /*vec3 color=*/col, /*vec3 normal=*/normal, /*int returnCode=*/returnCode
    );
    
    // Mist.
    //col = mix(col, vec3(0,0,1), 1. / (1. + exp(-float(numSteps)*0.1 + float(maxNumSteps) - 380.)));
    
    //col = vec3(dist/100.);
    
    // Ambient occlusion.
    float factor = float(numSteps)/float(maxNumSteps);
    col = mix(col, vec3(0.5,0.5,0.7), factor);
    
    float fieldPace = 0.2;
    if(mod(time*fieldPace,4.0) <= 1.){
        float fieldFrac = mod(time*fieldPace,1.0);
        float fieldSmooth = 30.*fieldFrac+5.;
        float depth = (float(maxNumSteps)+fieldSmooth*2.)*fieldFrac-fieldSmooth*2.;
        float field = max(fieldSmooth-float(abs(numSteps - int(depth))), 0.)/fieldSmooth;
        field *= (1.-fieldFrac);
        col.g += field;
    }
    
    glFragColor = vec4(col, 1.0);
}
