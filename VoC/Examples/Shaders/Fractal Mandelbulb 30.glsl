#version 420

// original https://www.shadertoy.com/view/wllXz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float opUnion(float d1, float d2){
    return min(d1,d2);
}
float opSub(float d1, float d2){
    return max(-d1, d2);
}
float opInter(float d1, float d2){
    return max(d1,d2);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float opSmoothSub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); 
}

float lerp(float a, float b, float t){
    return a + (b - a) * t;
}

float DE(vec3 pos) {
    int Iterations = 128;
    float Bailout = 3.0f;
    float Power = 1.0f * time * 0.5;
    
    if (Power > 10.0) Power += 10.0;
    
    vec3 z = pos;
    float dr = 1.0;
    float r = 1.0;
    for (int i = 0; i < Iterations ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}

float GetDistance(vec3 pos){
    return DE(pos);
    float planeFrequency = 0.01 * time; // 0.5
    
    vec3 spherePos = vec3(0.0,0.0,-1.0 * time * time * time - 50.0);
    float sphereRadius = sin(time) * sin(time) * 5.0 + 2.0;
    spherePos.y -= sphereRadius;
    
    vec3 sphere2Pos = vec3(cos(time) * 3.0,-10.5,-1.0 * time * time * time - 50.0);
    float sphere2Radius = 5.0;
    
    float angle = pos.x + pos.y + pos.z;
    float offset = sin(angle * time) * 0.1;
    
    float sphereDist = length(pos - spherePos) - sphereRadius + offset;
    float sphere2Dist = length(pos - sphere2Pos) - sphere2Radius;
    
    float planeAngle = pos.x - pos.z + time + cos(pos.x);
    float planeDist = 5.0 - pos.y - cos(planeAngle * planeFrequency) * 2.0 + cos(pos.x + pos.y) * 2.0;
    
    float smallestDist = opSmoothSub(sphereDist, sphere2Dist, 1.0);
    smallestDist = opUnion(smallestDist, planeDist);
    
    //return smallestDist;
    
    // infinite amount of spheres
    float spacing = 4.0 * time;//15.0;
    
    pos = mod(pos,spacing) - vec3(spacing * 0.5);
    return length(pos) - 4.0;
    
}

float RayMarchShadow(vec3 rayOrigin, vec3 rayDir){
    float total_distance = 0.0;
    int number_of_steps = 256;
    float minimum_hit_distance = 0.001;
    float maximum_trace_distance = 1000.0;
    
    for (int i = 0; i < number_of_steps; i++){
        vec3 curPos = rayOrigin + rayDir * total_distance;
        
        float dist = GetDistance(curPos);
        
        if (dist < minimum_hit_distance || total_distance > maximum_trace_distance){
            break;
        }
        
        total_distance += dist;
    }
    return total_distance;
}

vec3 Normal(vec3 pos){
    float smallStep = 0.001;
    
    float x = GetDistance(pos + vec3(smallStep,0,0)) - GetDistance(pos - vec3(smallStep,0,0));
    float y = GetDistance(pos + vec3(0,smallStep,0)) - GetDistance(pos - vec3(0,smallStep,0));
    float z = GetDistance(pos + vec3(0,0,smallStep)) - GetDistance(pos - vec3(0,0,smallStep));
    
    return normalize(vec3(x,y,z));
}

float CalculateLight(vec3 pos, vec3 cameraRayDir){
    vec3 lightPos = vec3(0.0, -10.0, 10.0);
    vec3 normal = Normal(pos);
    
    vec3 dirToLight = normalize(lightPos - pos);
    float distToLight = length(dirToLight);
    
    float intensity = max(0.0,dot(dirToLight, normal))/(distToLight * distToLight + 1.0) * 2.0;
    
    // bright thing
    intensity += min(0.5,max(0.0,pow(dot(cameraRayDir, normal), 8.0)));
    
    //float intensity = dot(vec3(cos(time),sin(time),0.0),normal);
    //return intensity;
    
    // calculate if we should cast a shadow
    vec3 newPos = pos + normal * 0.3;
    float newDist = RayMarchShadow(newPos, dirToLight);
    
    // we hit something
    if (newDist < length(lightPos - newPos)){
        intensity *= 0.1;
    }
    
    return intensity;
}

vec3 RayMarch(vec3 rayOrigin, vec3 rayDir){    
    float total_distance = 0.0;
    int number_of_steps = 512;
    float minimum_hit_distance = 0.001;
    float maximum_trace_distance = 1000.0;
    bool glow = true;
    
    float minAllTime = maximum_trace_distance;
    
    for (int i = 0; i < number_of_steps; i++){
        vec3 curPos = rayOrigin + rayDir * total_distance;
        
        float dist = GetDistance(curPos);
        
        minAllTime = min(minAllTime, dist);
        
        if (dist < minimum_hit_distance){
            return vec3(0.6,0.2,0.5) * CalculateLight(curPos, rayDir);
            //return vec3(1.0,1.0,1.0) * CalculateLight(curPos);
            
            //return vec3(cos(curPos.x),sin(curPos.y),tan(curPos.z)) * CalculateLight(curPos);
        }
        else if (total_distance > maximum_trace_distance){
            break;
        }
        total_distance += dist;
    }
    if (glow){
        return vec3(0.0,0.0,0.0) + vec3(0.56,0.27,0.68)/minAllTime / 100.0;
    }
    return vec3(0.0);
}

vec3 EachPixel(vec3 cameraPos, vec2 pos){
    float FOV = 2.0; // 1.57
    if (time > 10.0){
        FOV -= (time - 10.0);
    }
    FOV = min(FOV,2.5);
    FOV = max(FOV, 0.2);
    
    float Px = (2.0 * ((pos.x + 0.5) / resolution.x) - 1.0) * tan(FOV * 0.5);
    float Py = (1.0 - 2.0 * ((pos.y + 0.5) / resolution.y)) * tan(FOV * 0.5);
    
    return RayMarch(cameraPos, vec3(Px, Py, -1.0));
}

void main(void) {
    vec3 cameraPos = vec3(0.0,-7.5, 15.0);
    
    cameraPos = vec3(0.0,0.0,1.0);
    cameraPos.x = min(1.0, time * 0.1);
    
    //cameraPos.z = sin(time) * 2.0 + 10.0;
    //cameraPos.y = -sin(time) * sin(time) * 1.0;
    //cameraPos.z = 15.0;
    //cameraPos.z = sin(time);
    
    // recently used
    //cameraPos.z = -time * time * time;
    //cameraPos.y = -cos(time * 0.5) * cos(time * 0.5) * 40.0 - 0.0;
    
    
    //cameraPos.x = sin(cameraPos.z * 0.2 * 8.0 + 8.0;
    
    vec3 col = EachPixel(cameraPos, gl_FragCoord.xy);

    glFragColor = vec4(col,1.0);
}
