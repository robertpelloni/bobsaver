#version 420

// original https://www.shadertoy.com/view/wlKGDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITER 100.

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t = pow(1.2,time)-1.;
    float pi = 3.1416;
    float tou = 6.2832;
    vec2 c = uv*2.;
    vec2 z = vec2(0.);
    float iter = 0.;
    
    
    for(float i=0.; i<MAX_ITER; i++) {
        z = vec2(pow(z.x, 2.) - pow(z.y, 2.), 2.*z.x*z.y) + c;
        
        if(length(z)>t) break;
        
        iter++;
    }
    
    float f = iter/MAX_ITER;
    float h = sin(t/f*(fract(t+atan(z.x,z.y)/tou)/length(z)));
    

    vec3 col = vec3(h);
    glFragColor = vec4(col,1.0);
}
