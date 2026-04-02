#version 420

// original https://www.shadertoy.com/view/MtffDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform int frames;

out vec4 glFragColor;

// An example Doyle spiral
// For nicer images see:
// http://www.josleys.com/show_gallery.php?galid=265
// For the math to get constants:
// https://bl.ocks.org/robinhouston/6096562
// This is basically just a port of the second link.

mat2 Rotate(float th) { return mat2(cos(th),-sin(th),sin(th),cos(th)); }

// Complex multiply
#define pi 3.1415926
#define cmul(a,b) mat2(a,-a.y,a.x) * b
#define cpow(a,n)  pow(length(a),n) * sin( n*atan(a.y,a.x)+vec2(pi/2.,0) )

// a^p = b^q, circles at (1,0) w/ radius r, a w/ |a|*r, b w/ |b|*r, etc.
// see diagram in pdf at first link
#define p 9
#define q 24
#define r 0.1490421
const vec2 a = vec2(1.3449103, 0.05751978);
const vec2 b = vec2(1.0750469, 0.30660765);
const float mod_a = length(a);
const vec2 a_recip5 = cpow(a, -5.);

const mat3 cols = mat3(244.,208.,12.,
                       242.,99.,95.,
                       0.,147.,209.)/255.;

void main(void) {
    float t = float(frames);
    vec2 uv = Rotate(-t * 2.*pi / 1000.)*(gl_FragCoord.xy - resolution.xy/2.);
    vec2 start = a_recip5;
    float max_d = .7*resolution.x;
    glFragColor = vec4(0.,0.,0.,1.);
    for (int i=0; i<q; i++) {          
        vec2 qvec = start;
        float mod_q = length(qvec);
        for (float j = 0.; j < 30.; j+=1.) {
            if (mod_q >= max_d) { break; }
            if (length(qvec - uv) < mod_q*r) {
                //glFragColor.xyz = cols[j%3]; // The below is for gles2 compat.
                glFragColor.xyz += float(mod(j,3.)==0.)*cols[0];
                glFragColor.xyz += float(mod(j+1.,3.)==0.)*cols[1];
                glFragColor.xyz += float(mod(j+2.,3.)==0.)*cols[2];
            }
            qvec = cmul(qvec, a);
            mod_q *= mod_a;
        }
        start = cmul(start, b);
    }
}
