#version 420

// original https://www.shadertoy.com/view/MsyyDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SPEED 0.5
#define SHAPES 20.
#define SHARPNESS 2.5

// Multiple the result of this function call to rotate the coordinates by the given angle.
#define rotate(angle) mat2(cos(angle),-sin(angle), sin(angle),cos(angle));

void main(void)
{
    // -1 to 1
    vec2 uv = ( 2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;
    
    
    float mask = 0.;
    for (float i=0.; i < 6.; i += 1.) {
        uv *= rotate(time / 10.)
            
        float dx = length(uv.x);
        float dy = length(uv.y);

        mask += sin((dx - (time * float(SPEED))) * SHAPES) * SHARPNESS;
        mask += sin((dy - (time * float(SPEED))) * SHAPES / 2.) * SHARPNESS;

    }
    
    // Time varying pixel color
    vec3 col = vec3(mask);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
