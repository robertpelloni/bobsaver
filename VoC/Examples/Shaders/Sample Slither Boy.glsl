#version 420

// original https://www.shadertoy.com/view/NtsGzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int MAX_STEPS = 200; //max steps for raymarching algorithm
float THRESHOLD = 0.001; //distance for which the ray marcher considers a surface to be hit
float MAX_DISTANCE = 80.0; //the ray marcher will stop after this distance; no hit
float NORMAL_DIFFERENTIAL = 0.0001; //a samll variation for gradient/normal approximations
float SHADOW_MARCH_OFFSET = 0.001; //a small offset to prevent self intersection during the shadow march
float SHADOW_SHARPNESS_FACTOR = 64.0; //how sharp the soft shadows should be
float IMPLICIT_SURFACE_UNDERESTIMATION_FACTOR = 0.7; //controls convergence speed

//not using AO for now
#define AO_STEPS 0
float AO_INTENSITY = 0.0;
float AO_DIFFERENTIAL = 0.01;

float hillInvAmplitude = 1.0; //inverse amplitude of the ground function
float hillFrequency = 0.5; //the frequency of the ground function

vec3 snakePos = vec3(0.0, 0.0, 0.0); //the root position of the snake's head

//a slow way to get a translation-rotation transformation
mat4 transform(vec3 translation, vec3 rotation) {
    float g = rotation.x;
    float b = rotation.y;
    float a = rotation.z;

    mat4 roll = mat4( //transposed compared to standard math notation
         cos(a), sin(a), 0.0, 0.0,         
          -sin(a), cos(a), 0.0, 0.0,         
          0.0, 0.0, 1.0, 0.0,         
          0.0, 0.0, 0.0, 1.0              
    );
    mat4 yaw = mat4( //transposed compared to standard math notation
         cos(b), 0.0, -sin(b), 0.0,         
          0.0, 1.0, 0.0, 0.0,         
          sin(b), 0.0, cos(b), 0.0,         
          0.0, 0.0, 0.0, 1.0              
    );
    mat4 pitch = mat4( //transposed compared to standard math notation
         1.0, 0.0, 0.0, 0.0,         
          0.0, cos(g), sin(g), 0.0,         
          0.0, -sin(g), cos(g), 0.0,         
          0.0, 0.0, 0.0, 1.0              
    );

    mat4 rot = pitch * yaw * roll;
    rot[3] = vec4(translation, 1.0);
    return rot;
}

//easy way to transform pos into a modified sdf space
vec3 sdTransform(vec3 translation, vec3 rotation, vec3 pos) {
    //transform pos instead of the sdf because the sdfs change in a complicated way
    mat4 trans = inverse(transform(translation, rotation));
    return vec3(trans*vec4(pos, 1.0));
}

//union of two sdfs (like OR)
float sdUnion(float dist1, float dist2) {
    return min(dist1,dist2);
}

//intersection of two sdfs (like AND)
float sdIntersection(float dist1, float dist2) {
    return max(dist1,dist2);
}

//subtraction of two sdfs (like AND but sdf1 is inside out)
float sdSubtraction(float dist1, float dist2) {
    return max(-dist1,dist2);
}

//smooth union of two sdfs
float sdSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

//smooth intersection of two sdfs
float sdSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); 
}

//smooth subtraction of two sdfs
float sdSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

//sdf to sphere
float sdSphere(vec3 pos) {
    return length(pos) - 1.0;
}

