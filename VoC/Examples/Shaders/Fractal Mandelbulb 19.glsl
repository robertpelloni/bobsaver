#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define V vec2(cos(r),sin(r))

float t,r,c,d,e = .005,p;
vec3 z, w, o, f;

void M() {
    d = 2.;
    z = o;
    for (int i=0; i<10; i++)
        p = pow( r = length(z), 8.),
        r < 4. ?
            d = p/r*8.*d  +2.,
            r = 8.* acos(z.z/r),
            f.xy = V,
            r = 8.* atan(z.y,z.x),
            z = p*vec3(f.y*V,f ) + o
        : z;
    r *= log(r)/d;

}

void main(void) 
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    z = vec3(resolution,0), o = z-z, r = t = 0.1 * time;
    w = vec3((U-z.xy*.5)/z.y, 1);
    w.xz *= mat2(o.zx=V,-o.x,o.z);
    o /= -.4;
    for (int i = 0; i < 90; i++) {
        M();
        c = r;
        c > e ? o += c*w : o;
    }
    o.x += e;
    M();
    O = O-O + 2.* abs( c - r ) / e ;
    glFragColor = O;
}
