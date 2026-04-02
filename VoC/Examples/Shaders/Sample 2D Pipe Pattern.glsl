#version 420

// original https://www.shadertoy.com/view/XlXBzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    2D Pipe Pattern
    ---------------

    Using a mixture of a cross-over tile and double arc tile to produce a pipe pattern.
    It's a 2D effect, but is rendered in an oldschool psuedo 3D game style... kind of. :)

    I like coding in psuedo 3D, because it's relaxing, and it's fun composing the illusion
    of depth and lighting...  I also like it because the physics police can't really 
    complain that the mock physical setting isn't fake enough. :D

    Anyway, there's nothing here that hasn't been done before. It's a relatively brief 
    example, and it's all pretty easy to code. If you can draw 2D shapes over other 2D 
    shapes, then it shouldn't present too much of a challenge.

    Similar examples:

    // Another dual tiled Truchet example.
    Truchet Roads - morgaza
    https://www.shadertoy.com/view/4lsyDX

    // The 3D counterpart. Not as relaxing to code this one, but still doable. :)
    Dual 3D Truchet Tilesv- Shaen
    https://www.shadertoy.com/view/4l2cD3

*/

// I put this here for anyone who wants to see the outlines of the individual Truchet tiles.
//#define SHOW_SINGLE_TILES

// I put these in out of sheer boredom. The idea was to provide a little extra visual 
// interest... I'll leave them in as a default, but I'm still not quite sure about them. :)
#define ENVIRONMENTAL_LIGHTS

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

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

// IQ's 2D box function. Necessary for correct box shadows.
float sdBox(vec2 p, vec2 b){
  
  return length(max(abs(p) - b, 0.));
  //vec2 d = abs(p) - b;
  //return min(max(d.x,d.y), 0.) + length(max(d,0.0));
}

// Background lines. Horizonal only, or horitonal and vertical, 
// as the case may be.
float bgLines(vec2 p){
   
  p = abs(fract(p) - .5);
  #ifdef SHOW_SINGLE_TILES
  return min(p.x, p.y);  
  #else
  return p.x;
  #endif
    
}

// Vec2 to vec3 hash. Works well enough, but I should probably substitute it for 
// one of Dave Hoskins's more robust versions.
vec3 hash23(vec2 p){
    
    vec3 dt;
    dt.x = dot(p, vec2(1.361, 113.947));
    dt.y = dot(p + 7.54, vec2(1.361, 113.947));
    dt.z = dot(p + 23.893, vec2(1.361, 113.947)); 
    
    return fract(sin(dt)*43758.5453);
    
}

// Background pipe shadows. A bit wasteful, considering that you could put a 
// blurry grid in the background, and the shadows would almost look the same, but
// something in my mind won't quite accept it. :)
float truSh(vec2 p, float lW){
   
    
    // Two tile Truchet system. Pretty standard.
    vec2 ip = floor(p);
    
    // Three random numbers, used for tile selection and tile flipping.
    vec3 rnd = hash23(ip);
    
    // Grid.
    p -= ip + .5;
    
    // Depending on the random number, select the tile, and flip it if necessary.
    if(rnd.z>.35){
        // Cross rotation. Flipping has no effect.
        if(rnd.x > .5) p = p.yx;
    }
    else if(rnd.y > .5) p.y = -p.y; // Dual arc flipping. Rotation does the same thing.
    
        // Distance field variables.
    float d1, d2, d3, d4;
    
    
    if(rnd.z>.35){
        
        // Cross tile.
        d1 = abs(p.y) - lW;
        d2 = abs(p.x) - lW;
        
    }
    else { 
        
        // Dual arc tile.
        d1 = length(p - .5) - .5;
        d2 = length(p + .5) - .5;
        d1 = abs(d1) - lW;
        d2 = abs(d2) - lW;
        
    }
    
    // Joins.
    d3 = sdBox(vec2(p.x, abs(p.y) - .5 + lW/3.), vec2(lW + .03, lW/6.));
     d4 = sdBox(vec2(p.y, abs(p.x) - .5 + lW/3.), vec2(lW + .03, lW/6.));

    
    // Overall object.
    return min(min(d1, d2), min(d3, d4));
}

