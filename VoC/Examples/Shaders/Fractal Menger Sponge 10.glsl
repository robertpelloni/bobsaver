#version 420

// original https://www.shadertoy.com/view/WtfXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERATIONS 1000.0
#define PRECISION 0.00001
#define MAXIMUMDISTANCE 100.0

//Menger sponge SDF by fb39ca4
//https://www.shadertoy.com/user/fb39ca4

float sdCross(vec3 p) {
    p = abs(p);
    vec3 d = vec3(max(p.x, p.y),
                  max(p.y, p.z),
                  max(p.z, p.x));
    return min(d.x, min(d.y, d.z)) - (1.0 / 3.0);
}

float sdCrossRep(vec3 p) {
    vec3 q = mod(p + 1.0, 2.0) - 1.0;
    return sdCross(q);
}

float sdCrossRepScale(vec3 p, float s) {
    return sdCrossRep(p * s) / s;    
}

//SDF Pass
float SDFpass(vec3 rayPos) {
    float scale = 1.0;
    float dist = 0.0;
    for (int i = 0; i < 5; i++) {
        dist = max(dist, -sdCrossRepScale(rayPos, scale));
        scale *= 3.0;
    }
    return dist;
}

//Normals
vec3 getNormal(vec3 rayPos) {
    vec2 offset = vec2(PRECISION,0.0);
    return normalize(vec3(
        SDFpass(rayPos + offset.xyy) - SDFpass(rayPos - offset.xyy),
        SDFpass(rayPos + offset.yxy) - SDFpass(rayPos - offset.yxy),
        SDFpass(rayPos + offset.yyx) - SDFpass(rayPos - offset.yyx)));
}

//Lighting

//Ambient occlusion
float lightAmbientOcclusion(vec3 rayPos, vec3 normal, float size, float iterations, float intensity) {
    float ambientOcclusion = 0.0;
    for (float i = 1.0; i <= iterations; i++) {
        float dist = size * i;
        ambientOcclusion += max((dist - SDFpass(rayPos + normal * dist)) / dist, 0.0);
    }
    return 1.0 - ambientOcclusion * intensity;
}

//Image
void main(void) {
    
    vec2 uv = gl_FragCoord.xy/resolution.xy; //UVs
    vec2 uvn = uv * 2.0 - 1.0;
    
    //vec2 mouse = vec4(mouse.x*resolution.x / resolution.xy * 2.0 - 1.0,mouse.y*resolution.y); //Mouse input
    
    vec3 camPos = vec3(0.0,0.0,mod(time,2.0)); //Basic camera setup
    vec3 camRot = vec3(0.0, 0.0, time * 15.0); //Camera rotation
    
    vec3 rayPos = camPos; //Set ray position
    vec3 rayDir = normalize(vec3(uvn.x, uvn.y * resolution.y / resolution.x,1.0)); //FOV
    float rayDist;
    
    //Rotation matrix (Camera rotation)
    rayDir = vec3(rayDir.x * cos(radians(camRot.z)) + rayDir.y * sin(radians(camRot.z)),
                  rayDir.y * cos(radians(camRot.z)) + rayDir.x * -sin(radians(camRot.z)),
                  rayDir.z);
    rayDir = vec3(rayDir.x,
                  rayDir.y * cos(radians(camRot.x)) + rayDir.z * sin(radians(camRot.x)),
                  rayDir.z * cos(radians(camRot.x)) + rayDir.y * -sin(radians(camRot.x)));
    rayDir = vec3(rayDir.x * cos(radians(camRot.y)) + rayDir.z * sin(radians(camRot.y)),
                  rayDir.y,
                  rayDir.z * cos(radians(camRot.y)) + rayDir.x * -sin(radians(camRot.y)));
    
    vec3 color = vec3(1.0); //Sky Color
    
    vec3 normal; //Init normal
    float dist; //Init distance
    
    for (float i = 0.0; i < ITERATIONS; i++) { //SDF passes
        rayDist = SDFpass(rayPos); //SDF pass
        if (rayDist < PRECISION) { //Collision
            normal = getNormal(rayPos); //Calculate normal
            color = mix(vec3(1.0) * lightAmbientOcclusion(rayPos, normal, 0.4, 5.0, 0.2), vec3(0.6,0.2,0.8), dist/5.0) + i / ITERATIONS;
            break;
        }
        if (dist > MAXIMUMDISTANCE) {
            break;
        }
        rayPos += rayDist * rayDir; //Move ray
        dist += rayDist;
    }
    glFragColor = vec4(color,1.0); //Render to screen
}
