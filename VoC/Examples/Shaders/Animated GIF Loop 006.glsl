// https://softologyblog.wordpress.com/2020/11/30/creating-glsl-animated-gif-loops/

#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float animationSeconds = 2.0; // how long do we want the animation to last before looping
float piTimes2 = 3.1415926536*2.0;

void main(void)
{
    //uv is pixel coordinates between -1 and +1 in the X and Y axiis with aspect ratio correction
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    // sineVal is a floating point value between 0 and 1
    // starts at 0 when time = 0 then increases to 1.0 when time is half of animationSeconds and then back to 0 when time equals animationSeconds
    float sineVal = sin(piTimes2*(time-0.75)/animationSeconds)/2.0+0.5; 

    float torus1Radius = 0.2+(1.0-sineVal)*0.4;
    vec2 torus1Center = mix(vec2(-0.8,0.0),vec2(0.8,0.0),sineVal);
    
    float torus2Radius = 0.2+(sineVal)*0.4;
    vec2 torus2Center = mix(vec2(0.8,0.0),vec2(-0.8,0.0),sineVal);
    
    float torus3Radius = 0.2+(1.0-sineVal)*0.2;
    vec2 torus3Center = vec2(0.0,0.0);
    
    float torusWidth = 0.1;
    float torusSmoothsize = 0.03;

    vec4 color = vec4(0.0); //init color variable to black

    //default pixel color is black
    color = vec4(0.0,0.0,0.0,1.0); 
    float c;
    c = smoothstep(torusWidth,torusWidth-torusSmoothsize,(abs(length(uv-torus1Center)-torus1Radius)));        
    color += vec4(c,0.0,0.0,1.0);
    c = smoothstep(torusWidth,torusWidth-torusSmoothsize,(abs(length(uv-torus2Center)-torus2Radius)));        
    color += vec4(0.0,c,0.0,1.0);
    c = smoothstep(torusWidth,torusWidth-torusSmoothsize,(abs(length(uv-torus3Center)-torus3Radius)));        
    color += vec4(0.0,0.0,c,1.0);
   
    glFragColor = color;
}
