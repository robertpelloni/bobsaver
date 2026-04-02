#version 420

// original https://www.shadertoy.com/view/3sGyRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// height of a equilateral triangle
const float h = .5 * sqrt(3.);

void main(void) {

    vec4 o = glFragColor;

    // want a black background
    o = 0. * o;
    
    // use later for rotation
    vec2 cs = vec2(cos(time), sin(time)),
    // scale centered axes
         uv = (2.5 + 2.5 * sin(.3 * time)) * (2. * gl_FragCoord.xy / resolution.xy - 1.) * vec2(resolution.x / resolution.y, 1);
    
    // points of the triangele: a, b, c
    vec2 a = vec2(-1., -h),
         b = vec2(+1., -h),
         c = vec2(+0., +h),
    // x and y axes and center z
         x = b - a,
         y = c - a,
         z = (a + b + c) / 3.;
    
    // center all points of the triangle
    a -= z; b -=z; c -= z;
    
    // rotate the world, so the triangle rotates back
    uv *= mat2(cs.x, cs.y, -cs.y, cs.x);
    
    // trafo into triangle world
    mat2 sierpinski = inverse(mat2(x, y));
    
    // apply trafo, with point 'a' as new origin
    vec2 r = sierpinski * (uv - a);
    
    // scale factor for triangle size
    float f = 1.;
    
    // if in triangle colorize it a little bit
    if(0. <= r.x && 0. <= r.y && r.x + r.y < f) o = vec4(1. - dot(uv,uv));// + .1 *  cos(.1 * time));
        
    // divide 15 times
    for(int i = 0; i < 15; ++ i) {
        
        o.rgb -=
            // am i inside the triangle? 
            // uncomment the next line for a showing only the center triangle!
            // 0. <= r.x && 0. <= r.y && r.x + r.y < 1. &&
            // am i in the lower left part of square in sierpinski space? -----------------------------------
            (mod(r.x, f) + mod(r.y, f) < f) //                                                               |
             ? fract(mod(f, sin(.1 * time))) * vec3(r.x, r.y, 1. - r.x - r.y) //yes, so add some rgb colors |
             : vec3(0.); // no, so add nothing                                                               |
                        //                                                       ----------------------------
                       //                                                       |
        // divide the scaling factor                                            |
        f *= .5;     //                                                         |
    }               //                                                          |
    
    glFragColor = o;
}                  //                                                           |
                  //                                                            |
/*    --------------------------------------------------------------------------
     |
     V

f = .5

+ - - - - - -
+ + - - - - -
+ + + - - - -
+ + + + - - -
+ + + + + - -
+ + + + + + -
+ + + + + + +

f = .25

+ - - - - - -
+ + - - - - -
+ + + - - - -
+ - - - - - -
+ + - - + - -
+ + + - + + -
+ + + + + + +

f = .125

+ - - - - - -
+ + - - - - -
+ + + - - - -
+ - - - - - -
+ + - - + - -
+ - + - + + -
+ + + + + + +

*/
