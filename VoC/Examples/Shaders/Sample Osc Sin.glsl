#version 420

// original https://www.shadertoy.com/view/tljSzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.141592653589793238
#define pi2 pi*2.0
void main(void)
{

    vec2 position = ( gl_FragCoord.xy / resolution.xy );

    float value1 = clamp(pow(1.0-abs(position.y-cos(time+cos(position.x*12.0)*2.0)/5.0-0.25),25.0)+pow(1.0-abs(position.y-0.5),25.0),0.0,1.0)
        *1.0-(abs(position.x-0.5)*2.0);
    float value2 = clamp(pow(1.0-abs(position.y-cos(time+cos(position.x*30.0)*2.0-pi/2.0)/5.0-0.5),25.0)+pow(1.0-abs(position.y-0.5),25.0),0.0,1.0)
        *1.0-(abs(position.x-0.5)*2.0);
    float value3 = clamp(pow(1.0-abs(position.y-cos(time+cos(position.x*9.0)*2.0+pi/2.0)/5.0-0.75),25.0)+pow(1.0-abs(position.y-0.5),25.0),0.0,1.0)
        *1.0-(abs(position.x-0.5)*2.0);
    glFragColor = vec4( vec3( value1,value2,value3 ), 1.0 );

}
