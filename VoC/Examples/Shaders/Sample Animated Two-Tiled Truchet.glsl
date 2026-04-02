#version 420

// original https://www.shadertoy.com/view/tsSfWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Animated Two-Tiled Truchet
    --------------------------

    An animated two-tiled Truchet arrangement -- to accompany the texture mapped
    one -- for anyone only interested in the animated portion. I tried to give 
    it a kind of geometric art deco feel.

    For anyone wanting to make one of these, a few simple observations should help: 
    
    Animating square grid Truchet arc tiles on their own requires the flow directions 
    to be reversed on alternate checkered tiles. Furthermore, in order to work 
    straight line tiles in with them, both horizontal and vertical lines must span 
    two grid cells. In addition, adjacent horizontal line rows must flow in opposite 
    directions. The same applies to adjacent vertical line columns.

    Other examples:

    // The texture mapped version of this.
    Animated Textured Truchet - Shane
    https://www.shadertoy.com/view/3dSBzt

    // A much, much simpler version containing just the arc tiles.
    Minimal Animated Truchet - Shane
    https://www.shadertoy.com/view/XtfyDf

*/

// Displays each separate grid cell, which allows you to more easily discern
// individual tiles.
//#define SHOW_GRID

// Thinner Truchet rails.
//#define THINNER

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// Global Truchet constants. The angle is either the angle of the
// Truchet semi-circles, which have been normalized to the zero to one
// range, or the value of the straight line position on the straight
// edge tile arrangement, which also ranges from zero to one.
vec2 ang;

// The Truchet distance field. A lot of this is standard stuff. The additional
// code here involved texture mapping. That was just a case of 
vec2 df(vec2 p){
    
    // Two by two cell random value.
    vec2 ip2 = floor(p/2.);
    float rnd2 = hash21(ip2 + .43);  
    
    // Cell ID and local coordinates.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    // Random 1x1 numbers, for flipping and rotating.
    float rnd = hash21(ip);
    float rnd3 = hash21(ip + .57);
    
    // The distance field container. Each cell contains either two lines
    // or two arcs, so this will hold each one.
    vec2 d = vec2(1e5);
  
    
    // When animating arc Truchet arrangements only, the trick is to 
    // reverse the animation flow on alternate checkered cells... 
    // I have a basic animated version on here somewhere, if you
    // require more information.
    //
    // Anyway, working in the extra overlapping straight line tiles 
    // complicates things. However, after a while, you'll realise that 
    // either the horizontal or vertical line must span two cells for 
    // the animationto work, so that's what the following two-by-two 
    // checkered "mod" decision is all about.
    //
    // Every 2 by 2 alternate checker, put in the overlapped straight 
    // tiles. Otherwise, calculate the distance field for the double 
    // arc one.
    if(mod(ip2.x + ip2.y, 2.)<.5){ // Alternate checkers.
    //if(rnd2<.5){ // Random 2x2 coverings.
    //if((mod(ip2.x, 2.)<.5 || mod(ip2.y, 2.)<.5) && rnd2<.5){ // Mixing.
        
        
        
        // Overlapping straight tile.

        d = abs(p);
        ang = p.yx;

        // Reversing just the X-directions on every second column. It's 
        // common sense... but it still took me a while to figure out.. :)
        if(mod(ip.x + 1., 2.)<.5){
            ang.x *= -1.;

        }
        // Reversing just the Y-directions on every second row.
        if(mod(ip.y + 1., 2.)>.5){
            ang.y *= -1.;
        }  

        // Randomly change the rendering order, which means
        // switching everything else. I always forget this, then spend
        // ages trying to figure out why things aren't working. :)
        if(rnd3<.5) {
            d = d.yx;
            ang = ang.yx;
        }

        // This makes things line up.
        ang += .5;
        
        // The straight lines are about 1.5 times the length of the
        // quarter arcs, so multiply the straight line pattern 
        // frequency by 3 and the arc frequency by 2.
        ang *= 3.;

    }
    else {
        
        
        // Double arc tile.
        
        // Randomly rotate.
        if(rnd<.5) {
            p = p.yx*vec2(1, -1);
        }
        
        // Individual arc distances. One in each corner.
        d.x = length(p - .5) - .5;
        d.y = length(p + .5) - .5;
        d = abs(d);
        
        // The angles of the pixels subtended to the circle centers of
        // each arc. Standard polar coordinate stuff.
        ang.x = -atan(p.y - .5, p.x - .5);
        ang.y = -atan(p.y + .5, p.x + .5);
        
        
        // This comes up all the time when animating square Truchets.
        // It's necessary to reverse the animation flow on alternate
        // checker squares.
        if(mod(ip.x + ip.y, 2.)<.5) ang *= -1.;

        
        // Reverse the flow on all randomly rotated tiles.
        if(rnd<.5) ang *= -1.;
        
        // Randomly change the rendering order, which means
        // switching everything else. I always forget this, then spend
        // ages trying to figure out why things aren't working. :)
        if(rnd3<.5) {
             d = d.yx;
             ang = ang.yx;
         }
        
        // Normalizing the angle. Four arcs make up a circle, which
        // means each needs to run from zero to one four times over
        // for the texture to wrap... I'm pretty sure that's right...
        // but I've been wrong before. :)
        ang *= 4./6.2831853;
        
        // The straight lines are about 1.5 times the length of the
        // quarter arcs, so multiply the straight line pattern 
        // frequency by 3 and the arc frequency by 2.
        ang *= 2.;
        
        
        
    }
    
    // Adding some time-based movement... or animation, if you wish to 
    // call it that. :D By the way, if you take out the time component,
    // I think the "fract" call still needs to be there.
    ang = fract(ang + time/4.);
    
    
    return d;
    
}

