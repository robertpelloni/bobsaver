#version 420

// original https://www.shadertoy.com/view/tlSGzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEPS = 100;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 1e-4;
const float PI = 3.1415;
const float shadow_sharpness = 64.0;

struct Material{
    vec3 ambientColour;
    vec3 diffuseColour;
    vec3 specularColour;
    float ambientStrength;
    float diffuseStrength;
    float shininess;
    float specularStrength;
};
    
struct Light{       
    vec3 position;
    vec3 colour; 
    //Attenuation variables
    float attn_linear;
    float attn_quad;
};
    
    
vec3 colours[4] = vec3[](vec3(1.0, 0.0, 0.0),
                         vec3(0.0, 1.0, 1.0),
                         vec3(1.0, 0.0, 1.0),
                         vec3(1.0, 1.0, 0.0));
    
vec4 getColour(vec3 cameraPos, vec3 rayDir, float dist);

Material sphere_material = Material(vec3(0.9, 0.9, 0.9), vec3(1.0, 1.0, 1.0), 
                                  vec3(1.0), 0.8, 1.0, 128.0, 1.0);
Material floor_material = Material(vec3(0.8), vec3(1.0), vec3(1.0), 0.6, 0.7, 128.0, 0.0);

Light light = Light(vec3(0.0, 2.5, -2.0), vec3(1.0), 0.09, 0.032);
    
vec3 rotate(vec3 p, vec4 q){
  return 2.0 * cross(q.xyz, p * q.w + cross(q.xyz, p)) + p;
}

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

void setColour(int c_id, float weight){
    vec3 col = mix(sphere_material.diffuseColour, colours[c_id], weight);
    sphere_material.ambientColour = 0.8*col;
    sphere_material.diffuseColour = col;
}
//https://www.iquilezles.org/www/articles/smin/smin.htm
float smoothMin(float a, float b, float k, int c_id){
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0 );
    setColour(c_id,h);
    return mix( b, a, h ) - k*h*(1.0-h);
}

float getSDF(vec3 position) {
    position.y -= 1.0 + sin(3.0*time) * 0.1;
    float k = 0.5;
    float t = time*0.6;
       float angle = PI*0.5;
    vec3 axis = normalize(vec3(0.0, 1.0, 0.0));
    position = rotate(position, vec4(axis * sin(-angle*0.5), cos(-angle*0.5))); 
    vec3 pos = position;
    float radius = 0.1;
    float dist = sphereSDF(position, radius);
    
    position = pos;
    radius = 0.15; 
    axis = normalize(vec3(-1));
    position = rotate(position, vec4(axis * sin(angle*0.5), cos(angle*0.5))); 
   
    position.x -= sin(5.0*t)*0.4;
    position.z -= cos(5.0*t)*0.4;
    dist = smoothMin(sphereSDF(position, radius), dist, k, 0);

    position = pos;
    axis = normalize(vec3(1.0,0.0,1.0));
    position = rotate(position, vec4(axis * sin(angle*0.5), cos(angle*0.5))); 
    position.x -= sin(2.0*t)*0.4;
    position.z -= cos(4.0*t)*0.4;
    dist = smoothMin(sphereSDF(position, radius), dist, k, 1);

    position = pos;
    axis = normalize(vec3(0.0, 1.0, 1.0));
    position = rotate(position, vec4(axis * sin(angle*0.5), cos(angle*0.5))); 
    position.x += sin(3.0*t)*0.4;
    position.z += cos(1.0*t)*0.4;
    dist = smoothMin(sphereSDF(position, radius), dist, k, 2);

    position = pos;
    axis = normalize(vec3(1.0, 1.0, 0.0));
    position = rotate(position, vec4(axis * sin(angle*0.5), cos(angle*0.5))); 
    position.x += sin(7.0*t)*0.4;
    position.z += cos(3.0*t)*0.4;
    dist = smoothMin(sphereSDF(position, radius), dist, k, 3);
    return dist;
}

vec3 rayDirection(float fieldOfView) {
    vec2 xy = gl_FragCoord.xy - resolution.xy / 2.0;
    float z = resolution.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

//https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat3 lookAt(vec3 camera, vec3 at, vec3 up){
  vec3 zaxis = normalize(at-camera);    
  vec3 xaxis = normalize(cross(zaxis, up));
  vec3 yaxis = cross(xaxis, zaxis);

  return mat3(xaxis, yaxis, -zaxis);
}

