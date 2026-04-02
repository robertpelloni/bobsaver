#version 420

// original https://www.shadertoy.com/view/cd3XR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// radial variant of https://shadertoy.com/view/mdcXD7

#define rot(a)        mat2(cos(a+vec4(0,11,33,0)))         // 2D rotation 
#define rot3(P,A,a)  ( mix( A*dot(P,A), P, cos(a) ) + sin(a)*cross(P,A) ) // 3D rot around an arbitrary axis

#define d(q)  (                                                                \
        t = length(q) - 4.,                             /* sphere  */         \
        a = fract(vec3( atan((q).z,(q).x), atan((q).y,length((q).yxz)),0) /.88) - .5, \
        min(t, length(q)*length(a.xy) - 1.35)             /* radial bands */    \
     )
            
void main(void)
{
	vec4 O = vec4(0.0);
	vec2 U = gl_FragCoord.xy;

    float t=11.;
    vec3  R = vec3(resolution.xy,1.0),
          D = normalize(vec3(U+U, -3.85*R.y) - R),          // ray direction
          p = vec3(0,0,90), q,a,                           // marching point along ray 
          M = vec3(.0,.5,0) * cos(.5*time + vec3(0,11,0)); 
        p.yz *= rot(-M.y),                                 /* rotations */
        p.xz *= rot(-M.x-1.57), 
        D.yz *= rot(-M.y),
        D.xz *= rot(-M.x-1.47); 

    for ( O=vec4(1); O.x > 0. && t > .5; O-=.005 )        // march scene  
        q = rot3( p, vec3(sin(time),0,cos(time)), 14.14 *smoothstep(.0023, .099, 1./length(p)) ), 
        t = d(q),
        p += .09*t*D;                                       // step forward = dist to obj      

 // O *= O*O*2.;                                           // color scheme
    if (length(q)<1.8)                                     //   sphere
        a = cos(4.28*a), t = a.x*a.y,
        O.rgb *= .5+.5*smoothstep(1.,0.,t/fwidth(t)); 
    else
        D = vec3(-1,1,0)*1e-3,                             // efficient FD normals https://iquilezles.org/articles/normalsSDF/
        O.rgb *= .7 -.8* normalize(  D.xxy* d( q + D.xxy ) + D.xyx* d( q + D.xyx ) + D.yxx* d( q + D.yxx ) + D.yyy * d( q + D.yyy ) );

	glFragColor = O;
} 