// The square grid boundaries.
float gridField(vec2 p){
    
    vec2 ip = floor(p);
    p -= ip + .5;
    
    p = abs(p);
    return abs(max(p.x, p.y) - .5) - .001;

}

void main(void) {

    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Scaling and translation.
    const float gSc = 7.;
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera in the north east (top right) direction. 
    vec2 p = uv*gSc - vec2(-1, -.5)*time/2.;
    

    // Smoothing factor, based on scale.
    float sf = 2./resolution.y*gSc;
   
    // Thinner rails.
    float lSc = 6.;
    #ifdef THINNER
    lSc = 8.;
    #endif
    
    // Line width.
    float lw = 1./lSc/gSc;
    
    // Calling the Truchet pattern distance field and giving it a bit of width.
    // Each cell contains two overlapping arcs or line objects. 
    vec2 d = df(p) - 2.5/lSc;
    
    // Background color. Keeping things simple.
    vec3 col = vec3(1., .9, .8);
    
    #ifdef THINNER
    // Line pattern. Used for thinner Truchet widths.
    float pat = abs(fract(p.x*lSc + .5*0.)  - .5) - lw*lSc/2.;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, pat)));
    #endif
   
    // Rendering the two Truchet layers. A lot of this was made up as I
    // went along, so you could ignore the details.
    //
    for(int i = 0; i<2; i++){
         
        // The tile layer distance... offset by a small amount or whatever
        // reason I had at the time. :)
        float di = d[i] - lw/4.;
        
        // The animated part: This is a standard cheap way to do it, but 
        // you could also plug "ang[i]" into a function that renders
        // shapes, etc.
        float tracks = clamp(sin(ang[i]*6.2831 + time*6.)*4., 0., 1.);
       
         
        
        // Set to 1 for normal edge thickness.
        float gap = 1. + lw;// + sf/2.;//.25/lSc;
        // Set to "di + lw" for normal edge thickness.
        
        // Fake ambient occlusion and dark edge.
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*6., di))*.35);
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, di));
        
        // Outer layers.
        col = mix(col, vec3(1., .9, .8), 1. - smoothstep(0., sf, di + lw*2.)); 
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, di + gap/lSc));
        // Middle.
        col = mix(col, vec3(1), 1. - smoothstep(0., sf, di + gap/lSc + lw));
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, di + 2.*gap/lSc));
        // The central tracks.
        col = mix(col, vec3(1)*tracks, 1. - smoothstep(0., sf, di + 2.*gap/lSc + lw));
         

    }
    
    // Displaying the grid cells.
    #ifdef SHOW_GRID
    float grid = gridField(p);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid)));
    #endif

    
    // Output to screen
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
