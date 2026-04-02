// https://www.shadertoy.com/view/XdfGDH

#version 420

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

#define T(i,j) texture(image,gl_FragCoord.xy/resolution.xy+vec2(i,j)/resolution.xy)

void main() 
{
    vec4 O = (   T(-1,-1)+T(0,-1)+T(1,-1)
          + T(-1, 0)+T(0, 0)+T(1, 0)
          + T(-1, 1)+T(0, 1)+T(1, 1) ) / 9.;
    
    float v = sin(6.28*3.*length(O.xyz));
    
    O *= 1.-smoothstep(0.,1., .5*abs(v)/fwidth(v));
	
	glFragColor = O;
}