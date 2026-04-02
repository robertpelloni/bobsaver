#version 420

// original https://www.shadertoy.com/view/Xt2XDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor=vec4(0.0);
    
    float C,S, t=(time-11.)/1e3;
    #define rot(a) mat2(C=cos(a),S=-sin(a),-S,C)

    vec2 R = resolution.xy, p;
    vec2 Coord;
    Coord.xy = 6.3*(gl_FragCoord.xy+gl_FragCoord.xy-R)/resolution.y;
    
    #define B(k) ceil( (p=cos(Coord.xy*=rot(t))).x * p.y )  * (.5+.5*cos(k))
 
    for (float a=0.; a<6.3; a+=.1)
        glFragColor += vec4(B(a),B(a+2.1),B(a-2.1),1) / 31.;

}
