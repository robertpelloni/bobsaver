#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3t3yR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//modified from https://www.shadertoy.com/view/wtlcR8
void main(void) { //WARNING - variables void (out vec4 O, vec2 U) { need changing to glFragColor and gl_FragCoord.xy
    vec2 U = gl_FragCoord.xy;  
    int x = int(U),
    y = int(U.y + 30. * time),
    r = (x+y)^(y^x);
       glFragColor = vec4( abs(r*r*r)/(y+int(time*50.)) % 9970 < 1000 );
}
