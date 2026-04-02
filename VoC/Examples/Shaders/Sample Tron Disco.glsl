#version 420

// original https://www.shadertoy.com/view/wstGz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define DEG2RAD PI/180.

// Prevents flickering
#define SUPERSAMP 8

// Project camera to world plane with constant worldY (height)
vec3 revProject(vec2 camPos, float worldY, float fov) {
    float worldZ = worldY / (camPos.y * tan(fov*DEG2RAD*.5));
    float worldX = worldY * camPos.x / camPos.y;
    return vec3(worldX, worldY, worldZ);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    // Define supersample sizes
    float fragsize = 1. / resolution.y;
    float supersize = fragsize / float(SUPERSAMP);

    // Define the screenspace horizon [-0.5, 0.5]
    float horizonY = 0.2;
    
    // Clip above horizon (optional)
    if (p.y > horizonY) {
        glFragColor = vec4(vec3(0.), 1.0);
    }
    else {
        // Initialize current fragment intensity
        float intensity = 0.;
        // Define the current grid displacement
        vec3 displace = vec3(3.*sin(2.*PI*0.1*time), 4.*time, 1.5);
        // Define the FOV
        float fov = 90.0;
        
        // Retrieve supersamples
        for (int i = 0; i < SUPERSAMP; i++) {
            for (int j = 0; j < SUPERSAMP; j++) {
                vec2 superoffset = vec2(i,j) * supersize;
                // Get worldspace position of grid
                vec2 gridPos = revProject(p + superoffset - vec2(0., horizonY), displace.z, fov).xz;                
                // Create grid
                vec2 grid = fract(gridPos - displace.xy) - 0.5;
                // Make wavy pattern
                float pattern = 0.7+0.5*sin(gridPos.y - 6.*time);
                
                // Compute grid fade distance
                float fade = min(1.0, pow(1.1, -length(gridPos) + 10.0));
                // Compute distance from grid edge
                float dist = max(grid.x*grid.x, grid.y*grid.y);
                
                // Add bright and glowy parts of grid
                float glow = 0.15 / (1.0 - dist);
                float bright = min(2.0, 0.01 / (0.25 - dist));
                intensity += fade * pattern * (glow + bright);
            }
        }
        
        // Define current fragment color
        vec3 col = 0.5 + 0.5*cos(time+p.yxy+vec3(0,10,20));
        // Normalize intensity
        intensity /= float(SUPERSAMP*SUPERSAMP);
        
        glFragColor = vec4(intensity * col, 1.0);
    } 
}
