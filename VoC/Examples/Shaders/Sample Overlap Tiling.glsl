#version 420

// original https://www.shadertoy.com/view/Md2cWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Overlap Tiling
    --------------

    If I were to give this a longer descriptive title, I'd probably call it tile
    quadrant overlap flipping... which is not a catchy title either. :) I'm not 
    really sure what you'd technically call the process, but it's just some basic 
    tile flipping that you may have seen around. Fabrice Neyret makes use of it in 
    some of his examples, but this particular one was inspired by one of Cexlearning's 
    postings - I've provided the link below.

    The trick behind this is pretty simple: Partition space into a grid, then 
    subdivide the grid into quadrants. In each quadrant (top left, top right, bottom
    left, bottom right), draw two overlapping symmetrical quarter shapes - Circles are
    the most common. Randomly overlap the top one or the bottom one, depending on the 
    hash ID for that quadrant... 

    OK, this is the point where I'd have difficulty visualizing, which is why I've 
    provided a "SHOW_GRID" define below. Look at the way the shapes overlap in each
    quadrant cell. There's also a "SHOW_FLIPPED" define that displays which quadrants
    have been flipped. Hopefully, those should make the description much clearer.

    The rest is just some polar coordinate-based decoration. For anyone not familiar
    with that part of the process, it's worth taking some time out to draw something
    along the lines of a clock face with circles, squares, etc, in place of the 
    numbers.

    // A nice example - especially if you want to see a much less bloated version.
    Sketch_Discs3 - cexlearning
    https://www.shadertoy.com/view/4d2yDh
    Based on this: Keijiro - https://github.com/keijiro/ShaderSketches

*/

// A visual aid to see the overlapping shapes in each quadrant. 
//#define SHOW_GRID
// Shows which quadrants have been flipped. Only shows when "SHOW_GRID" is defined.
//#define SHOW_FLIPPED

// Gives the pattern shapes a polynomial feel. Try 3, 4, 5, 9, etc.
const float sides = 5.; 

// vec2 to float hash.
float hash21( vec2 p ){ return fract(cos(dot(p, vec2(41.31, 289.97)))*45758.5453); }

// Fabrices consice, 2D rotation formula.
mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// Drawing a shape of radius "w" with falloff factor "fo."
float ci(vec2 p, float w, float fo){
    
    p = fract(p) - .5; // Grid partition.
    float a = atan(p.y, p.x); // Used to vary the radius to give a polynomial look.
    float circ = -length(p)*(cos(a*sides)*.035 + .965) + w;     
    return smoothstep(0., fo*2.*.333/450./max(circ, 0.001), circ); // Less interference than "fwidth."
    //return smoothstep(0., fwidth(circ-.015)*2., circ-.015); 
    
}
 
// The indivdual shape gradient. Basically the same as above, but without the smoothstepping.
float ciGrad(vec2 p, float w){
    
    p = fract(p) - .5; // Grid partition. 
    float a = atan(p.y, p.x); // Used to vary the radius to give a polynomial look.
    return -length(p)*(cos(a*sides)*.035 + .965) + w;  
    
}

