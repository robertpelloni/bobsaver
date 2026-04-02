#version 420

// original https://www.shadertoy.com/view/DtscRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define H(a) (cos(vec3(0,1,2)+(a)*6.3)*.5+.5)  // hue
#define QP(v) P(u.v, l, t, R.y/1e3) * .7  // quick points

// points: xy, overlap, value, size
float P(vec2 u, float l, float t, float r)
{
    float i = 0., f = i, c = i;
    vec2 w = fwidth(u), p;
    for (; i++<l;)
    {
        p.x = round((u.x-i)/l)*l+i; // skip i rows
        f = mod(trunc(p.x)*t, 1.);  // multiply ints with value
        p.y = round(u.y-f)+f;       // set as y
        c = max(c, r/length((u.xy-p)/w));
    }
    c /= sqrt(max(1., min(abs(u.x), abs(u.y)))); // darken
    return c;
}

// grid: xy, value, scale
float G(vec2 u, float t, float s)
{
    vec2 l, g, v;
    l = max(vec2(0), 1.-abs(fract(u+.5)-.5)/fwidth(u)/1.5); // lines
    g = 1.-abs(sin(3.1416*u.xy)); // glow
    v = (l + g*.5) * max(vec2(0), 1.-abs(sin(3.1416*round(u)*t))*s); // blend
    return max(v.x, v.y);
}

void main(void)
{
    float t = time/120.,
          s = 2.+cos(t*6.2832), // scale
          l = 10.; // overlap loop (detail)
    vec2 h = vec2(2., -3.), // spiral arms
         R = resolution.xy,
         m = (mouse*resolution.xy.xy-.5*R)/R.y*4.;
    vec3 u = normalize(vec3((gl_FragCoord.xy-.5*R)/R.y, 1))*s,
         c = vec3(.1);
    //if (mouse*resolution.xy.z < 1.) m = 4.*cos(t*3.1416-vec2(0, 1.5708));
    u.xy = tan(log(length(u.xy)) - atan(u.y, u.x)*h/2.) + m*10.;
    u.z = max(u.x/u.y, u.y/u.x);
    c += QP(xy) + QP(yx) + QP(yz) + QP(zy) + QP(zx) + QP(xz);
    c += G(u.xy, t, s) * .2;
    c += H(u.z+t)*c;
    glFragColor = vec4(c*sqrt(c), 1);
}