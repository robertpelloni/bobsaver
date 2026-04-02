#version 420

// original https://www.shadertoy.com/view/Wdd3DX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    
    Geometric Grid Pattern
    ----------------------

    I have a lot of grid pattern examples lying around. They're not exactly cutting edge, 
    but I find them quick to construct and visually interesting, which makes them suitable 
    texture add-ins for 3D scenes, or to provide the basis for the geometry itself.

      I see patterns that follow this particular rectangular strip concept all the time, but 
    usually in the form of randomly rotated cell segments. This version consists of 4 by 4 
    cell blocks that have been rotated in a specific predetermined order, in accordance with 
    array pattern entries. I'd imagine people could code this up without too much hassle, 
    and probably in more efficient ways, but for anyone interested, the workings and 
    explanation are below. I've kept the code reasonably short.

    Other Examples:

    // Using simple square geometry to great effect.
    Truchet variation - XT95
    https://www.shadertoy.com/view/llfBWB

    // Flyguy has a lot of clean but interestig exapmles.
    Material Design Pattern  - FlyGuy
    https://www.shadertoy.com/view/XsySWc

    // Clever.
    Escher-like tiling (255 chars) - FabriceNeyret2  
    https://www.shadertoy.com/view/4dVGzd

*/

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// This renders a horizontal or vertical box-line from point "a" to point "b," with a line 
// width of "w." It's different to the the usual line formula because it doesn't render the 
// rounded caps on the end -- Sometimes, you don't want those. It utilizes IQ's box formula 
// and was put together in a hurry, so I'd imagine there are more efficient ways to do the 
// same, but it gets the job done. I put together a more generalized angular line formula as 
// well.
float lBoxHV(vec2 p, vec2 a, vec2 b, float w){
    
   vec2 l = abs(b - a); // Box-line length.
   p -= vec2(mix(a.x, b.x, .5), mix(a.y, b.y, .5)); // Positioning the box center.
   
   // Applying the above to IQ's box distance formula.
   vec2 d = abs(p) - (l + w)/2.; 
   return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// Number of bar lines. As you can see from the imagery, there are five. Different numbers are
// interesting, but numbers in this range obviously visualize better.
#define N 5
const float Nf = float(N);

vec3 distField(vec2 p){
    
    vec2 ip = floor(p); // Cell ID.
    p -= ip + .5; // Centered local coordinates.
   
    // A lot of grid patterns are formed by rendering specific patterns in cells, then
    // randomly rotating them -- Truchets are a good example. Others can be formed by rotating
    // patterns according to a simple formula, like rotating alternate checkered cells. Others, 
    // however, need to be rotated according to specific sequence that might not be as easy to
    // define with a simple formula, in which case it makes more sense to simply hardcode them,
    // so that's what is happening here. Each 4x4 cell block is rotated according to the 4x4
    // cell block sequence below.
    // 
    // In this case, you could use a mat4, if you wanted, but the following is a little more 
    // readable, and can be extended to include any "N x M" arrangement.
    float ad[16] = float[16](3., 0., 1., 0.,
                             0., 3., 0., 1.,
                             3., 2., 1., 2.,
                             2., 3., 2., 1.);
    
    // Rotate the local grid coordinates according to the 4x4 sequence above. For instance, the
    // second cell on the third row has a value of "2," which results in 2 90-degree rotations.
    // The cell to the right of it has a value of "1," so will result in 1 90-degree rotation.
    int index = int(floor(mod(ip.x, 4.) + mod(4. - ip.y, 4.)*4.));
    float cID = ad[index];
    
    // Rotate the cell by multiples of 90 degrees, according to the 4x4 cell block array above.
    p = rot2(cID*3.14159/2.)*p;
     
    // Line width, cell object (box-line) ID, and box-line distance value.
    float w = 1./Nf, bID = -1., d = 1e5;
    
    // Render a series of bar-graph vertical lines that shorten with increasing X-value across
    // the cell, then fill in the rest of the space with the equivalent horizontal lines. Refer to 
    // the imagery to get a better idea. By the way, I've been doing this for years, and nothing 
    // below require math skills beyond grade school, yet I never get it right the first time. Sigh. :)
    for(int i = 0; i<N; i++){
        
        float fi = float(i);
        
        // Vertical and horizontal bar-graph like boxs of width "w." 
        float vBox = lBoxHV(p, vec2(-.5 + w/2. + fi*w, -.5 + w/2.), vec2(-.5 + w/2. + fi*w, .5 - w/2. - fi*w), w);
        float hBox = lBoxHV(p, vec2(-.5 + w/2. + (fi + 1.)*w, .5 - w/2. - fi*w), vec2(.5 - w/2., .5 - w/2. - fi*w), w);
       
        // Give the individual vertical and horizontal boxes their own unique ID (not to be confused
        // with the overall individual cell ID). These will be used later to shade and color the 
        // box lines. Again, refer to the imagery.
        if(vBox<d){ d = vBox; bID = fi; }
        if(hBox<d && i<N - 1){ d = hBox; bID = fi + Nf; }
         
    } 
     
    // Return the object distance, cell ID and individual cell object ID.
    return vec3(d, cID, bID);
    
}

void main(void) {

    // Aspect correct screen coordinates.
    float iRes = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
    
    // Scaling and translation.
    float gSc = 6.;
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera in the north east (top right) direction. 
    vec2 p = uv*gSc - vec2(-1, -.5)*time;
    
    // Smoothing factor -- based on the resolution and global scaling factor.
    float sf = gSc/iRes;

    // The distance field. It returns the block 
    vec3 d = distField(p);
    
    // Record the individual cell ID and the ID of the individual object 
    // within the cell.
    float cID = d.y;
    float bID = d.z;
    
    
    // Shade and color the cell contents, according to the cell object ID.
    //
    // Shade: Outer horizontal and vertical bars are lighter.
    float idSh = (Nf - 1. - mod(bID, Nf))/(Nf - 1.); 
    // Color, which is reliant on shade, meaning uter horizontal and vertical bars will
    // have lighter palette (a fiery variation) colors.
    vec3 dCol = pow(min(vec3(1.35, 1.02, 1)*mix(.3, .925, idSh), 1.), vec3(1, 2.25, 8.));
    
    // A blue-flame shaded complimentary color to the above.
    vec3 shCol = mix(dCol, dCol.zyx, .9); // Mixing in just a touch of the original color

    // Use the cell ID and cell object ID to apply the blue shaded color.
    //
    // Top left, X, sans frame.
    if(bID>.5 && bID<(Nf - .5) && mod(cID, 4.)==2.) dCol = shCol;
    // Top right, X and Y, sans frame.
    if(bID!=0. && bID!=Nf && mod(cID, 4.)==3.) dCol = shCol;
    // Bottom right, Y, sans frame.
    if(bID>(Nf + .5) && mod(cID, 0.)==0.) dCol = shCol;
    
    /*
    // The palette color gives the depth, but you can apply extra depth, if desired.
    vec2 q = rot2(svID*3.14159/2.)*p;
    q = fract(q) - .5;
    float lDist = max(1. - length(q - vec2(-.5, .5).yx), 0.);
    float sh = 1./(1. + lDist*lDist*4.);
    dCol = min(dCol*sh*1.25, 1.);
    */
    
    
    // Render the cell contents: I.e. The individually colored and shaded bar-graph lines. The 
    // "sqrt(450./iRes)" term is just a hack to give the dark lines around the borders some 
    // consistency with resolution changes. Catering to canvas size changes is almost futile. :)
    vec3 col = mix(vec3(0), dCol, 1. - smoothstep(0., sf, d.x + .02*sqrt(450./iRes)));// + .42/(Nf + 1.)
 
    // Run a bit of a texturized layer over the top. Comment it out, if you prefer
    // a cleaner version.
    //vec3 tx = texture(iChannel0, p/gSc*2.).xyz; tx *= tx;
    //tx = min(smoothstep(-.1, .3, tx)*1.1, 1.);
    //col *= tx;
    

    // Apply some subtle line overlays.
    vec2 pt = rot2(6.2831/3.)*p;
    float pat2 = clamp(cos(pt.x*6.2831*28.*iRes/450.)*2. + 1.5, 0., 1.);
    col *= pat2*.4 + .7;
    
    
    // Applying a subtle silhouette, for art's sake.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./16.); 

    
    // Rough gamma correction, then output to the screen..
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
