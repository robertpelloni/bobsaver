#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Mlfczf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot2(spin) mat2(sin(spin),cos(spin),-cos(spin),sin(spin))
#define pi acos(-1.0)

#define k 1.323

void main(void)
{
    vec2 centered = gl_FragCoord.xy*2.0-resolution.xy;
    vec2 uv = centered/resolution.y;
    
    float grey = 0.0;
    
    // instead of time i have pi/6.0 for a static shape
    const mat2 rot = rot2(pi/6.0);
    
    // using pow for seamless "infinite" zoom
    // it loops after 3 seconds, pow makes the zoom speed
    // seamless between loops
    float scale = 1.0/pow(k,fract(time/3.0)*6.0+3.0);
    // there is a full rotation every 6 seconds.
    
    uv *= scale*rot2(pi*time/6.0);
    int i;
    for(i = 0; i < 40; i++) {
        uv *= k * rot;
        
        if(uv.y > 1.0) {
            break;
        }
    }
    
    scale *= pow(k,float(i));
    grey = (uv.y-1.0)/scale*resolution.y/3.0;

    if (i%2 == 1) {
        grey = 1.0-grey;
    }
    
    uv /= scale;
    
    float len = dot(centered,centered);
    if (len < 20.0*20.0) {
        grey = mix(0.5,grey,sqrt(len)/20.0);
    }

    
    glFragColor = vec4(grey);
}
