#version 420

// original https://www.shadertoy.com/view/7tlGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Geometric Polar Pattern
    -----------------------

    I'm sure people have seen variations on this particular faux 3D pattern all 
    over the place. Artsy folk producing tangle patterns and so forth sketch 
    these out on paper all the time.
    
    Anyway, here it is in 2D procedural form. Not a lot of effort went into it
    at all, so I'm sure there'd be better ways to get the job done. In any case,
    it works well enough and was very easy to make. In case it isn't obvious, 
    the background is partitioned into polar cells, then the stripes are rendered 
    using angular and radial coordinates. Fake shading is applied, etc, to finish 
    things off. I'll leave the shortened version to the code golfing crowd. :)
    
    By the way, you could render this pretty easily using 3D techniques too. I 
    might do that at some stage, just for the fun of it, unless someone else 
    feels like giving it a go. :)

    Related examples:

    // An unlisted bare bones polar coordinate example, for 
    // anyone who's not quite sure how the polar thing works.
    Polar Repetition - Shane
    https://www.shadertoy.com/view/wdtGDM

*/

// Number of cells. Only intergers will work properly.
#define CELL_NUM 10.

// Monochrome or alternating color.
#define MONOCHROME

// Faux sunset styled colored lighting.
#define COLORED_LIGHTING

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Repeat 2x2 hash algorithm.
vec2 hash22G(vec2 p, vec2 repScale) {

    p = mod(p, repScale);
    // Faster, but probaly doesn't disperse things as nicely as other methods.
    float n = sin(dot(p, vec2(1, 113)));
    return fract(vec2(2097152, 262144)*n)*2. - 1.;
    
    //p = fract(vec2(2097152, 262144)*n)*2. - 1.;
    //return sin(p*6.283 + time*8.);

}

