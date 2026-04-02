#version 420

// original https://www.shadertoy.com/view/XtsBRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Mobius Weave
    ------------

    A Mobius spiral with a pseudo random weave. The idea came from Fabrice's cool "Round Weaving" 
    example. Fabrice always comes up with clever little shaders, and I have a habit of viewing
    them, then going off on a tangent for a few hours. :) 

    His "Round Weaving" shader essentially involves applying something along the lines of a polar 
    transform to a standard cross-weave pattern. Although visually different, this is just an extension 
    of that with some window dressing applied. Instead of the standard over under weave, I've psuedo-
    randomized it, and have substituted the polar transform for a reasonably well known Mobius spiral 
    transform, which is polar in nature, but a little bit fancier.

    Inspired by:

    // Slightly different, but basically a polar transformed cross weave. As with a lot of Fabrice's
    // shaders, it's very concisely written - Roughly a couple of tweets.
    round weaving - FabriceNeyret2
    https://www.shadertoy.com/view/MtffzB

    Other related examples:

    // Very cool, much more complex (no pun intended) example. Mobius spirals are pretty easy;
    // Packing circles into them is less so. :)
    Doyle spirals - knighty
    https://www.shadertoy.com/view/4tffDH

    // A simplified circle packed spiral.
    Doyle spiral - ws
    https://www.shadertoy.com/view/MtffDn

    // Just the basics - for anyone who wants to make a Mobius spiral, or whatever they're
    // technically called.
    Logarithmic Mobius Transform - Shane
    https://www.shadertoy.com/view/4dcSWs

*/

// Standard 2D rotation formula - See Nimitz's comment.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Standard Mobius transform: f(z) = (az + b)/(cz + d). Slightly obfuscated.
vec2 Mobius(vec2 p, vec2 z1, vec2 z2){

    z1 = p - z1; p -= z2;
    //return vec2(dot(z1, p), z1.y*p.x - z1.x*p.y)/dot(p, p);
    // Equivalent to the line above. Fabrice tidied it up. I'd imagine the grouped
    // operations might make it a little quicker, but don't quote me on that. :)
    return mat2(z1, z1.y, -z1.x)*p/dot(p, p); 
}

// Standard spiral zoom.
vec2 spiralZoom(vec2 p, vec2 offs, float n, float spiral, float zoom, vec2 phase){
    
    p -= offs;
    float a = atan(p.y, p.x)/6.283 + time/32.;
    float d = length(p);
    //return vec2(a*n + log(d)*spiral, -log(d)*zoom + a) + phase;
    // Equivalent to the line above. Fabrice tidied it up. I'd imagine the grouped
    // operations might make it a little quicker, but don't quote me on that. :)
    return mat2(n, 1, spiral,-zoom)*vec2(a, log(d)) + phase;

}

// This is a rewrite of IQ's original. It's self contained, which makes it much
// easier to copy and paste. I've also tried my best to minimize the amount of 
// operations to lessen the work the GPU has to do, but I think there's room for
// improvement.
//
float noise3D(vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
    const vec3 s = vec3(7, 157, 113);
    
    vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
    p -= ip; // Cell's fractional component.
    
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
    
}

