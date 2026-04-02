#version 420

// original https://www.shadertoy.com/view/NtV3zw

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Hexagon Molecule Pattern
    ------------------------
    
    This is a minimal abstract geometric representation of a molecular structure, 
    or to put it another way, it's another typical hexagon grid based pattern. :)
    
    Sometimes, I like to take a break from coding things that require thinking and
    do something easy. Variations on this particular pattern are everywhere, 
    especially in the world of stock imagery. The basic vector style I've chosen is 
    even more of a cliche, but it's simple and effective.

    There are several ways to produce a pattern like this, but since it's just a
    basic 2D overlay example that isn't taxing on the GPU, I've chosen the most direct 
    one, which is to produce a hexagonal grid, then iterate through all six sides and 
    vertices of the cells that have been flagged for rendering. There's definitely 
    better ways to go about it, like using polar coordinates, etc. If you only wanted 
    to render random sides, then a triangle grid would probably make things easier.
    
    I almost rendered this in offset vertex form, but decided to keep things simple.
    However, that's always an option at a later date. By the way, I've put in some
    "defines" to change the overall color scheme if green's not your thing. :)

    
    Other Hexagonal Pattern Examples:

    democapsid -- remaindeer 
    https://www.shadertoy.com/view/sltGDj

    sci-fi hexagons  -- laserdog 
    https://www.shadertoy.com/view/Mlcczr

    Hexagons - distance -- iq 
    https://www.shadertoy.com/view/Xd2GR3
    
    Berry stairs - duvengar
    https://www.shadertoy.com/view/Ns2GRz
    

*/

// Color scheme - Blue: 0, Red: 1, Green 2.
#define COLOR 2

// Greyscale background.
//#define GREYSCALE

// Show the hexagon grid that the pattern is based on...
// Probably a little redundant in this case, but it's there.
//#define SHOW_GRID

#define FLAT_TOP

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){ 
    // An accuracy hack for this particular example. Unfortunately, 
    // "1. - 1./3." is not always the same as "2./3." on a GPU.
    p = floor(p*32768.)/32768.;
    return fract(sin(dot(p, vec2(27.617, 57.743)))*43758.5453); 
}

