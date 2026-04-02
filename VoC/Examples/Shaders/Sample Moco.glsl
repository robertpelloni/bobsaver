#version 420

// original https://www.shadertoy.com/view/4s3yD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159235659
float def(vec2 st,float f1);
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 st = gl_FragCoord.xy/resolution.xy;
vec2 pos=vec2(0.5)-st;
    float a=atan(pos.x,pos.y);
    float rad=length(pos);
    float time=time;
    
    float e=sin(rad*5.0*pi+sin(a*2.0)+time);
    //sin(rad*pi*5+time)*0.05;
    
    float r=def(st,e*2.0-0.2);
    float g=def(st,e+2.0);
    float b=def(st,e*2.0+0.2);
    
    vec3 c1= vec3(0.98,0.02,0.2);
    vec3 c2= vec3(0.3,0.41,0);
    vec3 c3= vec3(0.5,0.01,0.3);
    
    vec3 colfin=vec3(r*c1)+vec3(g*c2)+vec3(b*c3);
    
    glFragColor=vec4(colfin,1.0);
}

//From JPupper - Julian Daniel Puppo
float def(vec2 st,float f1){
 vec2 pos=vec2(0.5)-st;
    float a=atan(pos.x,pos.y);
    float rad=length(pos);
    float time = time;
    float f=0.0;
    //f1+=sin(sin(rad*5+sin(a*5)));
    float cant=3.0;
    st.x*=resolution.x/resolution.y;
    st=st*2.0-1.0;
    
    for (int i=0;i<=int(cant);i++){
    
    vec2 pos1=vec2(0.5,float (i)/cant)-st;
    float a1=atan(pos1.x,pos1.y);
    float rad1=length(pos1);
    
   f+=sin(rad*5.0*pi+time+sin(rad1*5.0+time+sin(rad*f1+time))/cos(f*2.0+4.0));
    f*=sin(pi/f1);
   ///sin(a1*f+time*0.2)
   //f*=length(abs(st)*f1);
    }
f*=1.0-smoothstep(f,f+0.5,rad);

return (f);
}