/*
// Altermative, cheaper shadow. Just a grid. Almost works... almost. :)
float truShFake(vec2 p){
   
  p = abs(fract(p) - .5);
  return min(p.x, p.y);
}
*/

void main(void) {

    // Screen coordinates. I've coded it for the 800 by 450 window, so have put some mild
    // restrictions on the resolution to account for blurriness, Moire patterns at smaller
    // canvas sizes, etc.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/clamp(resolution.y, 350., 600.);

    
    // Scale. Analogous to the field of view.
    const float sc = 4.;

    // Sizing the scene and moving it.
    vec2 p = uv*sc + vec2(sin(time*3.14159/16.)*2., 1.*time);
    
    // Putting a light slightly up to the right, just to match the fake drop shadows.
    // It's used for a bit of subtle attenuation.
    vec3 lp = vec3(vec2(sin(time*3.14159/16.), 1.*time) + .5, -1);
    
    // Keeping a copy of the sized screen coordinates.
    vec2 oP = p;
    
    
    // GRID SETUP.
    //
    // Grid square (tile) ID.
    vec2 ip = floor(p);
    
    // Three random numbers, used for tile selection and tile flipping.
    vec3 rnd = hash23(ip);
    
    // Partition the grid. Equivalent to: p = fract(p) - .5;
    p -= ip + .5;
    
    // Depending on the random number, select the tile, and flip it if necessary.
    if(rnd.z>.35){
        // Cross rotation. Flipping has no effect.
        if(rnd.x > .5) p = p.yx;
    }
    else if(rnd.y > .5) p.y = -p.y; // Dual arc flipping. Rotation does the same thing.

        
    
    // THE BACKGROUND.
    //
    // Background. Not sure why I shaded it, because it gets attenuated later... I'll
    // amalgamate the two when I get time.
    vec3 bg = vec3(1.1, 1, .9)*vec3(.85, .75, .65)*max(1. - length(uv)*.5, 0.);

    
    // Pipe pattern (dual Truchet) drop shadow.
    float tru = truSh(oP + .1, .15);
    //float tru = truShFake(oP + .1) - .15; // Fake shadow grid. 
    
    // Put the drop shadow on the background.
    bg = mix(bg, vec3(0), (1. - smoothstep(0., .15, tru))*.5);    
    
        

    // Putting some lines on the background. I made it up as I went along, so I
    // wouldn't take it too seriously.
    #ifdef SHOW_SINGLE_TILES
    const float scl = 1.;
    #else
    const float scl = .5;
    #endif
    float vor = bgLines((oP - (scl<.75? 0.: .5))*scl);
    float sq = vor - .03*scl;
    bg = mix(bg, vec3(0), (1. - smoothstep(0., .1*scl, sq))*.7);
    sq = vor - (.075 + .01)*scl;
    sq = abs(sq) - .0075*scl;
    bg = mix(bg, vec3(0), (1. - smoothstep(0., .01*scl, sq))*.9);    
    sq = vor;
    sq = abs(sq) - .0075*scl;
    bg = mix(bg, vec3(0), (1. - smoothstep(0., .01*scl, sq))*.9);

    // Quick, diagonal line pattern. Pretty standard way to make one.   
    float diag = clamp(sin((oP.x - oP.y)*6.283*20.)*1. + .95, 0., 1.)*.5 + .5;      
    // Applying it to the background.
    bg = mix(bg, vec3(0), (smoothstep(0., .01*scl, vor - .0075*sc))*(1. - diag)*.9);
   
  

    // MAIN OBJECT COMPOSITION.
    //
    // Scene color. Set it to the pre-prepared background.
    vec3 col = bg;
    vec3 jCol = vec3(1, .7, .5); //  Join color.
    vec3 pCol = vec3(1); // Pipe color.
    float lW = .125; // Pipe width. 
    const float shadow = .5; // Drop shadow factor.
    const float lnTrans = .9; // Shape line transparency.
    
    const float shPow = 4.; // Shade power.
    const float shAmp = 1.; // Shade amplitude.
    const float shAmb = .1; // Shade ambience.
    
    
    #ifdef ENVIRONMENTAL_LIGHTS
    // Environmental light display: Interesting, but needs some tweaking. In case it needs to be said, I've 
    // added it in for visual interest. However, I can't really think of a physical reason why it'd be there...
    // And why isn't at least some light registering on the back wall? ... So many unanswered questions. :D
    tru = truSh(oP, .0);
    float tru2 = truSh(r2(-3.14159/3.)*oP*3. + .5 + time*.35, .0);
     float lgtMsk = (1. - smoothstep(0., lW, tru))*(1. - smoothstep(0., .15, tru2));
    #endif
    
    // OBJECT DISTANCE FIELDS.
    //
    // Distance and shading variables.
    float d1, d2, d3, d4, d5, sh1, sh2, sh3, sh4, sh5;
    
    
    // Apply the distance fields and shades for the overlayed straight pipe tile, and for
    // the quarter bent pipe tile. The code below looks fiddly, but it's all pretty simple.
    // Draw a rectange, or an arc, etc. Shade and so forth.
    //
    // Rendering more straight pipes than curved ones. Pipe bends tend to occur less.
    if(rnd.z>.35){ 
        
        // The overlayed straight pipes.
        
        // Vertical and horizontal pipes.
        d1 = abs(p.y) - lW;
        d2 = abs(p.x) - lW;
        
        #ifdef ENVIRONMENTAL_LIGHTS
        // Adding the moving lights. I hacked this in. The cross over pipe needs a bit of masking,
        // logic, due to one pipe going under the other. It doesn't look right without it.        
        if(rnd.x<=.5) pCol = mix(pCol, vec3(2, 3, 4), (1. - smoothstep(0., .05, d2+lW))*lgtMsk*.5);
        pCol = mix(pCol, vec3(2, 2.5, 3), (smoothstep(0., .02, d2))*lgtMsk*.35);
        #endif

    }
    else {
        
        // The quarter pipe bends. Two on each tile. I'm rendering both for simplicity.
        // Plus, I wanted to ensure that the shadows rendered correctly. Having said that,
        // I'll come back to this and cut down on the double rendering when I have time.
        
        // Two arcs (quarter pipes).
        d1 = length(p - .5) - .5;
        d2 = length(p + .5) - .5;
        d1 = abs(d1) - lW;
        d2 = abs(d2) - lW;
        
        #ifdef ENVIRONMENTAL_LIGHTS
        // Adding the environmental lighting to the pipes.
        pCol = mix(pCol, vec3(2, 2.5, 3), lgtMsk*.35);
        #endif

        
    }
    
    #ifdef ENVIRONMENTAL_LIGHTS  
    // Adding the environmental lighting to the joins.
    jCol = mix(jCol, vec3(2, 2.5, 3), lgtMsk*.15);
    #endif
    
    // Joins. They're the same for each tile, so can be taken outside the "if" statement.
    d3 = sdBox(vec2(p.x, abs(p.y) - .5 + lW/3.25), vec2(lW + .03, lW/6.));
    d4 = sdBox(vec2(p.y, abs(p.x) - .5 + lW/3.25), vec2(lW + .03, lW/6.));

    // Extra shadowing, to place over the bottom pipe. Makes the shadows a little more realistic.
    d5 = length(p) - .2;
    
    
    // LIGHTING THE OBJECTS.
    //
    // Using the distance field to shade the objects. 
    sh1 = (-d1 + lW)/lW/2.;
    sh2 = (-d2 + lW)/lW/2.;
    float d3in = abs(p.x) - lW - .03;
    float d4in = abs(p.y) - lW - .03;
    sh3 = (-d3in + lW)/lW/2.;
    sh4 = (-d4in + lW)/lW/2.;

    // Tube ribbed lines.
    sh1 *= clamp(sin(d1*6.283*24.)*.5 + 1., 0., 1.);
    sh2 *= clamp(sin(d2*6.283*24.)*.5 + 1., 0., 1.);

    // Ramping up the shading for a more metallic look.
    sh1 = pow(max(sh1, 0.), shPow)*shAmp + shAmb;
    sh2 = pow(max(sh2, 0.), shPow)*shAmp + shAmb;
    sh3 = pow(max(sh3, 0.), shPow)*shAmp + shAmb;
    sh4 = pow(max(sh4, 0.), shPow)*shAmp + shAmb;

    sh5 = (cos(p.y*6.283*1.5)*.5 + 1.25);
    sh5 = pow(sh5, 1.)*sh2;
    
    // RENDERING THE LAYERS.
    //
    // In short, render a drop shadow, sharp dark egde, then apply the main 
    // color and pattern. Pretty standard stuff.
    //
    // Drop shadow.
    col = mix(col, vec3(0), (1. - smoothstep(0., .2, d1 - .03))*shadow);
    // Dark edge.
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, d1 - .02))*lnTrans);
    // Main color and pattern.
    col = mix(col, pCol*sh1, 1. - smoothstep(0., .01, d1));
    
    // Fake drop shadow for the bottom straight tube - cast by the top one.
    if(rnd.z>.35) col = mix(col, vec3(0), (1. - smoothstep(0., .2, d5))*.7); 
    col = mix(col, vec3(0), (1. - smoothstep(0., .2, d2 - .03))*shadow);
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, d2 - .02))*lnTrans);
    col = mix(col, pCol*sh2, 1. - smoothstep(0., .01, d2));
    
    
    // Extra lighting on the top cross section to give a slight bending impression...
    // I doubt it's fooling anyone. :)
    if(rnd.z>.35) col = mix(col, pCol*sh5, (1. - smoothstep(0., .01, d2))*.5);
    
    // Adding the joins - Pipes first. Joins afterward.
    col = mix(col, vec3(0), (1. - smoothstep(0., .1, d4 - .02))*shadow);
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, d4 - .02))*lnTrans);
    col = mix(col, jCol*sh4, 1. - smoothstep(0., .01, d4));
        
    col = mix(col, vec3(0), (1. - smoothstep(0., .1, d3 - .02))*shadow);
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, d3 - .02))*lnTrans);
    col = mix(col, jCol*sh3, 1. - smoothstep(0., .01, d3));
 
    
    
    
    

    // Very fake light attenuation. Using the shading information to pretend there's 
    // some 3D depth, then calculating the distance to the light hovering above it.
    float atten = length(lp - vec3(oP, -col.x));
    col *= vec3(1.15)*1./(1. + atten*atten*.05);
    
    // Adding some grunge, just to break things up a little. Comment this section
    // out, and the example looks too clean.
    float fBm = noise3D(vec3(oP*32., 1. - col.x))*.66 + noise3D(vec3(oP*64., 2. - 2.*col.x))*.34;
    col *= fBm*.5 + .75;
    
    
   
    /*
    // Cheap postprocess hash. Interesting, and looks cool with other examples, but 
    // possibly a little too much grunge, in this instance. Anyway, I've left it here 
    // for anyone who's like to take a look.
    float gr = dot(col, vec3(.299, .587, .114))*1.15;
    oP = r2(3.14159/3.)*oP;
    if(gr<.4) col *= clamp(sin((oP.x - oP.y)*6.283*96./sc)*1. + .95, 0., 1.)*.4 + .6;
    oP = r2(3.14159/3.)*oP;
    if(gr<.55) col *= clamp(sin((oP.x - oP.y)*6.283*96./sc)*1. + .95, 0., 1.)*.4 + .6;
    oP = r2(3.14159/3.)*oP;
    if(gr<.75) col *= clamp(sin((oP.x - oP.y)*6.283*96./sc)*1. + .95, 0., 1.)*.4 + .6;
    */

    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