// Gradient noise: Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into squares, 
// attach random 2D vectors to each of the square's four vertices, then smoothly 
// interpolate the space between them.
float gradN2D(in vec2 f, vec2 repScale){
  
   f *= repScale;
    
    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
   const vec2 e = vec2(0, 1);
   
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec2 p = floor(f);
    f -= p; // Fractional position within the cube.
    

    // Smoothing - for smooth interpolation. Use the last line see the difference.
    vec2 w = f*f*f*(f*(f*6.-15.)+10.); // Quintic smoothing. Slower and more squarish, but derivatives are smooth too.
    //vec2 w = f*f*(3. - 2.*f); // Cubic smoothing. 
    //vec2 w = f*f*f; w = ( 7. + (w - 7. ) * f ) * w; // Super smooth, but less practical.
    //vec2 w = .5 - .5*cos(f*3.14159); // Cosinusoidal smoothing.
    //vec2 w = f; // No smoothing. Gives a blocky appearance.
    
    // Smoothly interpolating between the four verticies of the square. Due to the shared vertices between
    // grid squares, the result is blending of random values throughout the 2D space. By the way, the "dot" 
    // operation makes most sense visually, but isn't the only metric possible.
    float c = mix(mix(dot(hash22G(p + e.xx, repScale), f - e.xx), dot(hash22G(p + e.yx, repScale), f - e.yx), w.x),
                  mix(dot(hash22G(p + e.xy, repScale), f - e.xy), dot(hash22G(p + e.yy, repScale), f - e.yy), w.x), w.y);
    
    // Taking the final result, and converting it to the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}

// Gradient noise fBm.
float fBm(in vec2 p, vec2 repScale){
    
    // Four layers.
    return gradN2D(p, repScale)*.57 + gradN2D(p, repScale*2.)*.28 + gradN2D(p, repScale*4.)*.15;
}

void main(void) {

    
    // Aspect correct screen coordinates.
    float iRes = resolution.y;
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
 
    // Falloff factor: Sometimes,  we might have to use "fwidth(d)," 
    // a numeric solution, or use a constant.
    float sf = 1./iRes; 
    
    // Scaling... Trivial in this case.
    vec2 p = uv - vec2(-1./4., -1./16.) - vec2(cos(time/4.)/12., sin(time/3.)/16.);
    
     
    // Canvas rotation.
    p *= r2(-time/16.);
    
    // Slight noise coordinate perturbation for that sketchy look.
    p += (vec2(gradN2D(p, vec2(40)), gradN2D(p + .36, vec2(40))) - .5)*.005;
    
    
    // Background noise to be mixed in later.
    float ns = fBm(p, vec2(128));
    
    // Polar angle.
    float a = atan(p.y, p.x);
    
    
    // Partitioning the angle into the number of cells.
    float ia = floor(a/6.2831853*CELL_NUM);
 
    
    // Variable to determine alternate cells... Only useful for even cell numbers.
    float dir = mod(ia, 2.)<.5? -1. : 1.;

    
    // Converting square coordinates to polar ones. I.e. Angular and radial.
    p *= r2(a);
    // Above is equivalent to:
    //p = vec2(p.x*cos(ia) + p.y*sin(ia), p.y*cos(ia) - p.x*sin(ia));
    

    // RENDERING  

    
    // Used for things like shading.
    float sinFunc = sin(a*CELL_NUM/2.);
    
    // Radial rings.
    const float rNum = 5.;
    float wf = dir<0.? .1 : .05; // Ring warp factor.
    //
    // Cell stripes: There'd be other ways to do this, but this works well enough.
    float ring = mod(p.x + sinFunc*length(p)*wf + .25/rNum*dir, 1./rNum) - 1./rNum/2.;
    ring = abs(ring) - 1./rNum/4.;//*min(.65 + length(p)*.4, 1.5);
    
    
    // Alternate cell shading.
    vec3 col1 = vec3(1, .95, .9)/6., col2 = vec3(1, .95, .9);
    //
    // Black and white, or is it white and black? :)
    if(dir>0.) {
        col1 = vec3(1, .95, .9)/8.;
        #ifdef MONOCHROME
        col2 = vec3(1, .95, .9);
        #else
        col2 = mix(vec3(1, .3, .2), vec3(.3, .4, 1), p.x);
        #endif
    }

    
    // Rendering alternating stripes.
    vec3 col = mix(col1, vec3(0),  (1. - smoothstep(0., sf*16., ring - .005))*.7);
    col = mix(col, col2*1.5,  1. - smoothstep(0., sf*2., ring));
    col = mix(col, col2,  1. - smoothstep(0., sf*2., ring + .008));
    
    // Tweaking.
    col = col*.92 + .03;
    
    
    // Angular shading between cells to give a fake rounded appearance.
    col *= smoothstep(0., .25, abs(sinFunc));
    col *= smoothstep(0., 1., abs(sinFunc))*.9 + .1;

    // Polar noise.
    vec2 pol = vec2(a/6.2831*32. - time/18., p.x*2.);
    float pns = fBm(pol, vec2(32., 4));
    pns = smoothstep(0., .05/clamp(length(p), .001, .5), pns - .49); 
    //
    // Using the polar noise to put dark sketch noise at the cell edges and 
    // white in the centers.
    col = mix(col, max(col - pns, 0.), 1. - smoothstep(0., 1., abs(sinFunc)));
    col = mix(col, col + col*pns*2., 1. - smoothstep(0., .1, 1. - abs(sinFunc)));
    
    // More overall gradient FBM noise.
    col *= smoothstep(0., .85, ns) + .4;
   
    // Extra coloring.
    col *= vec3(1, .98, .95);
    #ifdef COLORED_LIGHTING
    // Colored blue and orange angular shading for the fake environmental sunset look.
    col *= mix(vec3(.3, .6, 1), vec3(1, .5, .2), sin(a*CELL_NUM - .7))*.7 + .4;
    #endif
    
    // Subtle vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.) + .05;
    // Colored variation.
    //col = mix(col.xzy, col, pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125));

    
    
    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
