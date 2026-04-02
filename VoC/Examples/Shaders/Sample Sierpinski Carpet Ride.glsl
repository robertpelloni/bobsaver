#version 420

// original https://www.shadertoy.com/view/sssSRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool antialiased = false; // changing to true will drop framerate without a high-end GPU

vec3 draw(vec2 p, float start, float end, float iter) 
{     

    float len = end - start;
    float x = p.x - start;
    float y = p.y - start;
    
    float thresh = 0.03; 
    float pct = 0.;
    
    float i;
    for(i=0.; i<iter; i++) {
        len /= 3.;       
        float xd = mod(x/len-1.-20.*sin(time*0.11), 6.+5.*cos(time*0.5));
        float yd = mod(y/len-1.-4.*cos(time*0.14), 6.+5.*sin(time*0.4));
        if (xd < 1. && yd < 1.) {
            pct = (smoothstep(0.,thresh,xd) - smoothstep(1.-thresh,1.,xd))
                * (smoothstep(0.,thresh,yd) - smoothstep(1.-thresh,1.,yd));
            break;  
        }
    }
    
    return mix(vec3(0.1,0.1,0.1), vec3(1.-i/iter, 1.-i/(iter+5.), 1.), pct);    
}

void main(void)
{
    vec3 color = vec3(0,0,0);
    float samples = 0.;
    for (float x=(antialiased ? -0.33 : 0.); x<(antialiased ? 0.34 : 0.1); x+=0.33) {
        for (float y=(antialiased ? -0.33 : 0.); y<(antialiased ? 0.34 : 0.1); y+=0.33) {
            vec2 p = (2.*(gl_FragCoord.xy + vec2(x,y)) - resolution.xy)/resolution.y; // [-1,1] vertically    
            color += draw(p, -1., 1., antialiased ? 7. : 6.);
            samples++;
        }
    }
    glFragColor = vec4(color/samples,1);
}
