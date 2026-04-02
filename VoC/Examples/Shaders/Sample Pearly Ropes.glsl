#version 420

// original https://www.shadertoy.com/view/DtlXWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define H(a) (sin(vec3(0,1.047,2.094)+((a)*6.2832))*.5+.5) // color
#define RT(a) mat2(cos(m.a*1.571+vec4(0,-1.571,1.571,0)))   // rotate
#define Q(v) max(H(u.v-t), H(1./u.v+t)) * g(u.v, t)

// grid
float g(float x, float t)
{
    if (abs(x) < 1.) x = -1./x; // reciprocals
    return (1.-abs(sin((x-t)*3.1416))) / max(0., abs(x));
}

void main(void) //WARNING - variables void (out vec4 RGBA, in vec2 XY) need changing to glFragColor and gl_FragCoord.xy
{
	vec2 XY = gl_FragCoord.xy;
    vec3 c = vec3(0), u, v;
    vec2 R = resolution.xy,
         m = (mouse*resolution.xy.xy/R*4.)-2.,
         o;
    float p = 2., // aa pass (1=off)
          t = (time-10.)/5.,
          a, r;
    m = vec2(sin(t/2.)*.2, sin(t)*.1); // rotate with time
    
    for (int k = 0; k < int(p*p); k++) // aa loop
    {
        o = vec2(k%2, k/2)/p; // aa offset
        u = normalize(vec3((XY-.5*R+o)/R.y, 1))*8.;
        u.yz *= RT(y), // pitch
        u.xz *= RT(x); // yaw
        a = atan(u.y, u.x);
        r = length(u.xy);
        
        u.xy = tan( log(r) + vec2(a, -a*3.)/2. ); // log spirals
        v = Q(x); // set 1
        v = max(v, .5*Q(y)); // set 2
        v = min(v, H(r-t*4.) * g(r, t*4.) + .25) + pow(v, vec3(5.)); // rings
        
        c += v;
    }
    c /= p*p; // fix brightness after aa
    
    glFragColor = vec4(c+c*c*4., 1);
}