// The shape patterns. It's all pretty easy, but it's fiddly... which is just another way to say that
// it's really annoying to code. :) Honestly, you could pretty much ignore this.
float ciPat(vec2 p, float w, float dir){
   
    // Subdivide the grid.
    p = fract(p) - .5; 
    
    // Converting to polar coordinates:
    // r = length(p), a = atan(p.y, p.x), p = p*rot(a).
    // Ie: p.x = r*cos(a), p.y = r*sin(a).
    
    // To make this slightly more complica... interesting, I've multiplied the radius
    // by a sinusoidal term to give the circles a rounded polynomial looking shape. 
    
    
    // Some prerotation (is that a word?) for a bit of animation.
    p *= r2(time*.25*dir);
    // Matching the shape mutation.
    p *= cos((atan(p.y, p.x) + time*.25*dir)*sides)*.035 + .965;
    
    // Single center circle. Not sure why I called it "dt." ...
    // Short for dot, which is a reserves word. :)
    float dt = -length(p) + .05;
    dt = min(dt, -dt + .035);
    dt = smoothstep(0., fwidth(dt)*1., dt);

    
    // Converting the grid positions to polar coordinates, as described above.
    // The "cos" term is some aditional circle mutation. Change the global variable "sides" 
    // to something like 4 or 5, then you'll see the effect more clearly.
    float r = length(p)*(cos(atan(p.y, p.x)*sides)*.035 + .965);
    float a = atan(p.y, p.x);
    
    
    
    // Calculating the the radial centers of each cell. It's a pretty standard way to get
    // it done.
    float cellDots = 9.;
    float ia = floor(a/6.2831853*cellDots);
    ia = (ia + .5)/cellDots*6.2831853;
    
    // Converting the radial centers to their positions within the circular looking shape.
    p *= r2(ia);
    
    // Moving the points out a bit along the radial line.
    float q = p.x - .18; //fract(p.x) - .5; // Radial repetion.
    q = abs(abs(q) - .09); // Repeat trick to double up on points.
    
    // Drawing the two sets of nine dots.
    float circ = -length(vec2(q, p.y)) + .03;
    circ = min(circ, -circ + .0275);  // Taking the inner portions out to show just the outlines.
    float c = smoothstep(0., fwidth(circ)*1., circ);
    
    // Drawing the lines within the slice shapes.
    q = p.x - .27; // Radius.
    float line = -max(abs(abs(p.y) - .05) - .1/8., abs(q) - .6/8.);
    line = max(line, -max(abs(abs(p.y) - .015) - .1/8., abs(q + .1/8.) - .8/8.));
    float c1 = smoothstep(0., fwidth(line)*1., line)*.5; // Lighten the lines.
    
    // I must have had fruit on my mind with doing this, hence the "slice" name.
    // Anyway, this is the nine... abstrace fruit slice objects.
    float slice = -length(vec2(q*.8, p.y))*(cos(atan(p.y, q)*3.)*.15 + .85) + .085;
    slice = min(slice, -slice + .025); // Taking the inner chunks out to show just the outlines.
    float c2 = smoothstep(0., fwidth(slice)*1., slice);
    
    // Combining the individual elements for the overall pattern.
    return max(max(c, c2), max(c1, dt));
    
}

