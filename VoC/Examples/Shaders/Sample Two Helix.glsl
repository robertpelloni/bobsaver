#version 420

// original https://www.shadertoy.com/view/WtKGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 30.0
#define MIN_DISTANCE 0.1
#define MAX_DISTANCE 100.0
#define PI 3.14159265359

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

mat4 rotationMatrix(float angle, vec3 axis)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float map(vec3 p){
    
    float plane = p.y+2.0; //the floor

    //sphere 2 cuts out sphere 1
    float the = time*.2;
    float tha = time*.5;
    
    
    
    mat4 rMatrix1 = rotationMatrix(time,vec3(0,1,0));
    mat4 rMatrix2 = rotationMatrix(time+3.14,vec3(0,1,0));

    vec4 cyl1P = vec4(0,0,0,0);
    vec4 cyl2P = vec4(0,0,0,0);

    cyl1P.x += sin(p.y*.5)*2.0;
    cyl1P.z += cos(p.y*.5)*2.0;

    cyl1P = rMatrix1 * cyl1P;
    cyl1P.xz += p.xz;

    cyl2P.x += sin(p.y*.5) * 2.0;
    cyl2P.z += cos(p.y* .5) * 2.0;

    cyl2P = rMatrix2 * cyl2P;
    cyl2P.xz += p.xz;

    float cyl1 = sdCylinder(cyl1P.xyz + vec3(0.0,0.0,-2.0),vec2(1.0,10.));
    float cyl2 = sdCylinder(cyl2P.xyz + vec3(0,0,-2),vec2(1,10));

    float finalShape = min(cyl1, cyl2);
    return finalShape;

}

vec3 getNormal(vec3 p){
    //sampling around the point
    vec2 e = vec2(0.01, 0.0); //eplison - small offset
    float d = map(p);
    vec3 n = d - vec3(
                    map(p-e.xyy),
                    map(p-e.yxy),
                    map(p-e.yyx));
    return normalize(n);
}

float diffuseLighting(vec3 p) {
    vec3 lightPosition = vec3(3,9,-3);
    vec3 light = normalize(lightPosition - p); // normalize the vector
    vec3 normal = getNormal(p);

    float diffuse = clamp( dot(normal, light), 0., 1.); // percentage of similarity
    return diffuse;

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv = uv.st * 2.0 - 1.0 ; // 0 is the center
    
        vec3 rayOrigin = vec3(0.0, 1.0, -2.0); // change this to change the camera
    vec3 rayDirection = normalize(vec3(uv, 1.));

    float diffuse;
    float distanceOrigin = 0.0; // initial distance from cam is 0

    vec3 normal;
    // you must define a max limit for marching...
    // good upper limit is 128
    for ( int i = 0; i < 128; i++ ) {

        // start with camera origin + the incremented value, * ray Direction
        vec3 position = rayOrigin + distanceOrigin * rayDirection;
        //formula to create a sphere
        float map = map(position); // just for naming
        distanceOrigin += map; // check again after hitting the radius of the sphere

        //set the near and far clipping plane
        if (distanceOrigin < MIN_DISTANCE || distanceOrigin > MAX_DISTANCE) break;
        diffuse = diffuseLighting(position);

    }

    distanceOrigin /= 2.; // couldn't see the map, so divide by 2

    vec3 shape = vec3(1,1,1) * diffuse;
    

    vec4 color = vec4(shape,1);

    // Output to screen
    glFragColor = vec4(color);
}
