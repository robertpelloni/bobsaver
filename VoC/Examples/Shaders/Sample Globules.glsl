#version 420

// original https://www.shadertoy.com/view/wttXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
day003: Globules
29 Jan 2020

Just playing around with the smooth blending functions,
and a little bit of randomness... kinda.
Really need to work on lighting though...
*/
vec3 rotate3D(vec3 point, vec3 rotation) {
    vec3 r = rotation;
    mat3 rz = mat3(cos(r.z), -sin(r.z), 0,
                   sin(r.z),  cos(r.z), 0,
                   0,         0,        1);
    mat3 ry = mat3( cos(r.y), 0, sin(r.y),
                    0       , 1, 0       ,
                   -sin(r.y), 0, cos(r.y));
    mat3 rx = mat3(1, 0       , 0        ,
                   0, cos(r.x), -sin(r.x),
                   0, sin(r.x),  cos(r.x));
    return rx * ry * rz * point;
}

float sdfSphere(vec3 position, vec3 center, float radius) {
    return distance(position, center) - radius;
}

float sdfPlane( vec3 position, vec4 n ) {
    return dot(position, normalize(n.xyz)) + n.w;
}

float smin(float d1, float d2, float k) {
    float res = exp2( -k*d1 ) + exp2( -k*d2 );
    return -log2( res )/k;
}

float distanceField(vec3 position) {
    float d = sdfSphere(position, vec3(0.35*sin(time*0.5), 0.2*cos(time*0.8), 0.0), 0.55);
    
    vec3 moon = vec3(0.95*cos(time*0.4), 0.85*sin(time*1.4), -0.85*cos(time));
    float d1 = sdfSphere(position, moon, 0.2);
    d = smin(d, d1, 3.0);
    
    d1 = sdfSphere(position, vec3(0.95*cos(time*2.3), 0.95*sin(time*3.4), 0.95*cos(time*1.5)), 0.05);
    d = smin(d, d1, 3.0);
    
    d1 = sdfSphere(position, moon+vec3(0.35*cos(time*1.3), 0.49*sin(time*2.4), 0.35*cos(time*2.8)), 0.01);
    d = smin(d, d1, 8.0);
    
    float d2 = sdfPlane(position, vec4(0.1*sin(time*0.2), 1.0, 0.07*sin(time*0.3), 0.75+0.2*sin(time*0.3)));

    return smin(d2, d, 8.0);
}

vec3 calcNormal( vec3 p ) 
{
    // We calculate the normal by finding the gradient of the field at the
    // point that we are interested in. We can find the gradient by getting
    // the difference in field at that point and a point slighttly away from it.
    const float h = 0.0001;
    return normalize( vec3(
                           -distanceField(p)+ distanceField(p+vec3(h,0.0,0.0)),
                           -distanceField(p)+ distanceField(p+vec3(0.0,h,0.0)),
                           -distanceField(p)+ distanceField(p+vec3(0.0,0.0,h)) 
                     ));
}

float raymarch( vec3 direction, vec3 start) {
    // We need to cast out a ray in the given direction, and see which is
    // the closest object that we hit. We then move forward by that distance,
    // and continue the same process. We terminate when we hit an object
    // (distance is very small) or at some predefined distance.
    float far = 15.0;
    float d = 0.0;
    vec3 pos = start;
    for (int i=0; i<100; i++) {
        float sphereDistance = distanceField(pos);
        pos += sphereDistance*direction;

        d += sphereDistance;
        if (sphereDistance < 0.01) {
            break;
        }
        if (d > far) {
            break;
        }
    }
    return d;
}

void main(void)
{
    // Normalise and set center to origin.
    vec2 p = gl_FragCoord.xy/resolution.xy;
    p -= 0.5;
    p.y *= resolution.y/resolution.x;
    
    vec3 cameraPosition = vec3(0.0, 0.0, -6.0);
    //vec3 cameraOrientation = vec3(0.0, 0.0, 0.0);
    vec3 planePosition = vec3(p, -5.0);
    // planePosition = rotate3D(planePosition, vec3(0.0, 0.0, time));
    
    vec3 lookingDirection = (planePosition - cameraPosition);
    
    // Rotate light around origin in xz plane
    float angle = time;
    vec2 lightPos2D = mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*vec2(0.0,1.0); 
    vec3 lightPoint = normalize(vec3(1.0*sin(time*0.5), 1.0, -1.0));
    vec3 lightFacing = lightPoint - vec3(0.0);
    
    // raymarch to check for colissions.
    float dist = raymarch(lookingDirection, planePosition);
    vec3 color = vec3(0.01);
    if (dist < 15.0) {
        color = vec3(0.05, 0.105, 0.305);
        vec3 normal = calcNormal(planePosition+ dist*lookingDirection);
        float light = dot(lightFacing, normal);
        color += 0.4* smoothstep(0.3, 1.0, light);
    }
    
    // gamma correction
    color = pow( color, vec3(1.0/2.2) );
    glFragColor = vec4(color,1.0);
}
