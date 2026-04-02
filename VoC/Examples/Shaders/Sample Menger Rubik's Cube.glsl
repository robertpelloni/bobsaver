#version 420

// original https://www.shadertoy.com/view/NlKGWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)          mat2(cos(a+vec4(0,11,33,0)))  // rotation
#define H(t)            fract(1e4*sin((t)*1e4))       // hash
#define B(x,y,z,r1,r2)  max( max(a.x,a.z)-r1, a.y-r2) // box
               // manage one slice, remember closest to pixel
#define S(k)   r = q - Y* .67 *float(k-1),                     \
               i%3==k ? r.xz *= rot(s*fract(T)*1.57) : U,      \
               a = abs(r), v = B(x,y,z,1.,.33),                \
               v < t ? t=v, q0 = r + Y* .67 *float(k-1) : r

void main(void)
{
	vec2 U=gl_FragCoord.xy;
	vec4 O=vec4(0.0);

    float t=9., s, v,T=time; 
    int n, i = int(18.*H(floor(T)));                  // choose the random rotation+dir
    s = i%2==0 ? 1. : -1.; i/=2;                      // direction
    
    vec3  R = vec3(resolution.xy,1.0), Y = vec3(0,1,0),
          D = normalize(vec3((U+U-R.xy)/R.y, -3.)),   // ray direction
          p = vec3(0,0,6), q,q0,r,a,                  // marching point along ray 
          M = vec3(10,12,0)/1e2*cos(time+vec3(0,11,0))+vec3(0,.12,0); 

    for ( O=vec4(1); O.x > 0. && t > .005; O-=.01 ) {
        q = p,
        q.yz *= rot(.5-6.3*M.y),                      // rotations
        q.xz *= rot(-6.3*M.x), t = 9.,
        q = i/3==1 ? q.xzy : i/3==2 ? q.yxz : q,      // choose rotation axis
        S(0), S(1), S(2),                             // draw slices + rot one
        q = q0;
        for( n=0; n<3; n++ )                          // Menger fractal recursion
            a = abs(q),
            t = max(t, -B(x,y,z,.33,3.)),             // holes in 3 directions
            t = max(t, -B(y,z,x,.33,3.)),
            t = max(t, -B(z,x,y,.33,3.)),
            q = fract( 1.5*(q+1.) )*2. - 1.;          // recursion to smaller scale

        p += .25*t*D;                                 // step forward = dist to obj
    }

	glFragColor=O;
}
