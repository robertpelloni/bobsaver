#version 420

// original https://www.shadertoy.com/view/4lVGzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float time = time;
       float scale = ( 40.0+20.0*sin(0.3*time));
    vec2 p = scale*(gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    //rotate
    float rotationrate = 0.1;
    float s = sin(rotationrate*time);
    float c = cos(rotationrate*time);
    p = mat2(c,s,-s,c)*p;
       
    //bipolar coordinates (sigma, tau)
    float a = min(10.0,2.0*time);
    float alpha = a*a - dot(p,p);
    float beta = a*a + dot(p,p);
    float sigma = atan( 2.0*a*p.y ,alpha);
    float tau = 0.5*log((beta + 2.0*a*p.x)/(beta - 2.0*a*p.x));

    //do something funky in bipolar corrdinates
    float freq = 20.0;
    float rate = 3.0;
    vec2 osc = 0.5*(1.0 + cos(freq*vec2(sigma,tau) + rate*time)) ;
    float bipolarOscillations  = 0.5*(osc.x+osc.y);
    
    float spotPattern = pow(bipolarOscillations,2.0 + 1.5*sin(0.2*time));
    float gray = spotPattern;
    vec3 color = vec3(gray);
     glFragColor  = vec4(color,1.0);
}
