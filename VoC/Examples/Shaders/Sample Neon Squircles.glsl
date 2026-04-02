#version 420

// original https://www.shadertoy.com/view/mdjXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* @kishimisu - 2022 [262 chars] 
   shortened to 252 chars by @Xor in the comments!
   
   No raymarching this time as I wanted to stay
   below 300 chars, I tried to reduce the number
   of instructions to the minimum to avoid having
   a body with brackets in the for loop.
   
   The layout of the code was inspired by @Xor's 
   codegolfing shaders: for(..; ..; O.rgb += *magic*); 
*/
void main(void) {
	
	vec2 F = gl_FragCoord.xy;
    vec2 r = resolution.xy, u = (F+F-r)/r.y;    
    vec4 O=vec4(0.);
    
    for (float i; i<20.; O.rgb +=
    .004/(abs(length(u*u)-i*.04)+.005)                   // shape distance
    * (cos(i+vec3(0,1,2))+1.)                            // color
    * smoothstep(.35,.4,abs(abs(mod(time,2.)-i*.1)-1.)) // animation
    ) u*=mat2(cos((time+i++)*.03 + vec4(0,33,11,0)));   // rotation
	glFragColor=O;
}
