#version 420

// original https://www.shadertoy.com/view/WtBGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    //Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    //Equalize the aspect ratio
    uv.y /= resolution.x/resolution.y;
    
    //Zoom out
    uv *= 10.0;
    
    //Add distortion
    for(float i = 1.0; i < 4.0; i+=1.0){ 
        uv.x += sin(time + uv.y * i);
        uv.y += cos(time + uv.x * i);
    }

    //Time varying pixel colour
    vec3 col = 0.5 + 0.5*cos(time + uv.xyx + vec3(0,2,4));

    //Fragment colour
    glFragColor = vec4(col,1.0);
}