//sdf to ellipsoid
float sdEllipsoid(vec3 p, vec3 r){
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

//a function to represent the ground
float groundFunction (vec3 pos) {
    return sin(hillFrequency*pos.x) + 
    cos(hillFrequency*pos.z) + 
    -hillInvAmplitude*(pos.y );
}

//the gradient of the ground
vec3 groundGradient (vec3 pos) {
    return vec3(
        hillFrequency*cos(hillFrequency*pos.x), 
        -hillInvAmplitude, 
        -hillFrequency*sin(hillFrequency*pos.z)
    );
}

//the approximate signed distance to the ground (just an lower bound and not even an sdf)
float sdGround(vec3 pos) {
   float f = groundFunction(pos);
   vec3 grad = groundGradient(pos);
   return IMPLICIT_SURFACE_UNDERESTIMATION_FACTOR*abs(f)/length(grad);
}

//the sdf of the head of the snake. All done by trial and error there is no method to the mayhem
float scene_head(vec3 pos){ 
    vec3 q = pos;
    float head = sdSphere(q);
    head = sdSmoothUnion(0.7*sdSphere((q-vec3(0.0,-0.3,-1.0))/0.7), head, 0.8);
    head = sdSmoothSubtraction(2.0*sdSphere((q-vec3(0.0,2.1,0.4))/2.0), head, 0.3);
    head = sdSmoothSubtraction(0.6*sdSphere((q-vec3(0.65,0.5,0.4))/0.6), head ,0.3);
    head = sdSmoothSubtraction(0.6*sdSphere((q-vec3(-0.65,0.5,0.4))/0.6), head, 0.3);
    head = sdSmoothUnion(0.5*sdSphere((q-vec3(-0.3,0.2,-0.3))/0.5), head, 0.3);
    head = sdSmoothUnion(0.5*sdSphere((q-vec3(0.3,0.2,-0.3))/0.5), head, 0.3);
    head = sdSmoothSubtraction(0.5*sdSphere((q-vec3(0.35,0.2,-0.2))/0.5), head ,0.05);
    head = sdSmoothSubtraction(0.5*sdSphere((q-vec3(-0.35,0.2,-0.2))/0.5), head ,0.05);
    return head;
}

//the sdf of the eyes of the snake
float scene_eyes(vec3 pos) {
    vec3 q = pos;
    float eyes = 0.5*sdSphere((q-vec3(0.35,0.2,-0.2))/0.5);
    eyes = sdUnion(0.5*sdSphere((q-vec3(-0.35,0.2,-0.2))/0.5), eyes);
    eyes = sdSmoothSubtraction (0.2*sdSphere((q-vec3(0.4,0.3,0.1))/0.2), eyes, 0.15);
    eyes = sdSmoothSubtraction (0.2*sdSphere((q-vec3(-0.4,0.3,0.1))/0.2), eyes, 0.15);
    return eyes;
}

//the sdf of the pupils of the snake
float scene_pupils(vec3 pos) {
    vec3 q = pos;
    float pupils = 0.3*sdSphere((q-vec3(0.4,0.3,-0.02))/0.3);
    pupils = sdUnion(0.3*sdSphere((q-vec3(-0.4,0.3,-0.02))/0.3), pupils);
    return pupils;
}

//the sdf of the body. This is extreamly slow.
float scene_body(vec3 pos, vec3 rootPos){
    #define segmentCount 16; 
    float segmentLength = 0.5;
    float segmentWidth = 0.5;
    float segmentOffsetFactor = 0.5;
    vec3 root = vec3(0.0, 0.0, -1.0);
     
    float body = 1000000.0;
    for(int i = 0; i < segmentCount i++) { 
        vec3 segmentPos = 2.0*segmentOffsetFactor*segmentLength*float(i)*vec3(0, 0.0, -1);
        segmentPos += vec3(0, 0, 1) * snakePos;
        segmentPos += root;
        segmentPos.y = groundFunction(segmentPos) + segmentWidth;
        
        float segment = sdEllipsoid(vec3(pos - segmentPos), vec3(segmentWidth, segmentWidth, segmentLength));
        body = sdSmoothUnion(body, segment, 0.6);
    }
    
    return body;
}

//combine all the sdfs for the scene and use the distance to choose the right material id
//returns vec2 sd where sd.x = distToScene and sd.y = materialID
vec2 scene (vec3 pos) {
    float ground = sdGround(pos);
    
    //head rotation
    vec3 groundGrad = groundGradient(snakePos);
    float groundAngleX = acos(dot(groundGrad, vec3(0, 0, 1))/ length(groundGrad)) - 0.5*3.14;
    float groundAngleZ = -acos(dot(groundGrad, vec3(1, 0, 0))/ length(groundGrad)) + 0.5*3.14;
    
    vec3 q = sdTransform(snakePos, vec3(groundAngleX, 0.0, groundAngleZ), pos);
    float head = scene_head(q);
    float eyes =  scene_eyes(q);
    float pupils = scene_pupils(q);
    float body = scene_body(pos, snakePos);
    
    //merge body and head
    head = sdSmoothUnion(body, head, 0.3);

    //find the shortest sd
    float dist = min(head, ground);
    dist = min(dist, eyes);
    dist = min(dist, pupils);
    
    //choose material id based on shortest distance
    float objectID = -1.0;
    if (dist >= head) { 
        objectID = 2.0;
    }else if (dist >= eyes) {
        objectID = 3.0;
    }else if (dist >= pupils) {
        objectID = 4.0;
    }else {
        objectID = 1.0;
    }
    
    return vec2 (dist, objectID);
}

//aproximate normal to scene. Basically central differences method for the gradient
//returns vec2 rayData where rayData.x = rayLength and rayData.y = materialID
vec3 getNormal(vec3 pos) {
    vec3 h = vec3 (NORMAL_DIFFERENTIAL, 0, 0);
    
    vec3 normal = vec3(
        scene(pos + h.xyy).x - scene(pos - h.xyy).x,
        scene(pos + h.yxy).x - scene(pos - h.yxy).x,
        scene(pos + h.yyx).x - scene(pos - h.yyx).x
    );

    return normalize(normal);
}

//the raymarching algorithm
vec2 Raymarch (vec3 ro, vec3 rd) {
    vec2 sceneDistance = vec2 (0.0, -1.0);
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 rayPos = ro + sceneDistance.x*rd;
        
        vec2 localDistance = scene(rayPos);
        if (localDistance.x < THRESHOLD) {
            break;
        }
    
        sceneDistance.x += localDistance.x;
        sceneDistance.y = localDistance.y;
        
        if (sceneDistance.x > MAX_DISTANCE) {
            break;
        }
    }
    if(sceneDistance.x > MAX_DISTANCE) {
        sceneDistance.x = -1.0;
    }
    
    return sceneDistance;
}

