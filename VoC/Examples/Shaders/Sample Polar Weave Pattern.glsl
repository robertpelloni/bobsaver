#version 420

// original https://www.shadertoy.com/view/3ljfR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Polar Weave Pattern
    -------------------

    One of my favorite nerd related hobbies is to recreate a simple 
    pattern I've come across on the internet. If I really feel like 
    geeking out, I'll render the exact pattern using several different 
    approaches. :)
    
    Anyway, this particular pattern and its derivatives are all over 
    the net, and although I couldn't find any, there are probably 
    examples on here too. There are several ways to produce it. In this 
    case, I'm minimizing rendering calls by using a single pass repeat 
    polar approach, which means no neighboring cells need be considered. 

    It took me longer to put together than I anticipated, but the idea 
    is pretty simple: Partition space into repeat polar cells, then 
    render two circular arcs on each cell edge with radii such that 
    their edges completely overlap. This will result in what look like 
    a bunch of overlapping circles. The final step is to flip the 
    bottom half of each cell to produce a weave.

    Related examples:

    // When Fabrice first posted these, I wasted way too much
    // time playing around with the code. :)
    rosace 3c - FabriceNeyret2
    https://www.shadertoy.com/view/Ms3SzB

    // Related in the sense that it uses polar coordinates only,
    // but it's really cool, so I included it anyway. :)
    Rose - Dave_Hoskins
    https://www.shadertoy.com/view/ldBGDh

    // An unlisted bare bones polar coordinate example, for 
    // anyone who's not quite sure how the polar thing works.
    Polar Repetition - Shane
    https://www.shadertoy.com/view/wdtGDM

*/

// Display the radial cell boundaries on the background.
//#define SHOW_CELLS

// Adds the weave effect: If you comment in the SHOW_CELLS define
// above, then scroll down to the WEAVE define, you'll see that it 
// involves a very simple trick.
#define WEAVE

// Random ordering. I prefer the ordered look, but the option
// is here to show it can be done. The pattern changes every two
// seconds. By the way, this can occasionally produce discontinous
// results when using odd cell numbers... which I'll fix later. 
//#define RANDOM_ORDER

// Number of cells: Integers between 4 and 10 work. Beyond that,
// some tweaking will be necessary. Interestingly, odd numbers will
// produce a single weave, whereas even numbers will produce two
// separate interlocked weaves.
#define CELL_NUM 8.

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Hacky globals, put in as an afterthought. Struct containers are tidier, but 
// sometimes they can be even less readable. In addition, WebGL can throw all
// kinds of errors when you're trying to used them inside raymarching loops,
// which can be extra annoying.
//
// Anyway, there's an alternate cell variable and edge width. The vec2 is a 
// global local cell coordinate variable, which is kind of a contradiction 
// in terms. :)
float gDir, gEw;
vec2 gP;

