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

    float circle1Radius = 0.2+(1.0-sineVal)*0.2; //radius of circle
    vec2 circle1Center = mix(vec2(-0.8,0.0),vec2(0.8,0.0),sineVal);
    
    float circle2Radius = 0.2+(sineVal)*0.2; //radius of circle
    vec2 circle2Center = mix(vec2(0.0,-0.8),vec2(0.0,0.8),sineVal);
    
    float circle3Radius = 0.2+(1.0-sineVal)*0.2; //radius of circle
    vec2 circle3Center = mix(vec2(-0.8,-0.55),vec2(0.8,0.8),sineVal);
    
    vec4 color = vec4(0.0); //init color variable to black

    //default pixel color is black
    color = vec4(0.0,0.0,0.0,1.0); 
    //test if pixel is within the circle
    if (length(uv-circle1Center)<circle1Radius)
    {
        color += vec4(1.0,0.0,0.0,1.0);
    } 
    if (length(uv-circle2Center)<circle2Radius)
    {
        color += vec4(0.0,0.0,1.0,1.0);
    } 
    if (length(uv-circle3Center)<circle3Radius)
    {
        color += vec4(0.0,1.0,0.0,1.0);
    } 
   
    glFragColor = color;
}
