#version 420

// original https://www.shadertoy.com/view/3sBBRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//The argument function takes in parameters of a+bi
//References:
//
//http://paulbourke.net/fractals/tetration/
//3Blue1Brown: https://youtu.be/elQVZLLiod4?t=2558    

#define pi 3.14159
#define CENTER vec2(1.986137,.217708)
#define LOOP 23.15

//Returns angle of p where p = p.x + p.y*i
float arg(vec2 p)
{
    return atan(p.y,p.x);
}
void main(void)
{
    float t = exp(10.*pow(sin(pi/2.*time/LOOP),2.));
    
    
    //resize window and number of iterations
    vec2 uv = 8.*((gl_FragCoord.xy-0.5*resolution.xy)/resolution.y)/t+CENTER;
    int N = 30+int(exp(4.4*pow(sin(pi/2.*time/LOOP),2.)));
    
    
    //background gradient
    vec3 col = vec3((uv.x+3.)/10.,0.4,0.5);
    
    
    //temporary variables
    vec2 p = uv;
    float c;
    float m;
    for (int i=0;i<N;i++)
    {
        //complex exponentiation
        c = pow(length(uv),p.x)*exp(-p.y*arg(uv));
        //m = p.y*log(length(uv))+p.x*arg(uv);
        m = p.y*0.5*log(dot(uv,uv))+p.x*arg(uv);
        p.x = cos(m);
        p.y = sin(m);
        p *= c;
        
        //compute color based on magnitude (This number is actually very fun to change!)
        if (length(p) > 500.)
        {
            float f = float(i)/20.;    
            col = abs(vec3((sin(f+1.57)),sin(f+0.4),sin(1.2*(f+0.5))))*0.85;          
            break;
        }
    }
    glFragColor = vec4(col,1.0);
}