//Get surface normal from the gradient of the surrounding sdf field
//by sampling the values in the neighbouring area
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        getSDF(vec3(p.x + EPSILON, p.y, p.z)) - getSDF(vec3(p.x - EPSILON, p.y, p.z)),
        getSDF(vec3(p.x, p.y + EPSILON, p.z)) - getSDF(vec3(p.x, p.y - EPSILON, p.z)),
        getSDF(vec3(p.x, p.y, p.z + EPSILON)) - getSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

//https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float softShadow(vec3 pos, vec3 rayDir, float start, float end, float k ){
    float res = 1.0;
    float depth = start;
    for(int counter = 0; counter < (MAX_STEPS); counter++){
        float dist = getSDF(pos + rayDir * depth);
        if( abs(dist) < EPSILON){ return 0.0; }       
        if( depth > end){ break; }
        res = min(res, k*dist/depth);
        depth += dist;
    }
    return res;
}

float distanceToScene(vec3 cameraPos, vec3 rayDir, float start, float end) {
    
    //Start at a predefined distance from the camera in the ray direction
    float depth = start;
    
    //Variable that tracks the distance to the scene 
    //at the current ray endpoint
    float dist;
    
    //For a set number of steps
    for (int i = 0; i < MAX_STEPS; i++) {
        
        //Get the sdf value at the ray endpoint, giving the maximum 
        //safe distance we can travel in any direction without hitting a surface
        dist = getSDF(cameraPos + depth * rayDir);
        
        //If it is small enough, we have hit a surface
        //Return the depth that the ray travelled through the scene
        if (dist < EPSILON){ return depth; }
        
        //Else, march the ray by the sdf value
        depth += dist;
        
        //Test if we have left the scene
        if (depth >= end){ return end; }
    }
    
    //Return max value if we hit nothing but remain in the scene after max steps
    return end;
}

//Ambinet occlusion reduces the ambinet light strength in areas 
//which are closely shielded by other objects
//https://www.youtube.com/watch?v=22PZF7fWLqI
float ambientOcclusion(vec3 position, vec3 normal){
    float ao = 0.0;
    //step size
    float del = 0.05;
    float weight = 0.06;
    
    //Travel out from point with fixed step size and accumulate proximity to other surfaces
    //iq slides include `1.0/pow(2.0, i)` factor to reduce the effect of farther objects
    //but Peer Play uses just `1.0/dist`
    for(float i = 1.0; i <= 5.0; i+=1.0){
        float dist = i * del;
        //Ignore measurements from inside objects
        ao += max(0.0, (dist - getSDF(position + normal * dist))/dist);
    }
    //Return a weighted occlusion amount
    return 1.0 - weight * ao;
}

//http://www.iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
bool isEven(vec3 position){
    vec2 s = sign(fract(position.xz*0.5)-0.5);
    return (0.5 - 0.5*s.x*s.y) > 0.5;
}

vec4 reflection(vec3 position, vec3 rayDir, vec3 normal){
    vec3 refDir = normalize(reflect(rayDir, normal));
    float dist = distanceToScene(position + normal * EPSILON, refDir, MIN_DIST, MAX_DIST);
    vec4 col = getColour(position, refDir, dist);
    return col;
}
    
//Return colour of surface fragment based on light information
vec3 phongShading(vec3 position, vec3 normal, vec3 cameraPosition, 
                  Material material, Light light){
    
    //Create checkered pattern on the floor that fades in the distance
    if(material == floor_material){
        float weight = smoothstep(0.0, 0.5, length(cameraPosition - position)/MAX_DIST);
        vec3 darker_ambient = material.ambientColour * 0.5;
        vec3 mixed_ambient = (darker_ambient + material.ambientColour) * 0.5;
        darker_ambient = mix(darker_ambient, mixed_ambient, weight);
        material.ambientColour = mix(material.ambientColour, mixed_ambient, weight);
    
        if(isEven(0.5*position)){
            material.ambientColour = darker_ambient;
        }
    }
    
    vec3 lightDirection = normalize(light.position - position); 
    float distToLight = length(light.position - position);

    //How much a fragment faces the light
    float diff = max(dot(normal, lightDirection), 0.0);
    
    //Colour when lit by light
    vec3 diffuse = diff * material.diffuseColour * light.colour;

    //How much a fragment directly reflects the light to the camera
    vec3 viewDirection = normalize(cameraPosition - position);

    vec3 halfwayDir = normalize(lightDirection + viewDirection);  
    float spec = pow(max(dot(normal, halfwayDir), 0.0), material.shininess);

    //Colour of light sharply reflected into the camera
    vec3 specular = spec * material.specularColour * light.colour;   
    
    //https://learnopengl.com/Lighting/Light-casters
    float attenuation = 1.0 / (1.0 + light.attn_linear * distToLight + 
                light.attn_quad * (distToLight * distToLight)); 
    //Path to light blocked     
    float shadow = softShadow(position + normal * EPSILON * 8.0, lightDirection, MIN_DIST,
                              distToLight, shadow_sharpness);
    //Get ambient occlusion
    float ao = ambientOcclusion(position, normal);
    
    //Combine all aspects into a single colour
    vec3 result = ao * material.ambientStrength * material.ambientColour + 
        attenuation * shadow *(material.diffuseStrength * diffuse + 
                               material.specularStrength * specular);
    return  result;
}

