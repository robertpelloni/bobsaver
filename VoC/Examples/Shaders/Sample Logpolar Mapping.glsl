#version 420

// original https://www.shadertoy.com/view/3dSSDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define D smoothstep(3.,0., (1.-max(s.x,s.y)) / length(fwidth(p)) )
// vec3(p,cos,sin): trick to get rid of angle derivative discontinuity 
#define D smoothstep(3.,0., (1.-max(s.x,s.y)) / length(fwidth(vec3(p.x,cos(p.y),sin(p.y)))) )

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;

    O-=O;
    vec2 R = resolution.xy, 
         U = u+u-R,
         p = vec2(log(length(U)/R.y)-.3*time, atan(U.y,U.x) ),
        
    s = .5+.5*cos( 30. * p );  // log-polar grid
    O.r += D ;
    
    s = .5+.5*cos( 30. * p * mat2(1,-1,1,1) );
    O.g += D;                  // diagonals of log-polar grid

    glFragColor = O;
}
