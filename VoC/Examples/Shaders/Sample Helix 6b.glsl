#version 420

// original https://www.shadertoy.com/view/ldtfDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// variant of https://shadertoy.com/view/lsdfD8

void main(void) {
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    float T = (time-4.), t=1.,l,a,d,v, ds = 1.,  // ds=.5 for better look
          r0 = 200., r1 = 20., n = 3.82,       // n = 24/2pi
          A = 2.38, H = 4.*cos(A/2.);
    mat2  R = mat2( sin(T/4.+vec4(0,33,11,0)) );  
    vec3  q = vec3(resolution.xy,0.0),
          D = normalize(vec3(.3*(U+U-q.xy)/q.y, -1)).zxy,  // ray direction
          c, p // = 30./q;                     // marching point along ray 
               = vec3(-30.*(T/2.-2.),-2,-15.); D.yz*=R;

    O-=O;
    for ( O++; O.x > 0. && t > .01 ; O-=.015*ds )
        q = p, //q.xz *= R, q.yz *= R,         // rotation (could be factored out loop on p,D)

        c = q, c.z += r0, a = atan(c.y,c.z), 
        a += .02*sin(5.*T+7.*a),
        //q.x += 10.*sin(2.*T+q.x/200.), 
        q.z = length(c.zy)-r0, q.y = r0*a, q.x = mod(q.x-a*r0/6.3,r0)-r0/2.,// large helix
        q.z += 10.*sin(2.*T+3.*a), 
        c = q, c.x += r1, a = atan(c.z,c.x), 
        a += .05*sin(5.*T+3.*a),
        q.x = length(c.xz)-r1, q.z = r1*a, q.y = mod(q.y-a*r1/6.3,r1)-r1/2.,// medium helix
        q.z += .3*sin(10.*T+a), 

        l = length(q.xy), a = atan(q.y,q.x), 
        a += .2*sin(3.*T+q.z)
          + .05*sin(30.*T+3.*a),
        d = a-q.z,
        d = min( abs( mod(d  ,6.28) -3.14), 
                 abs( mod(d-A,6.28) -3.14) ),  // double strand (~2pi/3)
        t = length( vec3( l-4., d, fract(n*a)-.5 ) ) - .3, // spheres along spring
        d = a - round(q.z*n)/n -A/2. -3.14 +.5/n,
        d = ( length(vec2( (fract(q.z*n-.5)-.5)/n, l*cos(d)-H ))-.05 )/n, //rods
        t = min( t, v=max(l-4.,d) ),           // bounded rods
        p += ds*t*D;                           // step forward = dist to obj

    if (t==v) O.rg *= .9; else O.gb *= .9;     // colored rods vs spheres
    glFragColor = O;
}