Material getMaterial(int id){
    if(id == 0){
        return floor_material;
    }else{
        return sphere_material;
    }
}

float distToFloor(vec3 cameraPos, vec3 rayDir, vec3 floor_norm){
      //Find the distance to the floor as the hypotenuse of a triangle defined by
    //the height of the camera and the angle between the ray direction and the
    //negative floor normal
       return  abs(cameraPos.y/sin(PI*0.5 - acos(dot(rayDir, -floor_norm))));
}

vec4 getColour(vec3 cameraPos, vec3 rayDir, float dist){
    
    bool floor_ = false;
    vec3 floor_norm = vec3(0.0, 1.0, 0.0);
    float floor_dist = -1.0;
    
       //If ray points below the XZ plane, and the distance to the floor is smaller
    //than what is returned by the ray (either surface or max), render the floor
    if(rayDir.y < -EPSILON){
        floor_dist = distToFloor(cameraPos, rayDir, floor_norm);
        //Is the floor closer than other distances?
        floor_ = dist > floor_dist;
    }
    
    if(floor_){    
        dist = floor_dist;
    }
    
    //If the ray endpoint is not at a surface
    if (dist > MAX_DIST - EPSILON) {
        //If not pointing to floor, return sky colour
        if(!floor_){
            float weight = smoothstep(0.45, 0.6, pow(0.5 + 0.5 * rayDir.y, 1.0));
            return mix(vec4(0.7,0.82,0.92,1), vec4(0.2,0.37,0.68,1), weight);
        }
    }

    //Else, determine the surface colour
    vec3 position = cameraPos + rayDir * dist;
    vec3 normal = floor_ ? floor_norm : estimateNormal(position);
    vec3 col = phongShading(position, normal, cameraPos, getMaterial(floor_ ? 0 : 1),light);
    return vec4(col, 1.0);
}

//https://learnopengl.com/PBR/Theory
float fresnelSchlick(vec3 cameraPos, vec3 position, vec3 normal){
    float cosTheta = dot(normal, normalize(cameraPos - position));
    float F0 = 0.04;
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

void main(void) {
    //Get the default direction of the ray (along the negative Z direction)
    vec3 rayDir = rayDirection(45.0);
    
    //----------------- Define a camera -----------------
    
    vec3 cameraPos = vec3(sin(0.2*time) * -5.0, 1.3, cos(0.2*time) * -5.0);
    
    vec3 target = vec3(0.0, 1.0, 0.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    
    //---------------------------------------------------
    
    //Get the view matrix from the camera orientation
    mat3 viewMatrix = lookAt(cameraPos, target, up);
    //Transform the ray to point in the correct direction
    rayDir = viewMatrix * rayDir;
    
    vec3 floor_norm = vec3(0.0,1.0,0.0);
    
    //Find the distance to where the ray stops
    float dist = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST);
        
    vec3 position = cameraPos + rayDir * dist;
    vec3 normal = estimateNormal(position);
    vec4 col = getColour(cameraPos, rayDir, dist);
    
    //If object in scene
    if (dist < MAX_DIST - EPSILON){
        vec4 reflectedCol = reflection(position, rayDir, normal);
        float fresnel = fresnelSchlick(cameraPos, position, normal);
        col += reflectedCol * fresnel;
    }
    
    //If floor
    if(rayDir.y < -EPSILON){
        float floor_dist = distToFloor(cameraPos, rayDir, floor_norm);
        if(dist > floor_dist){
            position = cameraPos + rayDir * floor_dist;
            vec4 reflectedCol = reflection(position, rayDir, floor_norm);
            col = 0.9 * col +  0.1 * reflectedCol;
        }
    }
    glFragColor = col;
}
