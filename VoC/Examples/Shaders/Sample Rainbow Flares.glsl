#version 420

// original https://www.shadertoy.com/view/fljGzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//ALL CREDIT GOES TO benoitM ON SHADERTOY - https://www.shadertoy.com/view/WtjyzR

#define NUM_LAYERS 7.
#define ITER 15

vec4 tex(vec3 p)
{
    float t = time+78.;
    vec4 o = vec4(p.xyz,3.*sin(t*.1));
    vec4 dec = vec4 (1.,.9,.1,.15) + vec4(.06*cos(t*.1),0,0,.14*cos(t*.23));
    for (int i=0 ; i++ < ITER;) o.xzyw = abs(o/dot(o,o)- dec);
    return o;
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    vec3 col = vec3(0);   
    float t= time* .1;
    
    for(float i=0.; i<=1.; i+=1./NUM_LAYERS)
    {
        float d = fract(i+t); // depth
        float s = mix(5.,.5,d); // scale
        float f = d * smoothstep(1.,.9,d); //fade
        col+= tex(vec3(uv*s,i*4.)).xyz*f;
    }
    
    col/=NUM_LAYERS;
    col*=vec3(1.5,0.75,2.25);
       col=pow(col,vec3(.5 ));  

    glFragColor = vec4(col,1.0);
}
