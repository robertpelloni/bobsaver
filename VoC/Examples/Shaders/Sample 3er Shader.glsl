#version 420

// original https://www.shadertoy.com/view/sssXzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//uniform vec4 c1;

#define pi 3.14159265359

float def(vec2 uv,float f);
float def2(vec2 uv,float f);

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    
    //variable de forma
    float e =  def(uv, 0.0);
    
    float e2 = def(uv, pi/5.0);
    
    float e3 = def2(uv,pi/3.0);
    
    e3 += e2*sin(e);
    
    e += e2*sin(e3);
   // e = abs(e);
     
    //float f = sin(angulo*5.0);
    
    vec4 c1 = vec4(1.0,0.5,0.0,0.3);
    vec4 c2 = vec4(0.3,0.5,0.1,0.3);
     vec4 c3 = vec4(0.5,0.1,0.4,0.3);
    
    //c2.a es el alfa de C2, etc

// variable final    
vec4 fin = vec4(e)*c1*c1.a+ vec4(e2)*c2*c2.a+ vec4(e3)*c3*c3.a;
fin = vec4(e3)*c3*c3.a+vec4(e)*c1*c1.a;

    // Output to screen
    glFragColor = fin;
}

float def(vec2 uv, float f){

    //se define un punto
    
    vec2 p = vec2(0.5) - uv;
    //float cant = 10.0;
    float cant = 5.0;
float e = 0.0;

for (float i = 0.0; i < cant; i++) {
vec2 p = vec2(0.5,1.0/cant) - uv;
    // el angulo
    
    float angulo = atan(p.x,p.y);
    
    // el radio
    
    float rad = length(p)*1.0; 

e+= sin(rad*4.0+f+sin(angulo*3.0+time)*2.0*pi);
//e+=sin(rad*pi*cant+time+sin(angulo*50.0+sin(rad*pi*50.0))*0.5)+f;
e+= sin(e*pi)*0.2;

}

e/= cant/4.0;

//e = abs(e);
    

    //float e = sin(rad*pi*cant+time);
    
    //e = sin(rad*pi*cant+time+sin(angulo*5.0+sin(rad*pi*50.0))*0.5);
    
  //  e = sin(rad*pi*cant+time+sin(angulo*5.0)*0.5+sin(rad*pi*10.0))+f;    

return abs(e);

}

float def2(vec2 uv, float f){

    //se define un punto
    
    vec2 p = vec2(0.5) - uv;
    //float cant = 10.0;
    float cant = 5.0;
float e = 0.0;

for (float i = 0.0; i < cant; i++) {
vec2 p = vec2(0.5,1.0/cant) - uv;
    // el angulo
    
    float angulo = atan(p.x,p.y);
    
    // el radio
    
    float rad = length(p)*1.0; 

//e+= sin(rad*50.0+f+sin(angulo*3.0+time)*2.0*pi);
e+=sin(rad*pi*cant+time+sin(angulo*10.0+sin(rad*pi*50.0))*0.5)+f;
e+= sin(e*pi)*0.2;

}

e/= cant/4.0;

return abs(e);

}