vec4 dist(vec2 p){
    
    // Rotation performed here.
    p *= r2(-time/2.);
    
    
    // Polar angle.
    float a = atan(p.y, p.x);
    
    // Number of cells.
    const float aNum = CELL_NUM;
    
    // Partitioning the angle into "aNum" cells.
    float ia = floor(a/6.2831853*aNum);
 
    // Used to generate a random number for each cell, and consequently,
    // a random rendering order.
    float svIA = ia;
    
    // Variable to determine alternate cells... Only useful for even cell numbers.
    float dir = mod(ia, 2.)<.5? -1. : 1.;
    
    
    // Centering and converting back to radians... If you do this often enough,
    // it'll become second nature.
    ia = (ia + .5)/aNum*6.2831853;
    
    // Converting the radial centers to their positions.
    p *= r2(ia);
    // Above is equivalent to:
    //p = vec2(p.x*cos(ia) + p.y*sin(ia), p.y*cos(ia) - p.x*sin(ia));

    // Hacky global coordinate save.
    gP = p;
    
    
    // Producing the objects: In this case, two circles at the mid edges of each cell.

    
    // Setting the radial distance: We achive this by setting one of the polar 
    // coordinates to this value, which effectively moves the points out a bit along 
    // the radial line. If you didn't perform this, all objects would be superimposed 
    // on one another in the center. Repeat radial coordinates are possible too.
    const float rad = .265;
  
    #ifdef WEAVE
    // This is the trick you use to turn circles into a weave. It's very simple, but it
    // took me a while to figure out. Simply reverse the rendering order of the circles
    // on the bottom half of each cell. Just remember that the X and Y vector positions
    // (selected members, or whatever they're called) represent the polar coordinates of 
    // the cell. The don't literally mean X and Y... I've been doing this stuff for years 
    // and I still make that mistake. :) Anyway, the easiest way to see how it works is
    // to comment the line out, then comment it back in again.
    //
    // The halfway point on the cell edge occurs at the apothem, which is the radial
    // distance multiplied by the cosine expression below... and I knew this because 
    // I'm a good guesser. :D Seriously though, look at the geometry of a regular 
    // polygon, and the following should make sense.
    if(p.x<rad*cos(3.14159/aNum)) p.y = -p.y;  
    #endif
  
    
    // Far left and right sides of the cells. Each point is rotated back half a 
    // cell, then edged out by the radial distance... Polar coordinate stuff... You get 
    // used to it after a while... Kind of. :D
    vec2 p1 = p*r2(-3.14159/aNum) - vec2(rad, 0);
    vec2 p2 = p*r2(3.14159/aNum) - vec2(rad, 0);

    
    
    // The arc radius should be half the cell width, or half the side length of the  
    // regular polygon that the pattern is based on... I think this is right, but I was 
    // in a hurry, so if you have time, I'd double check it. It seems to work visually 
    // though, so that's a good sign. :)
    float offs = rad*sin(3.14159/aNum);
    
    
    // Two circles. We're rendering one over the other, so we need a distance for each.
    vec2 d = vec2(length(p1), length(p2)) - offs;

    // The polar angle for respective positions on each circle. If you're doing stuff
    // with circles, you'll want angles. In this case, they're being used to light up
    // different parts of the circles.
    vec2 ang = vec2(atan(p1.y, p1.x), atan(p2.y, p2.x));
    
    // Turning circles into arcs -- It's a standard CSG move. The centeral arc line
    // will occur at the original outer circle radius. Because of the absolute 
    // function, the width will be double, so you just halve what you want it to be.
    const float ew = rad/2.; // Arc width. 
    d = abs(d) - ew/2.; // Arc.
    
    
    #ifdef RANDOM_ORDER
    // Random rendering order, arranged to change every two seconds.
    if(fract(sin(svIA + floor(time/2. + 37.)*.083)*45758.5453)<.5) {
        d = d.yx;
        ang = ang.yx;
    }
    #endif

    // Save the alternate cell and edge width for use outside the function.
    gDir = dir;
    gEw = ew;
    
    
    // Returning the two arc distances and their respective angles.
    return vec4(d, ang);
    
}

