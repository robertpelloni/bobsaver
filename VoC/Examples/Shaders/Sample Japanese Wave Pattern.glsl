#version 420

// original https://www.shadertoy.com/view/XlKXzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Japanese Wave Pattern
    ---------------------

    I tend to call them fish scale tiles, but I've heard them referred to as Japanese wave 
    patterns, European tiles, etc. Either way, it's just an excuse to play around with 2D 
    polar coordinates.

    This particular design is based on something I came across on the net years ago. I'm 
    not sure who originally came up with it, but I see it frequently in various forms all 
    over the net. I have a feeling that the originals were hand drawn, because I don't 
    think anyone would ever get bored enough to code one... :)

    Conceptually, there's nothing difficult here, but the routines are a little fiddly. In 
    essence, the texture is constructed from a series of fan-like shapes made up of 
    combinations of strategically placed circles. Decorating the tiles involves a few steps, 
    due to the intricate details. However, it's essentially nothing more than a few lines 
    and shapes rendered on a polar grid.

    Getting finely detailed images to look right on everyone's system is impossible. I find 
    the biggest problem is the large range in PPIs these days. What looks right on my 
    system might not look that great on someone elses.

    I coded this using the 800x450 canvas on a 17 inch laptop with 1920x1080 resolution, so 
    the resulting image physically looks the size of Samsung phone in side view. However, 
    it's not uncommon for people to have systems with PPIs way in excess of that these days, 
    which would result in a much smaller image, and thus, squashed details. Unfortunately, 
    it's not possibe to control that.

    In order to show the repeat texture qualities, I've opted for scales that look the same 
    size at different resolutions. That may or may not have been the best choice.

    There's a compile option to distinguish between alternating scale layers and another 
    option to turn off the highlights, just in case a rippling, hardened scale is messing 
    with your sense of physical correctness. It disturbs mine a bit. :)

    Other examples:

    // I deliberately refrained from looking at Kuvkar's rendition in the hope that I could 
    // bring something new to the table. I didn't. :D
    European Cobblestone Tiles - kuvkar
    https://www.shadertoy.com/view/ldyXz1

    // Awesome usage of fish scales would be putting it mildly. :)
    Kelp Forest - BigWIngs
    https://www.shadertoy.com/view/llcSz8

    // Fabrices take on it. I might look into it more closely.
    Hexagonal Tiling 5 - FabriceNeyret2
    https://www.shadertoy.com/view/4dKXz3

*/

// Cheap bump highlights.
#define SHOW_HIGHLIGHTS

// Distinguishes between the two layers by changing the color of one.
//#define SHOW_ALTERNATE_LAYERS
   

// A cheap hack to store a bump value.
float bumpValue;

