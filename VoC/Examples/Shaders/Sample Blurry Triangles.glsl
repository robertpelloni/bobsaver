#version 420

// original https://www.shadertoy.com/view/XtScDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Blurry Triangles" by Martijn Steinrucken aka BigWings/CountFrolic - 2017
// countfrolic@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
/*

    I started playing around with triangular tiling and came up with a way to blur them.
    Perhaps it is useful to someone.
*/

#define S(a, b, t) smoothstep(a, b, t)
#define GRID 15.

#define R2 1.41421356
#define PI 3.14159265

float SimpleTriangle(vec2 uv, float w) {
    float diag = S(-w, w, uv.x-uv.y);
    float bottom = S(-w, w, uv.y);
    float right = S(w, -w, uv.x-1.);
    float top = S(w, -w, uv.y-1.);
    float left = S(-w, w, uv.x);
    
    return diag*bottom*top*left*right;
}

float Triangle(vec2 u, float w) {
    // Optimized blurred triangle. The way I got here was by writing out
    // the sum of a SimpleTriangle tile and it's 8 neighbors and then compacting and
    // throwing out stuff that doesn't contribute.
    // Still takes 7 smoothsteps, could perhaps be optimized more by exploiting 
    // symmetries. I'm sure someone will be able to reduce this further.
    // The smoothsteps catch tile edges + diagonals (centers)
    // ┌---┬---┬---┐
    // |   | F |   |
    // ├---┼-A-┼---┤
    // | K X C B F |
    // ├---┼-Y-┼---┤
    // |   | K |   |
    // └---┴---┴---┘
    float diag = u.x-u.y;
    float C = S(-w, w, diag);
    float Y = S(-w, w, u.y);
    float X = S(-w, w, u.x);
    float A = S(-w, w, u.y-1.);
    float B = S(-w, w, u.x-1.);
    float F = S(-w, w, diag-1.);
    float K = S(-w, w, diag+1.);
    
    return     X*(1.-B)*(C*Y*(1.-A) + K*A+ F*(1.-Y)) + 
            B*(C*A + F*Y*(1.-A)) + 
            ((1.-X)*(C*(1.-Y) + K*Y*(1.-A) + A));
}

void main(void)
{
    vec2 U=gl_FragCoord.xy;
    U = (U-resolution.xy*.5)/resolution.x;
    vec2 uv = U;
    
    float t = time*.2;
   
    float c = cos(t), s = sin(t);
    uv*= mat2(-c, s, s, c);
    
    
    uv *= mix(2., GRID, sin(t*.5)*.5+.5);

    c = cos(PI/4.), s = sin(PI/4.);    // rotate 45 degrees
    uv.x *= .5*sqrt(2.)*sqrt(3./4.);            // stretch so sides are of equal length
    uv *= mat2(-c, s, s, c);                    // apply rotation
    
    uv+=time;
    uv = fract(uv);
  
    //float blur = mouse*resolution.xy.y/resolution.y;
    float blur = resolution.xy.y/resolution.y;
    blur = mix(.01, .7, cos(time*2.+U.x*PI)*.5+.5);
    
    float v = Triangle(uv, blur);
    
   // v = S(.18, .2, v)*S(.82, .8, v);
    glFragColor=vec4(v);
}
