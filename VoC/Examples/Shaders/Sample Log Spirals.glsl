#version 420

// original https://www.shadertoy.com/view/mlsSzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define H(a) (sin(vec3(0,1.047,2.094)+vec3(a*6.2832))*.5+.5) // color
#define RT(a) mat2(cos(m.a*1.5708+vec4(0,-1.5708,1.5708,0))) // rotate

void main(void) //WARNING - variables void (out vec4 RGBA, in vec2 XY) need changing to glFragColor and gl_FragCoord.xy
{
    vec3 c, u, v;
    vec2 R = resolution.xy,
         m = (mouse*resolution.xy.xy/R*4.)-2.,
         o;
    float p = 2., // aa pass (1=off)
          t = (time-10.)/5.,
          a;
    m = vec2(sin(t/2.)*.2, sin(t)*.1); // rotate with time
    
    for (int k = 0; k < int(p*p); k++) // aa loop
    {
        o = vec2(k%2, k/2)/p; // aa offset
        u = normalize(vec3((gl_FragCoord.xy-.5*R+o)/R.y, 1));
        u.yz *= RT(y), // pitch
        u.xz *= RT(x); // yaw
        
        a = atan(u.y, u.x)/2.;
        u.xy = tan(log(length(u.xy)) + vec2(a*2., -a*5.)); // form spirals
        v = min(1.-abs(sin((u-t)*3.1416)), 1./abs(u));     // gridify
        c += H(u.x-t) * min(v.x, v.y) / min(max(v.x, v.y), 1.-v.x)*.5; // colors
    }
    c /= p*p; // fix brightness after aa
    
    glFragColor = vec4(c+c*c, 1.);
}