//sdf ambient occlusion. Didn't play well with the implicit surface
float AO (vec3 pos, vec3 normal) {
    float ao = 0.0;
    float dist = 0.0;
    for(int i = 0; i < AO_STEPS; i++) {
        dist = AO_DIFFERENTIAL * float(i);
        ao += max (0.0, (dist - scene(pos + normal*dist).x)/dist);
    }
    return 1.0 - ao*AO_INTENSITY;
}

float softShadow (vec3 ro, vec3 rd) {
    float penumbra = 1.0;

    float sceneDistance = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 rayPos = ro + sceneDistance*rd;
        
        float localDistance = scene(rayPos).x;
        
        penumbra = min(penumbra, SHADOW_SHARPNESS_FACTOR*localDistance/sceneDistance);
             
        if (localDistance < THRESHOLD) {
            break;
        }
        
        sceneDistance += localDistance;
        
        if (sceneDistance > MAX_DISTANCE) {
            break;
        }
    }
    
    return penumbra;
}

void main(void)
{
    //normalized screen space coordinates
    vec2 uv = (gl_FragCoord.xy - 0.5f*resolution.xy)/resolution.y;
    
    //snake pos 
    snakePos = vec3(0.0, 0.0, 3.0*time);
    snakePos.y = groundFunction(snakePos) + 1.0;
    
    //choose a camera angle based on mouse position
    float anglex = 10.0*mouse.x*resolution.xy.x/resolution.x;
    float angley = 10.0*mouse.y*resolution.xy.y/resolution.y;
    
    //set the ray origin
    float cameraDist = 12.0;
    vec3 ro = vec3(cameraDist*sin(anglex), angley, cameraDist*cos(anglex)) + vec3(0.0, 0.0, snakePos.z);
  
    //lookat computations
    vec3 target = snakePos;
    vec3 w = normalize((target - ro));
    vec3 u = normalize (cross(w, vec3(0, 1, 0)));
    vec3 v = normalize (cross(u, w));
   
    //set the ray direction using the lookat values
    vec3 rd = normalize(uv.x*u + uv.y*v + 1.0*w);
    
    //use blue gradient to color the sky
    vec3 col = vec3(0.4, 0.75, 1.0) - 1.0*rd.y;
    
    //ray march
    vec2 sceneDistance = Raymarch(ro, rd);
    
    if(sceneDistance.x > 0.0) {
        //recover the ray
        vec3 hitPosition = ro + sceneDistance.x*rd;
        vec3 hitNormal = getNormal(hitPosition);
        
        //defualt material value
        vec3 material = vec3(0.18);
        
        //use the material id to choose the material properies
        if(sceneDistance.y == 1.0) { //the ground material
            material = 0.18*vec3(0.129, 0.909, 0.137);
            
            //darken the color with sin to get stripes
            float f = smoothstep(0.4, 0.5, 0.5 + 0.5*sin(6.0*hitPosition.z + 6.0*hitPosition.x));
            material = mix (material, 0.8*material, f);
        } else if (sceneDistance.y == 2.0) { //the snake skin material
            material = 0.18*vec3(1.0, 0.564, 0.180);
            
            //darken the color with sin to get stripes
            float f = smoothstep(0.4, 0.5, 0.5 + 0.5*sin(12.0*(hitPosition.z - snakePos.z)));
            material = mix (material, 0.8*material, f);
        } else if (sceneDistance.y == 3.0) { //the eye material
            material = 0.18*vec3(1.0, 1.0, 1.0);
        } else if (sceneDistance.y == 4.0) { //the snake pupil material
            material = 0.18*vec3(0.03, 0.03, 0.03);
        }
        
        //set a direction for the sun light
        vec3 sunDirection = normalize(vec3(0.8, 0.4, 0.2));
        
        //light colors
        vec3 sunColor = vec3(7.0, 4.5, 3.0);
        vec3 skyColor = vec3(0.5, 0.8, 0.9);
        vec3 bounceColor = vec3(0.7, 0.3, 0.2);
        
        //specular strengtho constant. Could be changed to be per material.
        float specularStrength = 0.7;
        
        //directional light calculations. The bias for bounceDiffuse and skyDiffuse is in effect an ambient lighting layer
        float sunDiffuse = clamp(dot(hitNormal, sunDirection), 0.0, 1.0);
        float skyDiffuse = clamp(0.5 + 0.5*dot(hitNormal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
        float bounceDiffuse = clamp(0.5 + 0.5*dot(hitNormal, vec3(0.0, -1.0, 0.0)), 0.0, 1.0);
        //specular according to the Phong model
        float specular = pow(max(dot(rd, reflect(sunDirection, hitNormal)), 0.0), 32.0);
        //sun showow is computed with a second ray march (a hit is any value not -1.0 so the step funtion is used)
        float sunShadow = softShadow(hitPosition + SHADOW_MARCH_OFFSET*hitNormal, sunDirection);
        
        //calulate ambient occlusion
        float ao = AO(hitPosition, hitNormal);
        
        //combine all the light calculations do get the final pixel color
        col = material*ao*(
            sunColor*sunDiffuse*sunShadow + 
            sunColor*specular*specularStrength +
            skyColor*skyDiffuse + 
            bounceDiffuse*bounceColor
        );
    }
    
    //gamma correction. Standard value for the average monitor. Makes it easier to choose good colors
    col = pow(col, vec3(0.4545)); 
    
    glFragColor = vec4(col, 1.0);
}
