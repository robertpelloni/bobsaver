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

    float circleRadius = 0.5; //radius of circle - 0.5 = 25% of texture size (2.0) so circle will fill 50% of image
    vec2 circleCenter = vec2(-0.8,0.0); //center circle on the image
    
    float squareRadius = 0.5; //radius of circle - 0.5 = 25% of texture size (2.0) so circle will fill 50% of image
    vec2 squareCenter = vec2(0.8,0.0); //center circle on the image
    
    vec4 color = vec4(0.0); //init color variable to black

    //test if pixel is within the circle
    if (length(uv-circleCenter)<circleRadius)
    {
        color = vec4(1.0,1.0,1.0,1.0);
    } 
    //test if pixel is within the square
    else if ((abs(uv.x-squareCenter.x)<squareRadius)&&(abs(uv.y-squareCenter.y)<squareRadius))
    {
        color = vec4(1.0,1.0,1.0,1.0);
    } 
    else {
    //else pixel is the pulsating colored background
        color = vec4(uv.x,sineVal,1.0-uv.y,1.0); 
    }
   
    glFragColor = color;
}
