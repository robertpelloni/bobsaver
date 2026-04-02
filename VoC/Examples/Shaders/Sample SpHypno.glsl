#version 420

// original https://www.shadertoy.com/view/Msy3Rh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// https://oneoverzerosite.wordpress.com/
//

float SinSphereDistanceField( in vec4 sphere, in vec3 point )
{
    vec3 vDelta = sphere.xyz - point;
    float dist = dot ( vDelta, vDelta );
    dist = sqrt ( dist );
    float normalizedIn = (sphere.w - dist) / dist;
    return sin(max(normalizedIn,0.0)*3.14*0.5);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // Spheres equation: xyz as position and w as radius
    vec4 sphereR = vec4(0.0,0.0,10.0,3.0);
    vec4 sphereG = vec4(0.0,0.0,15.0,4.0);
    vec4 sphereB = vec4(0.0,0.0,18.0,4.0);
    // Spheres color
    vec3 colorR  = vec3( 0.9, 0.7, 0.0);
    vec3 colorG  = vec3( 0.5,-0.6, 0.0);
    vec3 colorB  = vec3( 0.3, 0.5, 0.0);
    
    // Compute the per pixel ray
    vec3 ray = vec3(uv*2.0-1.0,5.0); // xy from [0;1] to [-1;1], and set z to get some good lookin fov
    ray = ray * vec3(16.0,9.0,1.0);  // Preserve aspect ratio
    ray = normalize(ray);            
        
    
    // Add some random movement
    sphereR.w *= time;
    sphereG.w *= time;
    sphereG.x += sin(time*3.3)*0.2;
    sphereG.y += cos(time*3.3)*0.2;
    sphereB.w *= time;
    sphereB.y -= cos(time);
    sphereB.x += sin(time);
    
    // Ray marching
    vec3 sum = vec3(0.2,0.2,0.2);
    for (float i=0.0; i<20.0; i+=0.33)
    {
        vec3 pos = ray * i;
        sum.rgb += SinSphereDistanceField (sphereR,pos) * colorR;
        sum.rgb += SinSphereDistanceField (sphereG,pos) * colorG;
        sum.rgb += SinSphereDistanceField (sphereB,pos) * colorB;
    }
            
        
    glFragColor = vec4((sum*0.1+1.0),1.0);
    
    // Worst tone mapping ever seen
    glFragColor *= 0.33;    
}
