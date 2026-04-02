#version 420

// original https://www.shadertoy.com/view/Xcdyzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T (time/2e2)
#define A(v) mat2(cos((v)*3.1416 - vec4(0, 1.5708, -1.5708, 0)))  // rotate
#define H(v) (cos(((v)+.5)*6.2832 + vec3(0, 1, 2))*.5+.5)         // hue

float Q(vec3 u)  // sdf
{
    float t = T,                // speed
          l = 5.,               // loop to reduce clipping
          s = .4,               // object radius (max)
          a = 3.,               // amplitude
          r = dot(u.xy, u.xy),  // squared radius
          f = 1e20, i = 0., y, z;
    
    u.xy = vec2(atan(u.x, u.y), length(u.xy));  // polar transform
    u.x += t*133.;  // counter rotation
    
    for (; i++<l;)
    {
        vec3 p = u;
        y = round((p.y-i)/l)*l+i;         // segment y & skip rows
        p.x *= y;                         // scale x with segmented y
        p.x -= y*y*t*3.1416;              // move x (shows denominator of t)
        p.x -= round(p.x/6.2832)*6.2832;  // move x into segmented x
        p.y -= y;                         // move y into segmented y
        z = cos(y*t*6.2832)*.5+.5;        // cosine wave to match pattern
        p.z += z*a;                       // wave z
        p.z += r*.0005;                   // curve up
        f = min(f, length(p) - s*z);      // spheres
    }
    return f;
}

void main(void) //WARNING - variables void ( out vec4 C, vec2 U ) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 C = vec4(0.0);
    vec2 U = gl_FragCoord.xy;
    
    vec2 R = resolution.xy,
         m = //mouse*resolution.xy.z > 0. ?  // clicking?
             //  (mouse*resolution.xy.xy - R/2.)/R.y:  // coords from mouse
               cos(time/4. - vec2(0, 1.5708))*.3;  // coords from time
    
    vec3 o = vec3(0, -10.*sqrt(1.-abs(m.y*2.)), -90./(m.y+1.)),  // camera
         u = normalize(vec3(U - R/2., R.y)),  // 3d coords
         c = o.xxx, p;
    
    mat2 h = A(m.x/2.), // rotate horizontal
         v = A((m.y+.5)/2.);   // vertical
    
    float i = 0., d = i, s, g;
    
    for (; i++<70.;)  // raymarch
    {
        p = u*d + o;
        p.xz *= h;
        p.yz *= v;
        
        s = Q(p);  // map scene
        g = cos(round(length(p.xy))*T*6.2832)*.5+.5;  // gradient
        c += min(s, exp(-s/.05))  // black & white
           * (g+.1)               // shade
           * H(.1-g/2.)           // color
           * 5.;                  // brighten
        
        if (s < 1e-3 || d > 1e3) break;
        d += s*.7;
    }
    
    C = vec4(exp(log(c)/2.2), 1);
    
    glFragColor = C;
}