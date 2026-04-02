#version 420

// original https://www.shadertoy.com/view/Wsj3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define cplx vec2

cplx c_realpow(cplx z, float n) {
    float r = pow(length(z), n);
    float ntheta = n*atan(z.y,z.x);
    return r*cplx(cos(ntheta),sin(ntheta));
}

void main(void)
{
    float st = 2.*(sin(time/2.-1.57) + 1.5);
    vec2 m = 1. - mouse*resolution.xy.xy/resolution.xy;
    cplx p = 12./(st+1.)*(cplx(gl_FragCoord.xy/resolution.yy)+cplx(-1.2,-.5));

    int maxIter = int(25.*m.x);
    float thresh = 3.*m.y;
    
    cplx z = cplx(.000001, 0.);
    int i = 0;
    while (i<maxIter) {
        z = c_realpow(z, st) + p;
        if (length(z) > thresh) break;
        i++;
    }
    float c = 1. - float(i)/float(maxIter);
    glFragColor = vec4(c,c,c,1.);
}
