#version 420

//by mumumusuc 20181108

#define SIZE     0.2
#define A     vec2(-0.1)
#define B     vec2( 0.1)
#define C     vec2(-0.1, 0.5)
#define COLOR_A vec3( 1.0, 0.0, 0.0)
#define COLOR_B vec3( 0.0, 1.0, 0.0)
#define COLOR_C vec3( 0.0, 0.0, 1.0)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 r = resolution/resolution.y;
    vec2 pos = (gl_FragCoord.xy / resolution * 2.0 - 1.0) * r;
    vec2 touch = (mouse*2.0 - 1.0) * r;
    
    vec3 color = vec3(0.0);
    float colorA = SIZE/distance(pos,A+vec2(+cos(time),+sin(time))*0.2);
    float colorB = SIZE/distance(pos,B+vec2(-cos(time),-sin(time))*0.2);
    float colorC = SIZE/distance(pos,touch);
    
    float value = step(2.5,colorA+colorB+colorC);
    
    color += mix(color,colorA * COLOR_A, 0.5)*value;
    color += mix(color,colorB * COLOR_B, 0.5)*value;
    color += mix(color,colorC * COLOR_C, 0.5)*value;

    glFragColor = vec4(color, 1.0);
}
