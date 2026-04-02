#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define white vec3(1.)
#define r resolution
#define t time

const float PI = 3.1415926;
const float PI2 = PI * 2.0;

void main( void ) {
    vec2 p =( gl_FragCoord.xy * 2. - resolution.xy )/min(resolution.x, resolution.y);
    float l = length(p); 
    
    float arctan =  (atan(p.y, p.x)  +  PI) / PI2;
    float wave = sin(arctan *  PI * 100.);
    
    float circle = sin(l * 300.0 - time * 10.0) * wave;
    
    vec3 destColor = vec3(circle);    
    glFragColor = vec4(destColor, 1.0);
}
