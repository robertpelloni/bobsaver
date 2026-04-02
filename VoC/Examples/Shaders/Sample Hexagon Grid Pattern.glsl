#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WsVGWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Hexagon Grid Pattern
    --------------------

    I see variations on this particular pattern all over the place, and it's pretty
    easy to make, so I figured I'd recreate one. If it's not obvious, the idea is to
    partition space into hexagonal cells, then render six smaller overlapping hexagons 
    in each of the hexagonal cell's six corners. Commenting in the "SHOW_GRID" define 
    should make it more clear. 

    On a side note, there are countless other interesting hexagonal stock imagery 
    patterns on the internet that I'd love to see on Shadertoy, if anyone feels like 
    making any. :)

    
    Other Hexagonal Pattern Examples:

    Shadertober Day 10 - Pattern -- BackwardsCap
    https://www.shadertoy.com/view/tsV3Rd

    Hexagon Pattern -- plabatut 
    https://www.shadertoy.com/view/Wdt3WN

    Impossible Chainmail -- BigWIngs 
    https://www.shadertoy.com/view/td23zV

*/

//#define SHOW_GRID

#define FLAT_TOP

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.617, 57.743)))*43758.5453); }

// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1);
#else
const vec2 s = vec2(1, 1.732);
#endif

// Hexagonal bound: Not technically a distance function, but it's
// good enough for this example.
float getHex(vec2 p){
    
    // Flat top and pointed top hexagons.
    #ifdef FLAT_TOP
    return max(dot(abs(p.xy), s/2.), abs(p.y*s.y));
    #else   
    return max(dot(abs(p.xy), s/2.), abs(p.x*s.x));
    #endif
}

// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    vec4 ip = floor(vec4(p/s, p/s - .5));
    vec4 q = p.xyxy - vec4(ip.xy + .5, ip.zw + 1.)*s.xyxy;
    return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);
    //return getHex(q.xy)<getHex(q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);

}

void main(void) {

    
    // Aspect correct screen coordinates.
    float res = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/ res;
    
    // Scaling and translation.
    const float sc = 3.;
    vec2 p = uv*sc - vec2(-1, -.5)*time;
    
    // Smoothing factor.
    float sf = 1./res*sc;
    
    
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
    
    
    // Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
    // Multiplying them by "s" gives the actual vertex postion.
    #ifdef FLAT_TOP
    // Vertices: Clockwise from the left.

    vec2[6] vID = vec2[6](vec2(-1./3., 0), vec2(-1./6., .5), vec2(1./6., .5), 
                          vec2(1./3., 0), vec2(1./6., -.5), vec2(-1./6., -.5)); 
    
    //vec2[6] eID = vec2[6](vec2(-.25, .25), vec2(0, .5), vec2(.25, .25), 
                         // vec2(.25, -.25), vec2(0, -.5), vec2(-.25, -.25));
    
    #else
    // Vertices: Clockwise from the bottom left. -- Basically, the ones 
    // above rotated anticlockwise. :)
    vec2[6] vID = vec2[6](vec2(-.5, -1./6.), vec2(-.5, 1./6.), vec2(0, 1./3.), 
                          vec2(.5, 1./6.), vec2(.5, -1./6.), vec2(0, -1./3.));
     
    //vec2[6] eID = vec2[6](vec2(-.5, 0), vec2(-.25, .25), vec2(.25, .25), vec2(.5, 0), 
                          //vec2(.25, -.25), vec2(-.25, -.25));
 
    #endif

   
    // The scene color.
    vec3 col = vec3(1);

    
    // Rendering the six overlapping hexagons within each cell.
    for(int i = 0; i<6; i++){
        
  
        // Corner hexagon.
        vec2 q = abs(p4.xy - vID[5-i]*s*.5);
        float hx = getHex(q) - .265;
        float oHx = hx;

        // Using the neighboring hexagon to chop out one third. This way, the final
        // hexagon will look like it's tucked in behind the previous one... Comment
        // out the third (hx) line to see what I mean. By the way, you don't have to
        // do this, but I prefer this particular look.
        q = abs(p4.xy - vID[(5-i + 5)%6]*s/2.);
        float hx2 = getHex(q) - .27;
        hx = max(hx, -hx2);

        // Using the triangle wave formula to render some concentric lines on each
        // hexagon.
        float pat = (1. - abs(fract(oHx*16. + .2) - .5)*2.) - .55;
        pat = smoothstep(0., .2, pat);
        
        // Rendering the chopped out hexagon and a smaller white center.
        col = mix(col, vec3(1)*pat, 1. - smoothstep(0., sf, hx));  
        col = mix(col, vec3(1), 1. - smoothstep(0., sf, max(oHx + .22, -hx2)));
        // A colorful center, if preferred.
        //col = mix(col, vec3(1, .05, .1), 1. - smoothstep(0., sf, max(oHx + .22, -hx2))); 
        
        // Applying a shadow behind the hexagon. I thought it added more visual interest, 
        // but for something like wallpaper, or whatever, you could comment it out.
        vec3 sh = mix(col, vec3(0), (1. - smoothstep(0., sf, hx)));
        col = mix(col, sh, (1. - smoothstep(0., sf*8., max(max(hx, hx2), - hx2)))*.5);

    }
    
        
    // Rendering the grid boundaries, or just some black hexagons in the center.
    float gHx = getHex(p4.xy);
    
    #ifdef SHOW_GRID 
    // Grid lines.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(gHx - .5) - .035));  
    col = mix(col, vec3(1, .05, .1)*1.5, 1. - smoothstep(0., sf, abs(gHx - .5) - .0075));  
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., gHx - .02 - .025))*.5);
    // Colored center hexagon.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, gHx - .02 - .025));   
    col = mix(col, vec3(1, .05, .2), 1. - smoothstep(0., sf, gHx - .015));   
    #else
    // Small shadowed center hexagon.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., gHx - .02))*.5);   
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, gHx - .02));  
    #endif
    
    // Vignette.
    //uv = gl_FragCoord.xy/resolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625);

    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);;
}