// Fabrices consice, 2D rotation formula.
mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// Decorating each scale. For all intents and purposes, this is a demonstration of converting
// an N by N square grid to N by N disc-like polar cells and drawing some things in them.
// The code looks more involved than it really is, due to the coloring, decision making, etc. 
vec3 scaleDec(vec2 p, float layerID){

    // Square grid partioning for the scales. This will be further partitioned into a polar
    // grid to draw some details.
    p = mod(p, vec2(.9, .5)) - vec2(.9, .5)/2.;

    
    // Mover the center of the disc to the top of the cell. In fact, we've moved it slightly 
    // higher to allow for the thicker fan border.
    p -= vec2(-.05, -.28);
    

    
    // Pinching the design together along X to match the fact that we're drawing circles slightly
    // squashed along X... Technically ellipses.
    // We're also multiply by a scalar factor or 14. This breaks each scale into a 14x14 grid, 
    // which we'll convert to polar coordinates. See the radius (r) and angle (a) lines below.
    p *= 14./vec2(.95, 1); 
    
    float r = length(p); // Radius. The radial part of the polar coordinate.
    float patID = step(.5, fract(r/2.)); // Pattern ID. Either lines or the sinusoidal design.
     
    
    // Rotate: I've given the layer IDs values of one and negative-one, in order to spin the
    // discs in opposing directions... I figured it might look more interesting. Commenting it
    // out stops the rotation.
    p *= r2(-time/12.*layerID); 
    //p *= r2(-time/48.*(floor(r) + 4.)*spin); // Rotate sections at differt rates.
    //if(patID>.5) p *= r2(-time/12.*spin);  // Only rotate half the sections.
    
    
    // Controls the amount of vertical lines in each polar segment. Just to make things difficult,
    // I wanted a higher density of lines and squiggles as we moved down the scale.
    float vLineNum = floor(r)*12. + 16.;    
    if(patID>.5)  vLineNum /= 2.; // Lower the frequency where rendering the squiggly bits.
    
    
    // Angle of the pixel in the grid with respect to the center.
    float a = atan(p.y, p.x);
    // Partioning the angles into a number of segments.
    float ia = floor(a*vLineNum/6.2831853);
    ia = (ia + .5)/vLineNum*6.2831853; 
    
    // Rotating by the segment angle above.
    p *= r2(ia);
    p.x = fract(p.x) - .5; 
    
    // The vertical lines.
    float vLine = abs(p.y) - .05;  
    vLine = smoothstep(0., fwidth(vLine), vLine)*.75 + .25;//step(0., d);////clamp(fwidth(vLine), 0., .1)*2.
    if(patID>.5) vLine = 1.; // No vertical lines every second segment.
    
    // Horizontal partitioning lines.
    float hLine = abs(fract(r + .5) - .5) - .05;
    hLine = smoothstep(0., fwidth(hLine)*1., hLine);  
 
    // Scale border - Smooth (trial and error) version of: if(r>7.15) hLine1 *= .05;
    hLine *= .05 + smoothstep(0., fwidth(7.2 - r), 7.2-r)*.95; 
    
    // Every second partition, draw a sinusoidal pattern.
    if(patID>.5){
        
        // Line, centered in the partition, perturbed sinusoidally.
        float wave = sin(a*vLineNum/2.)*.2;
        float hLine2 = abs(fract(r + wave) - .5) - .04;
        hLine2 = smoothstep(0., fwidth(hLine2)*1., hLine2);
        // Place some dots in amongst the sinusoid.
        float dots = length(p - vec2(wave*.5, 0)) - .07;
        dots = smoothstep(0., fwidth(dots), dots);
        hLine2 = min(hLine2, dots);
        hLine2 = hLine2*.8 + .2;
        
        hLine = min(hLine, hLine2);
    }
    
    
    // Combining the horizontal line patterns and the vertical lines.   
    vec3 col = vec3(1)*min(vLine, hLine);
    
    // Color up every second partition according to object ID. I did this out of 
    // sheer boredom. :)
    if(patID<.5) {        
        
        if (layerID > 0.) col *= vec3(.7, .9, 1.3);
        else col *= vec3(.8, 1.2, 1.4);
    }
    
    // Apply some color, dependent on segment number.
    vec3 gradCol = pow(vec3(1.5, 1, 1)*max(1. - floor(r)/7.*.7, 0.), vec3(1, 2, 10)); 
    //vec3 gradCol = pow(vec3(1.5, 1, 1)*max(1. - (r)/7.*.7, 0.), vec3(1, 2, 10)); 
    //vec3 gradCol = pow(vec3(1.5, 1, 1)*max(1. - (r)/7.*.7, 0.), vec3(1, 3, 16)); 

    // Very simple bump value. It's a global variable, separate to the coloring. It's
    // a bit of hack added after the fact, but it works.
    //bumpFunc = cos(r*6.283)*.5 + .5;
    bumpValue = 1. - clamp(-cos(r*6.283*1.)*2. + 1.5, 0., 1.)*1.;
   
    
    // Return the final color.
    return col*(min(gradCol, 1.)*.98 + .02);
    
    
    
}

