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

    //shade pixels across the image depending on their X and Y coordinates - animated using sineVal
    glFragColor = vec4(gl_FragCoord.x/resolution.x,sineVal,1.0-gl_FragCoord.y/resolution.y,1.0);
}
