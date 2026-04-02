#version 420

// original https://www.shadertoy.com/view/wdGSzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI        3.14159265359

#define hue(h) clamp( abs( fract(h + vec4(3,2,1,0)/3.) * 6. - 3.) -1. , 0., 1.)

void rotate(in float angle, inout vec2 uv)
{    
    float ca = cos(angle);
    float sa = sin(angle);
    uv *= mat2(ca, -sa, sa, ca);    
}

float map(vec3 p) 
{
    return length(mod(p, 2.0) - 1.0) - 1.375;
}

vec3 getNormal(vec3 p) 
{
    float t = map(p);
    vec2 d = vec2(.5, 0.0);
    return normalize(vec3(t - map(p + d.xyy), t - map(p + d.yxy), t - map(p + d.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;
    vec2 q = gl_FragCoord.xy / resolution.xy;
    
    rotate(time*.5, uv);
    
    float tZ = (sin(time) * 0.25 + 0.5) * 0.75 + .25;

    vec3 camDir = normalize(vec3(uv*5. , 1.1));
        
    // Compute the orientation of the camera
    float yawAngle = PI * (1.2 + 0.2 * cos (time * 0.5));
    float pitchAngle = PI * (0.1 * cos (time * 0.3) - 0.05);
    
    //yawAngle += 4.0 * PI * mouse.x*resolution.xy.x / resolution.x;
    //pitchAngle += PI * 0.3 * (1.0 - mouse.y*resolution.xy.y / resolution.y);
    
    float cosYaw = cos (yawAngle);
    float sinYaw = sin (yawAngle);
    float cosPitch = cos (pitchAngle);
    float sinPitch = sin (pitchAngle);
    
    mat3 cameraOrientation;
    cameraOrientation [0] = vec3 (cosYaw, 0.0, -sinYaw);
    cameraOrientation [1] = vec3 (sinYaw * sinPitch, cosPitch, cosYaw * sinPitch);
    cameraOrientation [2] = vec3 (sinYaw * cosPitch, -sinPitch, cosYaw * cosPitch);

    camDir = cameraOrientation * camDir;
    
    vec3 camPos = vec3(1.0, 1. , - time * 3.);    
    
    float t = 0.0;
    for(int i = 0 ; i < 100; i += 1) {
        t += map(camDir * t + camPos);        
    }
    vec3 surf = camDir * t + camPos;    
    vec3 light = normalize(vec3(0.0, 0.0, 1.0)) ;
    vec3 normal = getNormal(surf);    
    
    float cg = (camDir * t).x + (camDir * t).y + (camDir * t).z;
    
    vec3 col = hue(cg*.05 - time * .2 ).rgb * clamp(dot(light, normal), .25, 1.);
        
    // Border dark
    col *= 0.2 + 0.8 * pow(32.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.3);   
    
    glFragColor = vec4(col, 1.0);
}
