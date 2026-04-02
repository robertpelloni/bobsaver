#version 420

// original https://www.shadertoy.com/view/DtcfRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 o = vec4(0.0);
    vec2 u = gl_FragCoord.xy;
    
    vec4 v = 16. * u.yxxy / resolution.y, i;
    
    for( o = i ; 
        i++.x < 17.; 
         v += o*i/20. -.04*(time+60.)*vec4(1,2,3,2) - v.yzwx/16.
       ) 
        o += atan(i+i*cos(i*i+length(.1*v.y+cos(i+v))))/19.;   
      
    o = 1./cosh(o*o*o*o - sin(v)/5.) ;
    
    glFragColor = o;
}