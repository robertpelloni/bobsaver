#version 420

// original https://www.shadertoy.com/view/XlXSWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Poincaré Disk
    2015 BeyondTheStatic

    Tools for creating uniform hyperbolic tessellations, using the Poincaré disk model.
    Also supports sphere (hypobolic?) tilings.

    The tilings are defined by two values, N and P (p & q in Schläfli notation):
        N: number of polygon vertices
        P: number of polygons meeting at a vertex

    The following N:P values are equivalent to the five Platonic solids (uniform sphere tilings):
        3:3 - tetrahedron
        4:3 - cube
        3:4 - octahedron
        5:3 - dodecahedron
        3:5 - icosahedron

    The following N:P values would produce Euclidian tessellations, and are thus unsupported here:
        3:6 - triangles
        4:4 - squares
        6:3 - hexagons

    All N:P values exceeding those which produce Euclidian tilings will produce hyperbolic tilings.

    Functions:
        vec2 radialRepeat(vec2 p, vec2 o, int n)
            Repeats vector o radially about center n times. Uses p to split up space so that o can be a non-uv vector.

        vec2 cInvert(vec2 p, vec2 o, float r)
            Circle inversion of p at position o of radius r.

        vec2 cInvertMirror(vec2 p, vec2 o, float r, float flip)
            Like cInvert(), but mirrors p at radius r. Inversion inside or outside circle is determined by flip (0.0 or 1.0).

        vec4 poincareGetStuff(int n_, int p_)
            Gets the necessary data to produce the Poincaré disk model from N and P values.
            Return values:
                x: distance of circle inversion (y position)
                y: radius of circle inversion
                z: distance from center to polygon vertex
                w: which side of the circle to perform inversion (0.0 or 1.0)(added to allow sphere tilings)                

        vec2 poincareCreateUVs(in vec2 p, vec4 pI)
            Uses p and pI to produce uvs for displaying the Poincaré disk. This should be placed inside a loop somewhere.

    Additional Remarks:
        - For more info on the Poincaré disk see: https://en.wikipedia.org/wiki/Poincar%C3%A9_disk_model
        - This construction based on "The hyperbolic chamber" http://www.josleys.com/article_show.php?id=83
        - The disk can be transformed into the upper half-plane model by using a circle inversion offset by 1 unit.
        - Platonic solids can be produced by mapping sphere tilings onto a sphere, using spherical inversion. (geodesic domes possible?)
        - The poincareGetStuff() function isn't necessary if you already know what you need.
        - If anyone can provide a conformal Euclidian->hyperbolic polygon uv mapping function for this, I'd be very appreciative :)
        - "Hypobolic' should be a word.

*/

const int N        = 7;    // number of polygon vertices
const int P        = 3;    // number of polygons meeting at a vertex
const int Iters    = 9;    // number of iterations

#define HALFPI    1.57079633
#define PI        3.14159265
#define TWOPI    6.28318531
float s, c;
#define rotate(p, a) mat2(c=cos(a), s=-sin(a), -s, c) * p

vec4 poincareGetStuff(int n_, int p_) {
    float n = PI / float(n_), p = PI / float(p_);
    vec2 r1 = vec2(cos(n), -sin(n));
    vec2 r2 = vec2(cos(p+n-HALFPI), -sin(p+n-HALFPI));
    float dist = (r1.x - (r2.x/r2.y) * r1.y);
    float rad = length(vec2(dist, 0.)-r1);
    float d2 = dist*dist - rad*rad;
    float s = (d2<0. ? 1. : sqrt(d2));
    return vec4(vec3(dist, rad, 1.)/s, float(d2<0.));
}

vec2 radialRepeat(vec2 p, vec2 o, int n) {
    return rotate(vec2(o.x, o.y), floor(atan(p.x, p.y)*(float(n)/TWOPI)+.5)/(float(n)/TWOPI));
}

vec2 cInvert(vec2 p, vec2 o, float r) {
    return (p-o) * pow(r, 2.) / dot(p-o, p-o) + o;
}

vec2 cInvertMirror(vec2 p, vec2 o, float r, float flip){
    return (length(p-o)<r ^^ flip==1. ? cInvert(p, o, r) : p);
}

vec2 poincareCreateUVs(vec2 p, vec4 pI) {
    return cInvertMirror(p, radialRepeat(p, vec2(0., pI.x), N), pI.y, pI.w);
}

void main(void) {
    vec2 uv = 2. * (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    
    // animate the disk
    if(true) {
        vec2 rot = vec2(sin(.3*time), cos(.3*time));
        uv = cInvert(uv, rot, 1.);
        uv = cInvert(uv+vec2(rot.y, -rot.x), rot, 1.);
    }
    
    // get data for the disk model
    vec4 pI = poincareGetStuff(N, P);
    
    // build the disk
    for(int i=0; i<Iters; i++)
        uv = poincareCreateUVs(uv, pI);
    
    // uncomment to mirror from disk's margin
    //uv = cInvertMirror(uv, vec2(0., 0.), 1., 1.);
    
    // this is the pattern for each polygon
    float f = 1. - dot(uv, uv) / pow(pI.z, 2.);
    
    glFragColor = vec4(vec3(f)*vec3(1.7, 1.1, .8), 1.);
}
