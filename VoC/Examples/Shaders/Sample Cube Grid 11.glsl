#version 420

#define MAX_DISTANCE 10.0
#define EPSILON 0.001

#define TWO_PI 6.28318530718

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

float udBox( vec3 p, float b )
{
  return length(max(abs(p)-b,0.0));
}

vec3 translateAndWrap(vec3 worldPosition, vec3 translation) {
    return fract(worldPosition - translation) * 2.0 - 1.0;
}

#define BOX_SPEED 0.5
float rand(vec3 n){return fract(sin(n.x) * 4375.854 + sin(n.y) * 1413.151 + sin(n.z) * 7512.434);}
vec3 boxTranslation(vec3 worldPosition) {
    vec3 seed = floor(worldPosition);
    vec3 r = vec3(rand(seed), rand(seed+111.0), rand(seed+222.0));
    float x = r.x*0.4-0.2;
    float y = r.y*0.4-0.2;
    float z = r.z*0.4-0.2;
    return vec3(x*sin(BOX_SPEED*time + r.x*TWO_PI),
            y*sin(BOX_SPEED*time + r.y*TWO_PI),
            z*sin(BOX_SPEED*time + r.z*TWO_PI)
           );
}

#define BOX_SIZE .2
float map(vec3 worldPosition) {
    vec3 centerPos = translateAndWrap(worldPosition, boxTranslation(worldPosition));
    return udBox(centerPos, BOX_SIZE);
}

float mapGlow(vec3 worldPosition) {
    vec3 glowCorner = vec3(BOX_SIZE);
    vec3 myPos = translateAndWrap(worldPosition, boxTranslation(worldPosition));
    return distance(glowCorner, abs(myPos));
}

vec3 getSurfaceNormal(vec3 p) {
    const float d = 0.007;
    return normalize(
        vec3(
            map(p+vec3(  d,0.0,0.0)) - map(p+vec3( -d,0.0,0.0)),
            map(p+vec3(0.0,  d,0.0)) - map(p+vec3(0.0, -d,0.0)),
            map(p+vec3(0.0,0.0,  d)) - map(p+vec3(0.0,0.0, -d))
        )
    );
}

struct TraceResult {
    float totalDistance;
    float surfaceDistance;
    vec3 endPosition;
    float glow;
};

#define GLOW 0.1
TraceResult traceRay(vec3 cameraPosition, vec3 direction) {
    float totalDistance;
    float surfaceDistance;
    vec3 pos;
    float maxGlow;
        
    for(int i=0; i<64; i++) {
        pos = cameraPosition + direction * totalDistance;
        surfaceDistance = map(pos);
        
        float glowDistance = mapGlow(pos);
        float glowFactor = (GLOW - glowDistance)/GLOW;
        
        if(glowFactor > .0) {
            float glowCamDist = distance(cameraPosition, pos);
            float glowFog = 1.0 / (1.0 + glowCamDist * glowCamDist * 0.05);
            float glowTotal = glowFactor * glowFactor * glowFog;
            
            if(glowTotal > maxGlow) {
                maxGlow = glowTotal;
            }
        }
        
        totalDistance += min(glowDistance * 0.2, surfaceDistance * 0.4);
        if(totalDistance > MAX_DISTANCE || surfaceDistance < EPSILON) {
            break;    
        }
    }
    return TraceResult(totalDistance, surfaceDistance, pos, maxGlow);
}

vec3 getLightPosition(vec3 cameraPosition) {
    vec2 mouseNorm = mouse * 2.0 - 1.0;
    return vec3(cameraPosition.xy + mouseNorm*2.0, cameraPosition.z);
}

vec3 getGlow(float glow) {
    if(glow > .0) {
        return glow*vec3(0.2,0.2,1.0);
    }
    
    return vec3(0.0);
}

vec3 getColor(vec3 cameraPosition, TraceResult traceResult) {
    float fog = 1.0 / (1.0 + traceResult.totalDistance * traceResult.totalDistance * 0.5);
    
    vec3 surfaceNormal = getSurfaceNormal(traceResult.endPosition);
    
    vec3 lightPosition = getLightPosition(cameraPosition);
    vec3 lightDirection = normalize(lightPosition-traceResult.endPosition);
    
    vec3 lightReflection = reflect(-lightDirection, surfaceNormal);
    vec3 cameraDirection = normalize(cameraPosition - traceResult.endPosition);
    float specularFactor = max(0.0, dot(cameraDirection, lightReflection));
    
    float ambient = 0.1;
    float diffuse = max(0.0, dot(surfaceNormal, lightDirection));
    float specular = 0.7 * pow(specularFactor, 16.0);
    
    vec3 lightColor = vec3(0.8, 1.0, 0.4);
    
    vec3 glow = getGlow(traceResult.glow);
    
    return fog*(ambient+diffuse+specular)*lightColor + glow;
}

void main( void ) {

    vec2 screenPosition = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    screenPosition.x *= resolution.x/resolution.y;
    
    float amplitude = 0.3;
    float rotSpeed = 0.5;
    float cosVal = amplitude*cos(time*rotSpeed);
    float sinVal = amplitude*sin(time*rotSpeed);
    
    vec3 cameraPosition = vec3(
        .0, //cosVal+time*0.1,
        .0, //-sinVal+time*0.03,
        time*0.1
    );
    
    screenPosition.x += cosVal * .5;
    screenPosition.y += -sinVal * .25;
    
    vec3 direction = normalize(vec3(screenPosition, 1.0));
    
    TraceResult traceResult = traceRay(cameraPosition, direction);
    
    vec3 color = traceResult.surfaceDistance < EPSILON ?
        getColor(cameraPosition, traceResult) : getGlow(traceResult.glow);
    
    glFragColor = vec4( color, 1.0 );

}