void main(void) {

    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    // A bit of fake screen coordinate distortion for that fish-eye look.
    uv *= sqrt(1. + dot(uv*resolution.x/resolution.y, uv)*.25);
    
    // Right to left scrolling.
    float tm = time*.25;
    // Slowing things down at larger resolutions - Based on Flockaroo's observation.
    if(resolution.x>800.) tm *= 800./resolution.x;
    uv += vec2(tm, 0);
    
    
    // Subdivding the grid. I wanted the shapes to be the same size, regardless of
    // resolution. Not sure whether that was the right choise or not. :)
    vec2 p = uv*3.5*resolution.y/450.;
    
    // The two colors. One for the top circle, and the other for the bottom. Which is top
    // and bottom, depends on the random quadrand ID.
    vec3 col1 = vec3(1);
    vec3 col2 = vec3(1);
    
    // The shape radius - relative to maximum grid width. ".5" is the maximum. In fact, I'm not
    // sure why I coded this in, because ".5" is pretty much the only setting that looks acceptable. :)
    const float w = .5;
    
    // In regards to the following mask, overlays, etc. If you just want to put a simple example
    // together without borders, decorations, etc, only one set is necessary. I could probably group
    // a few together, but the calculations are relatively cheap, so I'm leaving them in a more
    // legible state.
    
    // Inner shapes.
    float c1Inner = ci(p, w - .075, 1.);
    float c2Inner = ci(p + .5, w - .075, 1.); 
    
    // Shape borders.
    float c1Bord = ci(p, w + .025 - .075, 1.);
    float c2Bord = ci(p + .5, w + .025 - .075, 1.); 
    
    // Shadow masks.
    float c1Sh = ci(p, w + .075 - .075, 2.);
    float c2Sh = ci(p + .5, w + .075 - .075, 2.); 
    
    // Shape pattern for decoration.
    float c1Pat = ciPat(p, w - .075, 1.);
    float c2Pat = ciPat(p + .5, w - .075, -1.);
    
    // Reverse the pattern on random shapes to add a bit more variance.
    if(hash21(floor(p) + .71)>.65) c1Pat = 1. - c1Pat;
    if(hash21(floor(p + .5) + .41)>.65) c2Pat = 1. - c2Pat;

    
    // Random shape colors.
    if(hash21(floor(p) + .37)>.65) col1 *= mix(col1, vec3(.65, 1, .3), c1Inner);
    if(hash21(floor(p + .5) + .53)>.65) col2 *= mix(col2, vec3(1, .75, .65), c2Inner);
    
    
    // Applying the design pattern to the individual grid shapes.
    col1 = mix(col1, vec3(0), c1Pat*.7);
    col2 = mix(col2, vec3(0), c2Pat*.7);
 
    // Shading the grid shapes with a circular gradient.
    col1 = mix(vec3(0), col1, min(pow(ciGrad(p, w - .075)/(w - .075), 3.)*3. + .35, 1.));
    col2 = mix(vec3(0), col2, min(pow(ciGrad(p + .5, w - .075)/(w - .075), 3.)*3. + .35, 1.));
    

    // Dark borders and edges. I did this in a hurry, so there'd be a better way for sure.
    // The functions are cheap enough, so I'll leave them be, for now.
    col1 = mix(vec3(.0), col1, c1Bord);
    col2 = mix(vec3(.0), col2, c2Bord);
    col1 =  mix(col1, vec3(0), c1Bord - c1Inner);
    col2 =  mix(col2, vec3(0), c2Bord - c2Inner);  
 
     
    
    // Applying the shadow masks, according to the random quadrant ID.
    vec3 col;
    if(hash21(floor(p*2.))>.5) col = mix(col1*c1Sh, col2, c2Sh);
    else col = mix(col2*c2Sh, col1, c1Sh);
    

    
    // The grid lines, to show each quadrant. The bottom shape is either on the top or the bottom,
    // depending on the random ID for the quadrant. If you can understand that concept and know how
    // to draw circles, you can pretty much ignore this bloated example in its entirety. :)
    #ifdef SHOW_GRID
    
    vec2 ln;
    
    // Displays the flipped quadrants. Look at the shape encompassed by the red grid lines. Note that
    // the flipped quadrants are drawn on top - relative to the central shape bounded by the four 
    // quadrant grid cell. 
    #ifdef SHOW_FLIPPED
    if(hash21(floor(p*2.))>.5) col *= vec3(1., .5, 2);
    ln = abs(fract(p + .5) - .5) - 3./450.;
    col *= smoothstep(0., fwidth(ln.x), ln.x)*smoothstep(0., fwidth(ln.y), ln.y)*.9 + .1;  
    #else
    ln = abs(fract(p + .5) - .5) - 7./450.;
    col *= smoothstep(0., fwidth(ln.x), ln.x)*smoothstep(0., fwidth(ln.y), ln.y)*.9 + .1;
    ln = abs(fract(p + .5) - .5) - 2.5/450.;
    col += (1. - smoothstep(0., fwidth(ln.x), ln.x)*smoothstep(0., fwidth(ln.y), ln.y))*vec3(.5);
    #endif
    
    ln = abs(fract(p) - .5) - 8./450.;
    col *= smoothstep(0., fwidth(ln.x), ln.x)*smoothstep(0., fwidth(ln.y), ln.y)*.85 + .15;

    ln = abs(fract(p) - .5) - 2.5/450.;
    col += (1. - smoothstep(0., fwidth(ln.x), ln.x)*smoothstep(0., fwidth(ln.y), ln.y))*vec3(1, .0, .1);
    
    #endif
    
    
    // Vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125);
    // Colored varation.
    col = mix(pow(min(vec3(1.5, 1, 1)*col, 1.), vec3(1, 3, 16)), col, 
                     pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y) , .2)*.75 + .25);
    
    
    // Mild LCD overlay. It's very subtle, but it's there. :)
    vec2 rg = mix(mod(gl_FragCoord.xy, vec2(2))*col.xy, col.xy, .5);
    col = vec3(rg, col.z - mix(col.x - rg.x, col.y - rg.y, .5));
 
   
    glFragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}