void main(void) {

    
    // Aspect correct screen coordinates.
    float iRes = resolution.y; // min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
 
   
    // Scaling... Trivial in this case.
    vec2 p = uv;
    
     // Falloff factor: Sometimes,  we might have to use "fwidth(d)," 
    // a numeric solution, or use a constant.
    float sf = 2.5/iRes; 
    
    // Taking two samples.
    //
    // Drop shadow fields and angles.
    vec4 dSh = dist(p - normalize(vec2(-1.5, -1))*.03);
    // Distance fields and angles.
    vec4 d = dist(p);
    
    // Distance field angles.
    vec2 ang = d.zw;
    

    // RENDERING 
    
    // Producing two line patterns.
    //
    // Multiple dark lines for that cliche record look. The expression, 
    // "abs(fract(x*N - shift) - .5)," is a repeat triangle formula of sorts and 
    // useful when you want to produce repeat edge lines... There are heaps of 
    // other ways to produce concentric lines, but I find it's the most reliable.
    //
    const float lnN = 8.; // Number of concentric pattern lines.
    vec2 pat = abs(fract(d.xy/gEw*lnN - .5) - .5)*2. - .07;
    pat = smoothstep(0., sf/gEw*lnN, pat);
    // The darkish outer arc lines.
    vec2 pat2 = abs(fract(d.xy/gEw/2. - .5) - .5)*2. - 1./lnN;
    pat2 = smoothstep(0., sf/gEw/2., pat2);
    
    // Lighting: Using the respective arc angles to add or take away light from
    // the surface. The light and darker sections add to the illusion. The numbers
    // themselves are a bit of science mixed in with trial and error.
    vec2 shad;
    shad.x = clamp((cos(ang.x*1.8))*1.35, 0., 1.);
    shad.y = clamp((1. - cos(ang.y*1.6))*1.25, 1., 2.);
    shad = shad*.5 + .5;
  
    
    // Background: Very simple, but you can make it more elaborate.
    vec3 bg = mix(vec3(1, .9, .5), vec3(1, .85, .8), uv.y*.5 + .5)*(1. - length(uv)*.35);
    
    
    #ifdef SHOW_CELLS 
    // Display the radial cell boundaries on the background. Seeing each 
    // individual cell pattern can be helpful for debug purposes.
    float ln = min(abs(r2(-3.14159/CELL_NUM)*gP).y, abs(r2(3.14159/CELL_NUM)*gP).y);
    bg = mix(bg, bg*1.7, 1. - smoothstep(0., sf*CELL_NUM/6.2831, ln*CELL_NUM/6.2831 - .003));
    bg = mix(bg, bg/12., 1. - smoothstep(0., sf*CELL_NUM/6.2831, ln*CELL_NUM/6.2831 - .0007));
    // Alternate cell shading for even cell numbers. When the number is odd, alternate
    // cell coloring doesn't really make sense.
    if(mod(CELL_NUM, 2.)<.5 && gDir<0.) bg = mix(bg, bg.zzz, .25);
    else bg = bg = mix(bg, bg.xxx, .25);
    #endif 
    
     
    // Setting the scene color to that of the background.
    vec3 col = bg;
    
    // Drop shadows and arc edge shadows for that fake ambient occlusion look
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., min(dSh.x, dSh.y)))*.25);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., min(d.x, d.y)))*.25);
    
    // The ring colors. We're using the same color for each, but different colors
    // are possible.
    vec3 col1 = vec3(.62, .6, .58);
    vec3 col2 = col1;
    
    /*
    // If using different ring colors, alternate cells need to be swapped, but
    /// we're not, so it doesn't matter.
    if(gDir<0.) {
        vec3 tmp = col1; col1 = col2; col2 = tmp;
    }
    */
    
    // Applying the dark lines, edges lines and shading to each arc.
    col1 *= (pat2.x*.3 + .7)*pat.x*shad.x;
    col2 *= (pat2.y*.3 + .7)*pat.y*shad.y;
    // Colored stripes, if you prefer.
    //col1 *= mix(vec3(1), bg*vec3(1.1, 1, .9), 1. - pat2.x)*pat.x*shad.x;
    //col2 *= mix(vec3(1), bg*vec3(1.1, 1, .9), 1. - pat2.y)*pat.y*shad.y;

    
    
    // Rendering the bottom arc. Dark lines and color.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, d.x));
    col = mix(col, col1, 1. - smoothstep(0., sf, d.x + .0035));
    
    // Laying down some shadowing from the top arc onto the bottom one.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., max(d.y, d.x)))*.25);
    
    // Rendering the top arc. Dark lines and color.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, d.y));
    col = mix(col, col2, 1. - smoothstep(0., sf, d.y + .0035));
    
    
    // Extra sutble gradient coloring.
    //col = mix(col.yxz, col, uv.y*.5 + .5);
    
    
    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
