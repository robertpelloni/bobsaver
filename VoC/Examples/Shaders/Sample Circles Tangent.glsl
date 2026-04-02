#version 420

// original https://www.shadertoy.com/view/md2XDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(p,r) smoothstep( 3./R.y, 0., abs( length(U-p) - r ) - .01 )

void main(void)
{
   vec2 u = gl_FragCoord.xy;
   vec4 O = vec4(0.0);
   float t=time, x,r1=1.,r2 = .5+.3*sin(t/2.), r3,a,d, i=0.;
   vec2 R = resolution.xy, 
        U = ( u+u - R ) / R.y,
       p2 = vec2(sin(t), cos(t)*sin(t/2.))  *(r1-r2);
    O *= 0.;
    
    for( ; i < 6.28; i += 6.28/20. )  // ci
    { 
       vec2 p1 = vec2(cos(i), sin(i)),
            p3 = vec2( length(p1), length(p2) );
        x = length(p2-p1);
        d = p3.y,
        
         a =  ( dot(p3, p3) - x*x )             / 2. /   p3.x,
        r3 =  ( r1*r1 + d*d - 2.*a*r1 - r2*r2 ) / 2. / ( r2 + r1 - a );
        p3 = p1 * (r1-r3);

        O += S(p3,r3);
     }
    O += S(p2,r2);
    glFragColor = O;
}
