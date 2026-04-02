#version 420

// original https://www.shadertoy.com/view/ss2BDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S smoothstep

void main(void)
{
	vec2 u = gl_FragCoord.xy;
    vec2  R = resolution.xy,
          U = ( 2.*u - R ) / R.y;
         
    float t = -2.*time, l = length(U), 
          a = fract( (t-atan(U.y,U.x))/6.283+.42  ), b,
          v = U.y                                           // background deformation
              + .16 * S(.2, 0., abs(l-.6)-.02 ) 
                    * S( 0.,.9, a ) * S( 1.,.9, a );
    v = sin(120.*v);
    U += .6*vec2(cos(t),sin(t)); U /= .17;                  // ball
    b = asin(U.y), a = acos( U.x/cos(b) );                  // sphere coordinates
  //  if ( !isnan(a+b) ) 
    { 
        vec3 P = vec3(cos(b)*cos(a), cos(b)*sin(a), sin(b));
        t = .2+.8*max(0.,dot(P,vec3(.58)));                 // ball shading (as is, could be alot simpler )
     // t = sin(b*10.)*sin(a*40.-t); t /= (1e-5+fwidth(t)); // ball texture. ?rolling rotation
    } 
    glFragColor = vec4( mix( .5+.5*v/fwidth(v),
                 // min(1.,.5+.5*v/fwidth(v)) * (.5+.5*S(0.,.6,length(U)-.8)), // with shadow
                   t, 
                   S(3./R.y/.17,0.,length(U)-1.)) ); // compose
}
