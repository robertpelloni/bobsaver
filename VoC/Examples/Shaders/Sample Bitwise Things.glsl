#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/fs23zV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Saw tweet https://twitter.com/aemkei/status/1378106731386040322, got curious

void main(void)
{

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec2 glFragCoord=gl_FragCoord.xy;
    
    glFragCoord.xy *= 0.2;
    glFragCoord.xy += time * 10.0;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    int x = int(glFragCoord.xy.x);
    int y = int(glFragCoord.xy.y);
    
    int on = 1;
    
    int intTime = int(time);
    int cycle = intTime % 16;
    
    if (uv.x < .5f && uv.y < .5f) {
        on = (x | y) % cycle;
    } else if (uv.x < .5f) {
        on = (x ^ y) % cycle;
    }
    else if (uv.y < .5f) {
        on = (x * y) & (1 << cycle);
    }
    else {
        on = (x ^ y) & cycle;
    }
    
    // Output to screen
    glFragColor = vec4(col * float(on), 1.0);
}
