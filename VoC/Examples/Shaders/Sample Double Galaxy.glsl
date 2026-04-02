#version 420

// original https://www.shadertoy.com/view/MltXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: blackpolygon
// Title:  Double Galaxy

// Based on 'Audio Eclipse' by airtight
// https://www.shadertoy.com/view/MdsXWM

const float dots = 500.; 
float radius = 0.0025; 
const float brightness = 0.0003;

//convert HSV to RGB
vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}
        

void main(void)
{
    vec2 st=(gl_FragCoord.xy-.5*resolution.xy)/min(resolution.x,resolution.y);
    vec3 c=vec3(0.0);
    
    st = rotate2d( sin(time/5.)*3.14 ) * st;
    float b1a0 = 0.5+sin(time)*0.5;
    float b1a02 = 0.5+cos(time)*0.5;
    float ra =  (0.5+sin(time/3.)*0.3)*0.002;
    
    //inner
    for(float i=0.;i<dots/2.; i++){
            
        radius +=ra;
        
        //get location of dot
        float x = radius*cos(2.*3.14*float(i)/(dots/(15.+b1a0)));
        float y = radius*sin(2.*3.14*float(i)/(dots/(14. +b1a02)));
        vec2 o = vec2(x,y);
        
        //get color of dot based on its index in the 
        //circle + time to rotate colors
        vec3 dotCol = hsv2rgb(vec3((i + time*5.)/ (dots/14.),1.,1.0));
        
        //get brightness of this pixel based on distance to dot
        c += brightness/(length(st-o))*dotCol;
    }
    
    //outer
    for(float i=0.;i<dots; i++){
        radius += ra;
        float y = radius*cos(2.*3.14*float(i)/(dots/(10.+b1a0)));
        float x = radius*sin(2.*3.14*float(i)/(dots/(10. +b1a02)));
        vec2 o = vec2(x,y);
        vec3 dotCol = hsv2rgb(vec3((i + time*5.)/ (dots/10.),1.,1.0));
        c += brightness/(length(st-o))*dotCol;
    }
     
    glFragColor = vec4(c,1);
}
