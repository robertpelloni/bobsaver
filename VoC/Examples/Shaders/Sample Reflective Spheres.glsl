#version 420

// original https://www.shadertoy.com/view/ltXSRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct orb {
    vec3 pos;
    float rad;
    float emit;
};

void main(void)
{
    // ---------------------------------------
    
    #define OBJ_COUNT 3
    
    orb orbs[OBJ_COUNT];
    
    orbs[0].pos = vec3(-20.2 + cos(time) * 30.0, -15.7 + sin(time) * 11.0, 120.0 + sin(time) * 20.0);
    orbs[0].rad = 25.0;
    orbs[0].emit = 0.0;
    
    orbs[1].pos = orbs[0].pos + vec3(cos(time) * 45.0, sin(time) * 42.0, sin(time) * 38.0);
    orbs[1].rad = 20.0;
    orbs[1].emit = 0.0;
    
    orbs[2].pos = orbs[0].pos + vec3(cos(time) * 104.0, sin(time / 2.6) * 92.0, sin(time) * 104.0);
    orbs[2].rad = 20.0;
    orbs[2].emit = 0.0;
    
    // ---------------------------------------
    
    vec2 uv = (gl_FragCoord.xy / resolution.xy - 0.5) * 2.0;
    float aspectRatio = resolution.x / resolution.y;
    uv.y /= aspectRatio;
    
    vec3 rayUnit = normalize(vec3(uv, 1.0));
    vec3 rayColor = vec3(0.0, 0.0, 0.0);
    float rayStrength = 1.0;
    vec3 rayPos = vec3(0.0, 0.0, -1.0);
    
    float wallDepth = 50.0;
    float wallScale = 100.0;
    float wallLength = 300.0;
    
    float minZ;
    bool collision;
    orb minOrb;
    float underRoot;
    float notUnder;
    float currentZ;
    vec3 surfaceNormal;
    vec3 oMinusC;
    float wallY;
    float wallTileX;
    float wallTileZ;
    
    bool emitterHit = false;
    
    minOrb.pos=vec3(0.0);
    minOrb.emit=0.0;

    for(int b = 0; b < OBJ_COUNT + 2; b++) {
        
        collision = false;
        minZ = 0.0;
        
        for(int i = 0; i < OBJ_COUNT; i++) {

            oMinusC = rayPos - orbs[i].pos;
            underRoot = pow(dot(rayUnit, oMinusC), 2.0) - pow(length(oMinusC), 2.0) + pow(orbs[i].rad, 2.0);
            notUnder = -1.0 * dot(rayUnit, oMinusC);

            if(underRoot > 0.0) {

                currentZ = min(max(notUnder + sqrt(underRoot), 0.0), max(notUnder - sqrt(underRoot), 0.0));

                if(currentZ > 0.0 && (!collision || currentZ <= minZ)) {
                    minZ = currentZ;
                    collision = true;
                    minOrb = orbs[i];
                }
            }
        }
        
        if(collision && !emitterHit) {
            
            rayPos = minZ * rayUnit + rayPos;
            surfaceNormal = normalize(rayPos - minOrb.pos);
            rayStrength *= -dot(rayUnit, surfaceNormal);
            rayUnit = rayUnit + 2.0 * surfaceNormal * -1.0 * dot(surfaceNormal, rayUnit);
            
            if(minOrb.emit > 0.0) {
                emitterHit = true;
                rayColor += rayStrength * minOrb.emit;
            }
            
        } else if(!emitterHit) {
            
            emitterHit = true;
            wallY = abs(rayPos.y + wallDepth / rayUnit.y);
            if(wallY * abs(rayUnit.z) <= wallLength && wallY * abs(rayUnit.x) <= wallLength) {
                wallTileX = abs(floor(rayUnit.x * wallY / wallScale) - rayUnit.x * wallY / wallScale);
                wallTileZ = abs(floor(rayUnit.z * wallY / wallScale) - rayUnit.z * wallY / wallScale);
                if(wallTileX > 0.5 ^^ wallTileZ <= 0.5) {
                    rayColor += rayStrength;
                }
            }
            
        }
    }
    
    glFragColor = vec4(rayColor, 1.0);
}
