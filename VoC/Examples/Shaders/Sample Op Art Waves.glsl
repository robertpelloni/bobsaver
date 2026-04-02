#version 420

// original https://www.shadertoy.com/view/llK3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 bipolar(vec2 p,float a, float b){
     
    float alpha = a*a - dot(p,p);
    float beta = a*a + dot(p,p);
    float gamma = sqrt(alpha*alpha - 4.0*p.y*p.y*a*a);
    float sigma = atan( 2.0*a*p.y ,alpha + b*gamma );
    float tau = 0.5*log((beta + 2.0*a*p.x)/(beta - 2.0*a*p.x));
    
    return vec2(sigma,tau);
}

void main(void)
{
    float time = time;
    vec2 p = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    //rotate
   float rotationRate = 0.3;
   float s = sin(rotationRate*time);
   float c = cos(rotationRate*time);
   p = mat2(c,s,-s,c)*p;
    
    vec2 bp = bipolar(p,0.3, 1.0 + sin(time));
    float osc = bp.x + bp.y;
    
    vec3 color = vec3(sin(15.0*osc + 10.0*time));
   
     glFragColor  = vec4(color,1.0);
}