void main(void) {

    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
/*  
    // Polar transformation. Not as fancy looking, but there for comparison.
    uv = r2(time/4.)*uv;
    uv = r2(atan(uv.y, uv.x)*1.)*uv*2.;
    float r = length(uv)*.35;
    vec2 p = uv*16.;
*/ 
    
/*   
    // Standard patterned weave. Comparitively speaking, not that exciting. :)
    // Comment out the four lines below this block first.
    uv += time/16.;
    float r = 1.;
    vec2 p = uv*8.;
*/
    
    // Shading over the two singularity points. It serves two purposes: One, to give depth,
    // but also to alleviate Moire patterns that tend to build up. By the way, this is a
    // hack, and is only possible due to some constants below. However, it's possible to
    // extend it further to locate the singularity points in a more robust manner.
    float r = min(length(uv - vec2(-.375, .125)), length(uv - vec2(.375, -.125)));
    //float r = length(uv - vec2(-.375, .125))*length(uv - vec2(.375, -.125));
    
    
    // Transform the screen coordinates: For anyone not familiar with the order in which
    // you do this, transforms are performed prior to rendering the flat grid.
    //
    // The logarithmic Mobius spiral is one of the more interesting transformations, and 
    // just involves a little math. By the way, these transforms work independently, but tend 
    // to look better coupled together.
    uv = Mobius(uv, vec2(-.875, -.125) , vec2(.375, -.125));
    // Logarithmic spiral zoom.
    uv = spiralZoom(uv, vec2(-.5), 5., 3.14159*.2, .5, vec2(-1, 1)*time*.125);
     
    
    // Scene scaling. 
    vec2 p = uv*4.;
    
    
    // Overlapping cross construction. Most of it is common sense - Split space up into
    // grid cells. In each cell, draw a horizontal line, then overlap it with a vertical 
    // line. Apply shadows, decorative design, etc.
    
    
    // Cell's unique ID.
    vec2 ip = floor(p);
    
    // Partition space into cells. The line below is equivalent to "p = fract(p) - .5;."
    // It saves a "fract" call, which doesn't matter here, but it can be helpful inside
    // raymarching loops and so forth.
    p -= ip + .5;
    
    // Due to the nature of the transform, the pattern needs to wrap about the line
    // dividing the two singularity points, so true randomness isn't really possible.
    // However, it's possible use a symmetrical pattern that looks random... Kind of.
    //
    // By the way, I hacked the following together in a hurry, so there's probably a
    // more elegant way to write it. Although, I could probalby say that about most 
    // of my code. :)
    if(mod(ip.x*ip.y*.5 + (ip.x+ip.y + 1.)*.75, 2.)>.5) p.xy = p.yx;

    // It'd be nice to really randomize with the following, but artifacts are visible
    // about the line ividing the two singularity points. Hopefully, there's a
    // workaround, but I'm not sure what it is yet.
    //if(fract(sin(dot(ip, vec2(1.373, 113.937)))*43758.5453)>.5) p.xy = p.yx;
    

    // Horizontal line and vertical lines. Fabrices has cleverly used sinsusoids to
    // do it all, but I needed a little more precission to work with, so went the
    // 2D distance field route.
    float cx = abs(p.y) - .21;
    float cy = abs(p.x) - .21;
    
    // Rendering the decorated overlapping crosses. A lot of it was made up as I went
    // along. I could probably group a lot of it together, but relatively speaking, 
    // this all pretty easy for the GPU to handle.
    
    // The patterns that run over the stripes to give it that cheesy yarn-like look. :)
    float pat = clamp(cos((uv.x - uv.y)*6.283*24.)*.35 + .65, 0., 1.)*.8 + .2;
    vec2 uv2 = r2(-3.14159/4.)*uv;
    float pat3 = clamp(cos((uv2.x + uv2.y)*6.283*48.)*.75 + .75, 0., 1.)*.8 + .2;
    
    // The longitudinal and latitudinal stripes. One for the vertical line and another
    // for the horizontal one.
    float stripeX = clamp(cos(p.y*6.238*6.)*.6 + .57, 0., 1.);
    float stripeY = clamp(cos(p.x*6.238*6.)*.6 + .57, 0., 1.);
    
    // The background pattern - It's supposed to give the impression that there's some more
    // tightly woven yarn behind the main geometric pattern, or something to that effect.
    vec3 col = vec3(.25)*(1. - pat3*.9)*pat;

    // Rendering the vertical line.
    col = mix(col, vec3(0), (1. -smoothstep(0., .1, cx - .125))*.7); // Drop shadow.
    col = mix(col, vec3(0), 1. -smoothstep(0., .025, cx - .05)); // Sharper border line.
    // Main pattern.
    col = mix(col, vec3(.6)*(cos(p.y*6.283) + 1.)*stripeX*pat, 1. -smoothstep(0., .025, cx)); 
    // Darkening the center, just to tone it down a little.
    col = mix(col, vec3(0), (1. -smoothstep(0., .05, cx + .175))*.65);
     
    // Rendering the horizonal line, which is just a repeat of the above.
    col = mix(col, vec3(0), (1. -smoothstep(0., .1, cy - .125))*.7);
    col = mix(col, vec3(0), 1. -smoothstep(0., .025, cy - .05));
    col = mix(col, vec3(.6)*(cos(p.x*6.283) + 1.)*stripeY*pat, 1. -smoothstep(0., .025, cy));
    col = mix(col, vec3(0), (1. -smoothstep(0., .05, cy + .175))*.65);
    

    // Add a bit of noise to give the weave material more of an authentic look. 3D noise
    // was a bit of an indulgence, and not all that necessary, but I thought I'd supply
    // the fake depth information too.
    col *= noise3D(vec3(uv*256., r))*.75 + .75;
    
    
    // Artificial depth shading.
    //
    // Applying the shading to give the pattern a bit of depth, and to hide singularity
    // artifacts.
    vec3 fogCol = vec3(0); // Other - very dark - colors work too, but don't look convincing.
    col = mix(col, fogCol, 1./(1. + r*.25 + r*r*8.));
    // Extra fake fog to darken the horizon of those singularities a bit more.
    col = mix(col, fogCol, smoothstep(0., .99, .03/r));
    
    
    // Very mild sepia, almost charcoal. I did this to pay hommage to Fabrice's version. :)
    col *= vec3(1.1, 1, .95);
    
    // Apply a vignette.
    uv = gl_FragCoord.xy/resolution.xy; 
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y), .25)*1.15;
 
    
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
} 
