#version 420

// original https://www.shadertoy.com/view/XlB3RV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void) {
    float pi = 3.141592653589;
    float time = time;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 gradient = vec4(uv.x,(sin((time/2.)+uv.y)/2.)+0.5,(sin(time)/2.)+0.5,1.0);
    vec2 middle = ((gl_FragCoord.xy)/(resolution.xy)-0.5);
    float a1 = length(uv - vec2(0.5) );
    float b1 = (atan(middle.x,middle.y)+3.1415925)/6.2831;
    float c1 = sin(((a1+(b1/3.18))*40.0)+(time*3.0))*10.;
    float c2 = sin(((a1+(b1/3.18))*40.0)+(time*4.0))*10.;
    float c3 = sin(((a1+(b1/3.18))*40.0)+(time*5.0))*10.;
    float d1 = sin(c1*0.2);
    float d2 = sin(c2*0.25);
    float d3 = sin(c3*0.2);
    vec3 sickspiral = vec3(d1,d2,d3);
    float uvxs = (uv.x*5.)+time+d1;
    vec3 rainbow = vec3(sin(uvxs),sin(uvxs+(pi/2.)),sin(uvxs+pi));
    glFragColor = vec4(ceil(rainbow/0.2)*0.2, 1.0 );

}
