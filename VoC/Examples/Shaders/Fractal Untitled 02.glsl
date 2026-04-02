#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float MAX_DISTANCE = 10.0;
const float minRadius = 0.25;
const float fudgeFactor = 0.75;

vec4 orbitTrap;

float getDistanceEstimate(vec3 position) {
    vec4 positionAndScale = vec4(position, 1);
    vec4 offset = positionAndScale;
    
    orbitTrap = vec4(1000.0);
    
    for(int i = 0; i < 15; i++) {
        positionAndScale.xyz = abs(positionAndScale.xyz);
        float radiusSquared = dot(positionAndScale.xyz, positionAndScale.xyz);
        positionAndScale = 1.6*positionAndScale/clamp(radiusSquared, 0.4, 1.0) - vec4(vec3(0.5, 1.0, 0.4), 0.0);
        
        orbitTrap = min(orbitTrap, vec4(abs(positionAndScale.xyz), positionAndScale.w));
    }
    
    return (length(positionAndScale.xyz))/positionAndScale.w - 0.001;
}

vec3 getNormal(vec3 position) {
    vec2 epsilon = vec2(0.001, 0.0);
    vec3 normal = vec3(
        getDistanceEstimate(position + epsilon.xyy) - getDistanceEstimate(position - epsilon.xyy),
        getDistanceEstimate(position + epsilon.yxy) - getDistanceEstimate(position - epsilon.yxy),
        getDistanceEstimate(position + epsilon.yyx) - getDistanceEstimate(position - epsilon.yyx)
    );
    
    return normalize(normal);
}

float getAmbientOcclusion(vec3 position, vec3 normal) {
    float occlusion = 0.0, 
        marchStep = 0.02, 
        scatterCoefficient = 1.0;
    
    for(int i = 0; i < 15; i++) {
        float distanceFromGeometry = getDistanceEstimate(position + normal*marchStep);
        occlusion += (marchStep - distanceFromGeometry)*scatterCoefficient;
        scatterCoefficient *= 0.9;
        marchStep += marchStep/(float(i) + 1.0);
    }
    
    return 1.0 - clamp(occlusion, 0.0, 1.0);
}

void main( void ) {
    vec2 pixelCoordinate = -1.0 + 2.0*gl_FragCoord.xy/resolution;
    pixelCoordinate.x *= resolution.x/resolution.y;
    
    vec3 finalColor = vec3(0);
    float animationTime = time*0.3;
    vec3 cameraPosition = 0.75*vec3(cos(animationTime), 0.0, -sin(animationTime));
    vec3 cameraForward = normalize(vec3(0, 2.0*sin(animationTime), 0) - cameraPosition);
    vec3 cameraRight = normalize(cross(vec3(0, 1, 0), cameraForward));
    vec3 cameraUp = normalize(cross(cameraForward, cameraRight));
    
    vec3 cameraDirection = normalize(pixelCoordinate.x*cameraRight + pixelCoordinate.y*cameraUp + 1.97*cameraForward);
    
    float totalDistanceMarched = 0.0;
    
    vec3 position = vec3(0);
    for(int i = 0; i < 200; i++) {
        position = cameraPosition + cameraDirection*totalDistanceMarched;
        float distanceFromGeometry = getDistanceEstimate(position);
        if(distanceFromGeometry < 0.00001*(1.0 + 80.0*totalDistanceMarched) || totalDistanceMarched >= MAX_DISTANCE) break;
        totalDistanceMarched += distanceFromGeometry*fudgeFactor;
    }
    
    if(totalDistanceMarched < MAX_DISTANCE) {
        vec3 normal = getNormal(position);
        vec3 viewReflect = reflect(cameraDirection, normal);
        
        vec3 keyLightDirection = normalize(vec3(0.8, 0.7, -0.6));
        
        finalColor  = 0.2*vec3(1); // ambient
        finalColor += 0.7*clamp(dot(keyLightDirection, normal), 0.0, 1.0); // diffuse
        
        vec3 material = mix(vec3(1), vec3(0.8, 0.3, 0.4), orbitTrap.x);
        material = mix(material, vec3(0.2, 0.2, 0.9), orbitTrap.z);
        material = mix(material, vec3(0.1, 0.6, 0.3), orbitTrap.y);
        
        finalColor *= material;
        
        finalColor += 0.3*pow(clamp(dot(viewReflect, keyLightDirection), 0.0, 1.0), 16.0); // specular
        finalColor += 0.1*pow(clamp(1.0 + dot(cameraDirection, normal), 0.0, 1.0), 2.0); // fresnel
        
        finalColor *= vec3(getAmbientOcclusion(position, normal));
    }
    
    finalColor = sqrt(finalColor);
    
    glFragColor = vec4(finalColor, 1);
}