// Basically, three circular shapes combined in such a way as to create a fan. The result 
// is a grid "half" filled with fan shapes. A second layer - offset appropriately - is 
// required to fill in the entire space to create the overall scale texture.
//
// By the way, the procedure below is pretty simple, but a little difficult to describe. 
// Isolating the function and running it by itself is the best way to grasp it.
float scalesMask(vec2 p){

    
    const float fwScale = 3.; // "fwidth" smoothing scale. Controls border blurriness to a degree.
 
    // Repeat space: Breaking it up into .9 by .5 squares... just to be difficult. :)
    // I wanted the scales to overlap slightly closer together, which meant bringing the centers
    // closer together. This meant offsetting everything... You have my apologies. :)
    p = mod(p, vec2(.9, .5)) - vec2(.9, .5)/2.;
 
    
    // Draw a circle, centered at the top of the .9 by .5 rectangle.
    float c = length(p +  vec2(.0, .25)); 
    c = smoothstep(0.,  min(fwidth(c), .01)*fwScale, c - .5);

    float mask = c;

    // Chopped off two partial circles at the top left and top right. They're positioned in such
    // a way to create a fan shape.
    //
    // The "sign" business is just a repetitive trick to take care of two quadrants at once.
    // "sign(p.x)" has the effect of an "if" statement.
    c = length(p - vec2(sign(p.x)*.9, -1.)*.5);
    
    
    // Combine the three circular shapes to create the fan.
    return max(mask, smoothstep(0., min(fwidth(c), .01)*fwScale, .5 - c));
    
}

// The decrotated scale tiles. Render one set of decorated fans, combine them with the
// other set, then add some highlighting and postprocessing.
vec3 scaleTile(vec2 p){
    
    // Contorting the scale a bit to add to the hand-drawn look.
    vec2 scale = vec2(3, -2.);
    
    // One set of scale tiles, which take up half the space.
    float sm = scalesMask(p*scale); // Mask.
    vec3 col = sm*scaleDec(p*scale + vec2(-.5, -.25), 1.); // Decoration.
    float bf2 = bumpValue*sm;
    
    // The other set of scale tiles.
    float sm2 = scalesMask(p*scale + vec2(-.45, -.75)); // Mask.
    vec3 col2 = sm2*scaleDec(p*scale + vec2(-.5, -.75) + vec2(-.45, -.25), -1.); // Decoration.
    
    
    #ifdef SHOW_ALTERNATE_LAYERS
    // A simple way to distinguish between the two layers.
    col2 = col2*.7 + col2.yxz*.3;
    #endif
    
    // Add some highlighting.
    bumpValue = max(bf2, bumpValue*sm2);
    col = max(col, col2);
    
    // Toning the color down a bit. This was a last minute thing.
    return col*.8 + col.zxy*.2;
    
}

void main(void) {

    // Screen coordinates. Feel free to tweak it, if you want.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/650.; // resolution.y;

    // Perturbing - and shifting - the screen coordinates for a bit of a wavy effect. It
    // gives the texture a kind of hand-drawn feel.
    uv += sin(uv*3.14159*3. - sin(uv.yx*3.14159*6. + time*.5))*.0075 + vec2(0, .125);
 
    
    // Producing the scale tile.
    vec3 col = scaleTile(uv);
    #ifdef SHOW_HIGHLIGHTS
    float bf = bumpValue; // Saving the bump value.
    
    // Taking a second nearby sample, in order to produce some cheap highlighting.
    vec3 col2 = scaleTile(uv + .5/450.);// 450.;
    float bf2 = bumpValue;
    
    // Color-based, or texture based bump.
    float bump = max(dot(col2 - col, vec3(.299, .587, .114)), 0.)*4.;
    // Adding a cheap and nasty functional bump. It effectively adds some extra contour.
    bump += max(bf2 - bf, 0.)*2.;
    
    
    // Add the rough highlighting.
    col = col + vec3(1, 1, 1.5)*(col*.9 + .1)*bump;
    //col = col*(vec3(.5, .7, 1)*bump*8. + 1.);
    #endif
    
    // Rought gamma correction.
    glFragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}
