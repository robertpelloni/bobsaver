#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3djyWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float iterations = 20.0;
    vec3 col;
    
    for (float i = 0.0; i <= iterations; i++)
    {
        float colony = sin(uv.x+( time*0.5)+i)+(((sin(time))*0.5)+0.5);
        int x = int(i);
        if (colony >= uv.y-0.05 && colony <= uv.y+0.05 && col.x == 0.0 && col.y == 0.0 && col.z == 0.0)
        {
            if (x % 4 == 1)
            {
                col.r = 0.5;
                col.b = 0.8;
            }
            else if (x % 4 < 1)
            {
                col.b = 0.5;
                   col.g = 0.8;
            }
            else if (x % 4 > 1)
            {
                col.g = 0.5;
                col.r = 0.8;
            }
        }
        
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
