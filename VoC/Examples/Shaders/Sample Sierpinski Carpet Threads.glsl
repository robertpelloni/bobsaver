#version 420

// original https://www.shadertoy.com/view/sdsXzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 draw(vec2 p, float start, float end, float iter) 
{    
    float len = end - start;
    float x = p.x - start;
    float y = p.y - start;
    float i;
    float thresh = 0.05;
    float pct = 0.;
    
   for(i=0.; i<iter+1.; i++) {
        len /= 3.;       
        float xd = mod(x/len-1.,3.);
        float yd = mod(y/len-1.,3.);
        if (xd < 1. && yd < 1.) {
            pct = (smoothstep(0.,thresh,xd) - smoothstep(1.-thresh,1.,xd))
                * (smoothstep(0.,thresh,yd) - smoothstep(1.-thresh,1.,yd));
   
            if (i>iter) {
                pct *= (1.-(i-iter));
            }
            break;
        }       
    }

    return mix(
        vec3(0,0,0),
        vec3(-cos(i), -sin(i)/2.+0.5, sin(i))/2. + 0.5,
        pct
    );    
}

void main(void)
{
    float z = (1.+cos(time/2.))/2. * 0.92 + 0.025;
    float zoom = 5.*(pow(z,3.));
    vec2 offset = vec2(0.5,0.3);
    vec3 color = vec3(0,0,0);
    float samples = 0.;
    
    for (float x=-0.33; x<0.34; x+=0.33) {
        for (float y=-0.33; y<0.34; y+=0.33) {
            vec2 p = (2.*(gl_FragCoord.xy + vec2(x,y)) - resolution.xy)/resolution.y; // [-1,1] vertically    
            p *= zoom;
            p += offset;
            color += draw(p, -1., 1., 16. - 13.*pow(z-0.05,0.25)); // if aliasing is an issue, try changing the 12. to 13. or 14.
            samples++;
        }
    }
    
    glFragColor = vec4(color/samples,1);
}
