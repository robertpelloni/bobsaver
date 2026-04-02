#version 420

// original https://www.shadertoy.com/view/MtVXzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor=vec4(0.0);
    float w , y=0.0;
    vec2 R = resolution.xy;
    vec2 U;
    R = vec2( length( U= (gl_FragCoord.xy+gl_FragCoord.xy-R)/R.y )*22.-16.6, -1. );  // circle
    
    for (int i=0; i<5; i++)
        abs(w=20.*U.x-4.) < 1.  &&  abs(y=U.y) < .75  &&  ( abs(y) >.4 ? w>R.x: y>R.y )
            ?  R = vec2( w, y )  :  U,  
        U *= mat2(.31,-.95,.95,.31);
    glFragColor += 3.-3.*abs(R.x) -glFragColor; 
}

