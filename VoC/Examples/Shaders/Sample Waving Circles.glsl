#version 420

// original https://www.shadertoy.com/view/XtjSzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shader by Vamoss
// 17/09/2015
// Reference image
// http://beesandbombs.tumblr.com/image/121790476454

#define TWO_PI 6.28318530718

//  Function from Iñigo Quiles 
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0, 
                     0.0, 
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 getColor(in float angle){
     // Map the angle (-PI to PI) to the Hue (from 0 to 1)
    return hsb2rgb(vec3(angle,1.0,1.0));   
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    
    float radius = 0.3;
    
    //tile
    vec2 frequency = vec2(22.0, 12.0);
    vec2 index = floor(frequency * st)/frequency;
    float centerDist = 1.0-length(index-0.5);
    vec2 nearest = 2.0 * fract(frequency * st) - 1.0;
    
    //movement
    float velocity = 5.0;
    nearest.x += cos(time * velocity + centerDist * TWO_PI)*(1.0-radius);
    nearest.y += sin(time * velocity + centerDist * TWO_PI)*(1.0-radius);
    
    //circle
    float dist = length(nearest);
    float circle = step(radius, dist);
    
    //colors
    vec3 bgColor = vec3(0.0, 0.0, 0.0);
    
    float colorAngle = time + centerDist * 2.0;
    vec3 circleColor = getColor(colorAngle);
    
    vec3 color = mix(circleColor, bgColor, circle);
    
    glFragColor = vec4(color, 1.0);
    //glFragColor = vec4(vec3(centerDist), 1.0);
}
