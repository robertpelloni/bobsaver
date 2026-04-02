#version 420

// original https://www.shadertoy.com/view/mtSSDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define H(a) (cos(radians(vec3(0, -60, -120))-((a)*6.2832))*.5+.5) // hue pallete
#define RT(a) mat2(cos(m.a*1.571+vec4(0,-1.571,1.571,0))) // rotate
#define G(v) H(v)*g(v) // quick grid
#define L(v) length(v) // quick radius

float g(float x) // fancy grid
{
    float l = max(0., 1.-(abs(fract(x+.5)-.5)/fwidth(x)/1.5)), // lines
          g = 1.-abs(sin(x*3.1416)), // glow
          d = min(1., 1./abs(x));    // darken
    return (l+g*.4)*d;
}

void main(void) //WARNING - variables void ( out vec4 C, in vec2 U ) need changing to glFragColor and gl_FragCoord.xy
{
	vec2 U = gl_FragCoord.xy;

    int   loop = 35; // raymarch loop
    float aa = 2.,   // 1 = off
          t = time/20.,
          d, s;
    vec2  R = resolution.xy,
          m = mouse*resolution.xy.xy/R*4.-2.,  // mouse coords
          ao;
    vec3  c = vec3(0),            // background
          o = vec3(.5, .5, t/2.), // camera
          u, p, l, v;
    
    //if (mouse*resolution.xy.z < 1.) m = vec2(0, .15); // adjust camera position
    
    for (int k = 0; k < int(aa*aa); k++) // aa loop
    {
        ao = vec2(k%2, k/2)/aa; // aa offset
        u = normalize(vec3((U-.5*R+ao)/R.y, .75)); // ray direction
        u.yz *= RT(y); // pitch
        u.xz *= RT(x); // yaw
        d = 0.;
        p *= 0.;
        for (int i = 0; i < loop; i++) // raymarch
        {
            p = o+u*d; // position along ray
            p.z += round(abs(p.y-.5)+.5)*t; // movement
            s = smoothstep(.1, .15, L(p-round(p)) ); // sphere grid
            if (s < .01) break;
            d += s;
        }
        v = vec3(d/float(loop)); // gradient of objects
        v = H(v+sin(t)*.2)*(1.-v); // color
        l = 1.-vec3( L(u.yz), L(u.xz), L(u.xy) ); // spots at xyz
        v *= max(max(l.x, l.y), l.z)*4.+.5; // contrast & highlight
        if (u.y < 0.) v += G(u.x/u.y) + G(u.z/u.y-mod(t*2., 1.)) + .1; // floor grid
        v = max(v, .4-H(-d)); // fringe color
        v += min(1., 1.-L(u.xy)*1.2)*v; // adjust brightness
        c += v;
    }
    c /= aa*aa; // fix brightness after aa
    
    glFragColor = vec4(c*c, 1);
}
