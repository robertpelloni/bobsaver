#version 420

// original https://www.shadertoy.com/view/XtdBD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// copied and modified on top of "Sound sinus wave" https://www.shadertoy.com/view/XsX3zS

#define LIGHT_BEAMS 8.0
#define time time

void main(void)
{
     vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    uv.x *= resolution.x/resolution.y;

    vec3 color = vec3(0.0);
    
    for (float i=0.0; i<LIGHT_BEAMS; i++) {
        float freq = 1.0 + .6f * i;

        vec2 p = vec2(uv);

        p.y *= .8;
        p.y += (1.0f - 2.0f * (i/(LIGHT_BEAMS-1.0))) * (0.2 * (.5 + .5f * sin(.05 * time)));
        p.x += sin(p.y * 2.0 * (1.0f + freq + 60.0f * sin(.02*time)) + 
                   0. * time * (1.0f + 2.5f*i/LIGHT_BEAMS)) * cos(p.y * 2.0) * freq * 0.2 * ((i + 1.0) / LIGHT_BEAMS);

        
        float intensity = abs(0.02 / p.x);
        color += 5. * vec3(1.0 * intensity * (i / 5.0), 0.5 * intensity, 1.75 * intensity) * (1.0 / LIGHT_BEAMS);
    }
    
    // Output to screen
    color *= 1.0f - pow(.8 * uv.x, 2.0);
    glFragColor = vec4(color,1.0);
}