// IQ's box formula.
float sBox(in vec2 p, in vec2 b){
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// A box between points. Here's it's used to draw lines, but it has
// other uses.
float lBox(vec2 p, vec2 a, vec2 b, float ew){
    
    float ang = atan(b.y - a.y, b.x - a.x);
    //p = rot2(3.14159/6.)*(p - mix(a, b, .5));
    p = rot2(ang)*(p - mix(a, b, .5));
    
   vec2 l = vec2(length(b - a), ew);
   return sBox(p, (l + ew)/2.) ;
    
   //vec2 l = abs(b - a) + ew/2.;
   //return sBox(p - vec2(mix(a.x, b.x, .5), mix(a.y, b.y, .5)), (l + ew)/2.) ;
}

// Flat top hexagon, or pointed top.
#ifdef FLAT_TOP
const vec2 s = vec2(1.732, 1);
#else
const vec2 s = vec2(1, 1.732);
#endif

// Hexagon vertex IDs. They're useful for neighboring edge comparisons, etc.
// Multiplying them by "s" gives the actual vertex postion.
#ifdef FLAT_TOP
// Vertices: Clockwise from the left.

const vec2[6] vID = vec2[6](vec2(-1./3., 0), vec2(-1./6., .5), vec2(1./6., .5), 
                      vec2(1./3., 0), vec2(1./6., -.5), vec2(-1./6., -.5)); 

const vec2[6] eID = vec2[6](vec2(-.25, .25), vec2(0, .5), vec2(.25, .25), 
                      vec2(.25, -.25), vec2(0, -.5), vec2(-.25, -.25));

#else
// Vertices: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)
const vec2[6] vID = vec2[6](vec2(-.5, -1./6.), vec2(-.5, 1./6.), vec2(0, 1./3.), 
                      vec2(.5, 1./6.), vec2(.5, -1./6.), vec2(0, -1./3.));

const vec2[6] eID = vec2[6](vec2(-.5, 0), vec2(-.25, .25), vec2(.25, .25), vec2(.5, 0), 
                      vec2(.25, -.25), vec2(-.25, -.25));

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

// Using random vertex IDs to produce animated variable sized vertices.
vec4 getSz(vec4 p, int i){

    // Sizes for each side of the edge.
    vec2 sz = vec2(hash21(p.zw + vID[i]), hash21(p.zw + vID[(i + 1)%6]))*.4 + .6;
    
    // Blinking animation variables.
    vec2 szB = vec2(hash21(p.zw + vID[i] + .1), hash21(p.zw + vID[(i + 1)%6] + .1));
    szB = smoothstep(.9, .98, sin(6.2831*szB + time*1.)*.5 + .5);
 
    // Fianl sizes.
    sz *= 1. + szB*.1;
    
    // Returning the two sizes and two blinking factors.
    return vec4(sz, szB);
}

void main(void) {

    
    // Aspect correct screen coordinates.
    float res = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/res;
    
    // Global scale factor.
    const float sc = 5.;
    // Smoothing factor.
    float sf = sc/res;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = rot2(3.14159/12.); // Scene rotation.
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1, -1)); // Light direction.
    vec2 p = sRot*uv*sc + camDir*time/3.;
    
    
    
    
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
    // Hexagonal grid coordinates for the shadow.
    vec4 p4Sh = getGrid((p - ld*.15));

   
    
        
    // Rendering the grid boundaries, or just some black hexagons in the center.
    float gHx = getHex(p4.xy);
    
    float edge = 1e5, vert = 1e5;
    float shad = 1e5;
    
    // Edge width.
    float ew = .025;
    
    // Random threshold.
    float rndTh = .4;
    #ifdef SHOW_GRID 
    // Increase the threshold so that all hexagons are rendered.
    rndTh = 1.;
    #endif
    
    float gSz = 1e5;
    
    // Random value for the top layer cell and the shadow cell.
    float rnd = hash21(p4.zw);
    float rndSh = hash21(p4Sh.zw);
     
    // Iterate through all six sides of the hexagon cell.
    for(int i = min(0, frames); i<6; i++){
   

        // If the random cell ID is under a certain threshold, render
        // from both the cell and it's neighbor's perspective.
        
        float rndN = hash21((p4.zw + eID[i]*2.));
        if(rnd<rndTh || rndN<rndTh){
        
            // Produce the edge for this particular side.
            edge = min(edge, lBox(p4.xy, vID[i]*s, vID[(i + 1)%6]*s, ew));
            
            // Edge sizes and associated animation factors.
            vec4 sz = getSz(p4, i);
            
            // Vertices at the ends of this edge.
            float v1 = length(p4.xy - vID[i]*s) - ew*6.*sz.x;
            float v2 = length(p4.xy - vID[(i + 1)%6]*s) - ew*6.*sz.y;
            
            // Save the blinking factor for vertex colorization.
            if(min(v1, v2)<vert) gSz = v1<v2? sz.z : sz.w;
            
            // Vertices for this edge.
            vert = min(vert, min(v1, v2));                                                 
            
        }
        
       
        // Doing the same for the shadow.        
        rndN = hash21((p4Sh.zw + eID[i]*2.));
        if(rndSh<rndTh || rndN<rndTh){
        
            // Shadow edge.
            shad = min(shad, lBox(p4Sh.xy, vID[i]*s, vID[(i + 1)%6]*s, ew));
            
            vec4 sz = getSz(p4Sh, i);
            
            shad = min(shad, min(length(p4Sh.xy - vID[i]*s) - ew*6.*sz.x, 
                                 length(p4Sh.xy - vID[(i + 1)%6]*s) - ew*6.*sz.y));
            
        }

    }
    
    // The scene color.
    // Rotating the gradient to coincide with the light direction angle.
    vec2 ruv = rot2(atan(ld.y, ld.x) + 3.14159/2.)*uv;
    //
    // Blue gradient background.
    vec3 bg = mix(vec3(.7, .8, 1), vec3(.7, .9, 1), smoothstep(.3, .7, ruv.y*.5 + .5));
    //
    #if COLOR == 1
    bg = bg.zyx; // Redish background.
    #elif COLOR == 2
    bg = bg.yzx; // Powder lime background.
    #endif
    
    // Saving the background gradient color sans pattern overlay.
    vec3 bgColor = bg;
    
    
    /*
    // Line pattern. Not used.
    ruv = rot2(-3.14159/6.)*p;
    float lSc = (30.*1.732/sc);
    float pat = (abs(fract(ruv.y*lSc) - .5) - .25)/lSc;
    //pat = max(pat, -(pat + .25/lSc));
    */
    
    // A higher frequency hexagon pattern for the background.
    vec4 pat4 = getGrid(p*3.);
    float patHx = (getHex(pat4.xy) - .4)/3.;
    
    // Subtly blend the hexagon pattern with the background.
    bg = mix(bg, mix(bgColor, bgColor*bgColor*.85, .35), (1. - smoothstep(0., sf, patHx)));
    //bg = mix(bg, bg*.95, (1. - smoothstep(0., sf, abs(patHx + .005) - .01))); // Borders.
    //bg = mix(bg, vec3(0), (1. - smoothstep(0., sf, pat))*.07);
    
    
    // Greyscale background, if desired.
    #ifdef GREYSCALE
    bg = vec3(1)*dot(bg, vec3(.299, .587, .114));
    #endif
    
    
    // Render the shadows onto the background.
    //shad = max(shad, -(shad + .04));
    vec3 col = mix(bg, vec3(0), (1. - smoothstep(0., sf, shad))*.25);
    
    // Rendering the edges.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, edge)));
    
    // Rendering the vertices.
    vec3 svBg = bgColor;
    svBg = mix(svBg, vec3(1), .75);
    svBg = mix(svBg, min(pow(bgColor, vec3(6))*3., 1.), gSz*.65);
    // Vertex stroke and centers.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, vert)));
    col = mix(col, svBg, (1. - smoothstep(0., sf, vert + .04)));
    
    
    // Vignette.
    //uv = gl_FragCoord.xy/resolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);;
}
