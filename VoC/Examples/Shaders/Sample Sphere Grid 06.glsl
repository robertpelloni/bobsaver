#version 420

// original https://www.shadertoy.com/view/Xldfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
In this program, X and Y will be the floor coords, and Z will be height.
*/

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.y /= resolution.x/resolution.y; // I know it's unorthodox to normalize this way, but it makes FOV easier
    
    ///////////////////////
    // Graphics Settings //
    ///////////////////////
    int lim = 5000;         // Maximum steps allowed
    float stp = 0.01;       // Ray step
    float FOV = 1.0;        // 1.0 = 90 Deg.
    
    
    ////////////////////
    // Initialize Ray //
    ////////////////////
    float playerDir = time / 2.0;
    float rayYaw = atan(uv.x/1.5)/FOV + playerDir;
    float rayPitch = atan(uv.y/1.5)+radians(0.0);
    vec3 rayv = vec3(sin(rayYaw),cos(rayYaw),sin(rayPitch))*vec3(stp); // Ray step in terms of XYZ
    vec3 ray = vec3(sin((playerDir+radians(90.0)))*uv.x*0.5, (cos(playerDir+radians(90.0)))*uv.x*0.5, uv.y);                                    // XYZ of ray
    //vec3 ray = vec3(0.0,0.0,0.0);
    //temporary! (Until I get distance fields and shadows working.)
        float col = 0.0;
    
    ////////////////////
    // Ray Collisions //
    ////////////////////
    
    for (int i = 0; i < lim; i++)
    {
        ray += rayv;
        if (length(vec3(mod(ray.x, 2.0)-1.0,mod(ray.y, 2.0)-1.0,mod(ray.z + time, 2.0)-1.0)) < 0.25)
        {
            col = 1.0 - float(i)/5000.0;
            if (length(vec3(mod(ray.x +0.01, 2.0)-1.0,mod(ray.y, 2.0)-1.0,mod(ray.z + time, 2.0)-1.0)) < 0.25)
            {
                col -= 0.1; //Really bad temporary shadows just to show that it is in fact a raymarcher.
            
                break;
            }
            break;
        }
    }
    glFragColor = vec4(col,col,col,1.0);
}
