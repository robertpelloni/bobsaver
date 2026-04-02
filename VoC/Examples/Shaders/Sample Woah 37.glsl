#version 420

// original https://www.shadertoy.com/view/msd3Rj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv*=time/10.0;
    uv = vec2(atan(uv.x, uv.y)/acos(0.0), length(uv));
    
    uv+=fract(time/20.0);
    
    float c;
    if(fract(uv.x*20.0)>0.5)
    {
        c = 0.0;
        if(fract(uv.y*20.0)>0.5)
        {
            c = 1.0;
        }
    }
    else
    {
        c = 1.0;
        if(fract(uv.y*20.0)>0.5)
        {
            c = 0.0;
        }
    }

    // Time varying pixel color
    vec3 col = vec3(c);
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
