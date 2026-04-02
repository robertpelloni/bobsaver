#version 420

// original https://www.shadertoy.com/view/WdtGWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Sketched Geometric Pattern
    --------------------------

    A geometric pattern rendered in a pseudo sketch style. The example itself
    isn't cutting edge, but there are a heap of other define options below that 
    seek to demonstrate how various changes can effect the look and feel of a 
    basic geometric rendering.

    I have a lot of examples lying around that are only mildly interesting, but 
    might be of use to people, so I might start putting them up.

    If I had the time, I could quite happily submit simple geometric patterns
    all day. One of the things I like to do is render some simplistic objects in
    a grid, relate them to one another in some way, then start adding rendering
    layers, such as shadows, strokes, highlights, etc.

    Geometrically speaking, this example is about as easy as it gets. I'd 
    originally given the smaller squares some animation, but decided to 
    concentrate on the rendering side of things instead. The individual 
    postprocessing functions aren't that taxing either. However, when you put it 
    all together, the code blows out a little. Having said that, this isn't 
    really a treatise on shader coding, but rather a rendering style 
    demonstration.

    Similar Examples:

    There are too many to list, but Fabrice Neyret has heaps of cool little 
    examples that cover various grid patterns.

*/

// Postprocessing directives. Turning most of these on or off can completely
// change the feel of the image.

// Simple overlays. To see the sketch properly, set the color option to 
// grayscale. The sketch algorithm itself is just a cheap substandard 
// process, based on Flockaroo's fancy one. Having said that, it's still
// reasonably effective.
#define SKETCH
//#define LINE_OVERLAY 
//#define NAIVE_HATCH // I made this up a while back, and find it useful.
#define PAPER_GRAIN

// Shadows almost always look better, but there are times when they might
// overcook things a little. I think they enhance this example, but it's
// all a matter of personal requirements. Turning them off gives it a 
// fresher, more naive, rendering style, which can sometimes be preferable.
#define SHADOWS

// Highlights -- Usually performed by taking a nearby sample, then adding a
// variation on the difference.
#define HIGHLIGHTS

// Palettes: Not many, but I might add more.
//#define GRAYSCALE
//#define GRAY_WITH_COLOR
//#define CANDY_PALETTE
#define RANDOM_COLOR_FLIP
//#define VARIED_PALETTE
//#define REVERSE_PALETTE

// The object shape. Just three, but I might add others in due course.
// 0: Slightly rounded square, 1: Circle, 2: Octagon, of sorts.
#define SHAPE 0

// Picture frame variation.
//#define FRAMES

// Display mazelines or partial lines. The partial lines look more sketch-like, 
// so they're on by default. They're rendered in a cell offset fashion
// reminiscent of Voronoi.
//#define MAZELINES
#define PARTIAL_LINES

// Display the square cell grid boundaries. It's there for debug purposes,
// but has a certain aesthetic appeal.
//#define SHOW_GRID

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(27, 57)));
    return fract(vec2(262144, 32768)*n)*2. - 1.; 
    
    // Animated.
    //p = fract(vec2(262144, 32768)*n);
    //return sin(p*6.2831853 + time); 
    
}

// Based on IQ's gradient noise formula.
float n2D3G( in vec2 p ){
   
    vec2 i = floor(p); p -= i;
    
    vec4 v;
    v.x = dot(hash22(i), p);
    v.y = dot(hash22(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22(i + 1.), p - 1.);

#if 1
    // Quintic interpolation.
    p = p*p*p*(p*(p*6. - 15.) + 10.);
#else
    // Cubic interpolation.
    p = p*p*(3. - 2.*p);
#endif

    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
    //return v.x + p.x*(v.y - v.x) + p.y*(v.z - v.x) + p.x*p.y*(v.x - v.y - v.z + v.w);
}

// A hatch-like algorithm, or a stipple... or some kind of textured pattern.
float doHatch(vec2 p, float res){
    
    
    // The pattern is physically based, so needs to factor in screen resolution.
    p *= res/16.;

    // Random looking diagonal hatch lines.
    float hatch = clamp(sin((p.x - p.y)*3.14159*200.)*2. + .5, 0., 1.); // Diagonal lines.

    // Slight randomization of the diagonal lines, but the trick is to do it with
    // tiny squares instead of pixels.
    float hRnd = hash21(floor(p*6.) + .73);
    if(hRnd>.66) hatch = hRnd;  

    return hatch;

    
}

// IQ's box function with a smoothing factor added.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
    vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
}

// IQ's standard box function.
float sBox(in vec2 p, in vec2 b){
   
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// This will draw a box (no caps) of width "ew" from point "a "to "b". I hacked
// it together pretty quickly. It seems to work, but I'm pretty sure it could be
// improved on. In fact, if anyone would like to do that, I'd be grateful. :)
float lBox(vec2 p, vec2 a, vec2 b, float ew){
    
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));
    
   vec2 l = vec2(length(b - a), ew);
   return sBox(p, (l + ew)/2.) ;
}

// A distance function containing some basic shapes.
float dist(in vec2 p, in vec2 b){
    
    // Just in case the shape directive is accidentally commented out.
    #ifdef SHAPE
    
    #if SHAPE == 0
    // Slightly rounded square.
    return sBoxS(p, b, sqrt(b.x)*.1);
    #elif SHAPE == 1
    // Circle.
    return length(p) - b.x*1.05;
    #else
    // Octagon, of sorts.
    p = abs(p);
    return max(max(p.x, p.y), (p.x + p.y)*.7071 - b.x/6.) - b.x;
    #endif
    
    #else
    return sBoxS(p, b, sqrt(b.x)*.1);
    #endif
}

// Hacky global scale and global ID... I must've been in a hurry when putting 
//this together. :)
const float gSc = 5.5;
vec2 gID;

vec3 pattern(vec2 p){
    
    
    // Grid ID and local coordinates.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    
    // Distance field container. One for the lines, one for the larger objects,
    // and another for the smaller objects rendered over the top.
    vec3 d = vec3(1e5);
    
    
    // Render some boxes with various sizes in a checkboard fashion.
    float w = (mod(ip.x + ip.y, 2.)>.5)? .28 : .44;
    float s = dist(p, vec2(w));
    d.y = min(d.y, s);
    
    #ifdef FRAMES
    float ody = d.y;
    d.y = max(d.y, -(d.y + .15)); // Picture frame variation.
    #endif
    
    
    // Randomly offset the smaller boxes.
    vec2 rnd = hash22(ip);
    // Random offset factor.
    const float rF = .125;
    
    // Smaller boxes over the top of the larger boxes.
    if(mod(ip.x + ip.y, 2.)<.5){
        
        w = .2;
        s = dist(p - rnd*rF, vec2(w));

        d.z = min(d.z, s);
        #ifdef FRAMES
        d.z = max(d.z, -(d.z + .15)); // Picture frame variation.
        //d.z = max(d.z, -(d.z + .18)); 
        #endif
        
    }
    
    // Line thickness.
    float ew = .011;
       
    
    // Render some lines. It looks more difficult than it is. Basically, read
    // the offset position to each of the four cell neighbors, then render a
    // line between them. There's a maze variation in there too.
    if(mod(ip.x + ip.y, 2.)<.5){
        
        #ifdef MAZELINES
        float rnd3L = hash21(ip + vec2(-1, 0));
        float rnd3T = hash21(ip + vec2(0, 1));
        float rnd3R = hash21(ip + vec2(1, 0));
        float rnd3B = hash21(ip + vec2(0, -1));
        
        if(rnd3L<.5) d.x = min(d.x, lBox(p, vec2(-1, 0), rnd*rF, ew/2.));
        if(rnd3T>=.5) d.x = min(d.x, lBox(p, vec2(0, 1), rnd*rF, ew/2.));
        if(rnd3R<.5) d.x = min(d.x, lBox(p, vec2(1, 0), rnd*rF, ew/2.));
        if(rnd3B>=.5) d.x = min(d.x, lBox(p, vec2(0, -1), rnd*rF, ew/2.)); 
        #else
        #ifndef PARTIAL_LINES
        d.x = min(d.x, lBox(p, vec2(-1, 0), rnd*rF, ew/2.));
        d.x = min(d.x, lBox(p, vec2(0, 1), rnd*rF, ew/2.));
        d.x = min(d.x, lBox(p, vec2(1, 0), rnd*rF, ew/2.));
        d.x = min(d.x, lBox(p, vec2(0, -1), rnd*rF, ew/2.));
        #endif
        #endif
        
        
    }
    else {
        
        vec2 rndL = hash22(ip + vec2(-1, 0));
        vec2 rndT = hash22(ip + vec2(0, 1));
        vec2 rndR = hash22(ip + vec2(1, 0));
        vec2 rndB = hash22(ip + vec2(0, -1));

        
        #ifdef MAZELINES
        float rnd3 = hash21(ip);
        if(rnd3<.5){
            d.x = min(d.x, lBox(p, vec2(-1, 0) + rndL*rF, vec2(0), ew/2.));
            d.x = min(d.x, lBox(p, vec2(1, 0) + rndR*rF, vec2(0), ew/2.));
            
        }    
        else {
            d.x = min(d.x, lBox(p, vec2(0, 1) + rndT*rF, vec2(0), ew/2.));
            d.x = min(d.x, lBox(p, vec2(0, -1) + rndB*rF, vec2(0), ew/2.));
        }
        #else
        d.x = min(d.x, lBox(p, vec2(-1, 0) + rndL*rF, vec2(0), ew/2.));
        d.x = min(d.x, lBox(p, vec2(1, 0) + rndR*rF, vec2(0), ew/2.));
        d.x = min(d.x, lBox(p, vec2(0, 1) + rndT*rF, vec2(0), ew/2.));
        d.x = min(d.x, lBox(p, vec2(0, -1) + rndB*rF, vec2(0), ew/2.));
        #endif
        
        
    }
      
    // Straight lines.
    //d.x = min(d.x, lBox(p, vec2(0, -.5), vec2(0, .5), ew/2.));
    //d.x = min(d.x, lBox(p, vec2(-.5, 0), vec2(.5, 0), ew/2.)); 
    
    // Cut away the lines from the middle of the frame. You don't have to,
    // but I prefer it.
    #ifdef FRAMES
    d.x = max(d.x, -ody);
    #endif
    
    // Set the global ID to the cell object ID. Hacky coding --- There are
    // better ways to do this. :)
    gID = ip;
    
    // Return the distance functions.
    return d;
}

// The square grid.
float gridField(vec2 p){
    
    p = abs(fract(p) - .5);
    float grid = abs(max(p.x, p.y) - .5) - .015;
    
    return grid;
}

vec3 pencil(vec3 col, vec2 p){
    
    // Rough pencil color overlay... The calculations are rough... Very rough, in fact, 
    // since I'm only using a small overlayed portion of it. Flockaroo does a much, much 
    // better pencil sketch algorithm here:
    //
    // When Voxels Wed Pixels - Flockaroo 
    // https://www.shadertoy.com/view/MsKfRw
    //
    // Anyway, the idea is very simple: Render a layer of noise, stretched out along one 
    // of the directions, then mix a similar, but rotated, layer on top. Whilst doing this,
    // compare each layer to it's underlying greyscale value, and take the difference...
    // I probably could have described it better, but hopefully, the code will make it 
    // more clear. :)
    // 
    // Tweaked to suit the brush stroke size.
    vec2 q = p*4.;
    //q += vec2(n2D3G(oP*1.5), n2D3G(oP*1.5 + 7.3))*.1;
    q *= rot2(-3.14159/2.5);
    // I always forget this bit. Without it, the grey scale value will be above one, 
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.);
    // Underlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(.299, .587, .114)));
    // Stretched fBm noise layer.
    float ns = (n2D3G(q*4.*vec2(1./3., 3))*.64 + n2D3G(q*8.*vec2(1./3., 3))*.34)*.5 + .5;
    // Compare it to the underlying grey scale value.
    ns = gr - ns;
    //
    // Repeat the process with a couple of extra rotated layers.
    q *= rot2(3.14159/2.);
    float ns2 = (n2D3G(q*4.*vec2(1./3., 3))*.64 + n2D3G(q*8.*vec2(1./3., 3))*.34)*.5 + .5;
    ns2 = gr - ns2;
    q *= rot2(-3.14159/5.);
    float ns3 = (n2D3G(q*4.*vec2(1./3., 3))*.64 + n2D3G(q*8.*vec2(1./3., 3))*.34)*.5 + .5;
    ns3 = gr - ns3;
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense, 
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    ns = smoothstep(0., 1., min(min(ns, ns2), ns3)*2. + .25); // Rough pencil sketch layer.
    //
    // Mix in a small portion of the pencil sketch layer with the clean colored one.
    //col = mix(col, col*(ns + .3), .75);
    // Has more of a colored pencil feel. 
    col *= vec3(.8)*ns + .5;    
    // Using Photoshop mixes, like screen, overlay, etc, gives more visual options. Here's 
    // an example, but there's plenty more. Be sure to uncomment the "softLight" function.
    //col = softLight(col, vec3(ns)*.75);
    // Uncomment this to see the pencil sketch layer only.
    //if(mod(ip.x + ip.y, 2.)<.5) 
    // Grayscale override.
    #ifdef GRAYSCALE
    col = vec3(ns); 
    #endif
    
    #ifdef GRAY_WITH_COLOR
    col = vec3(ns); 
    #endif
    
    return col;
    
}

void main(void) {
    

    // Aspect correct screen coordinates.
    float iRes = min(resolution.y, 750.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
    
    // Scaling and translation.
    
    // You could rotate also, if you felt like it: rot2(a)*uv...
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera to the north east (top right) direction. 
    vec2 p = uv*gSc - vec2(-1, -.5)*time;
    
    // Keeping a copy of the background vector.
    vec2 oP = p;

    // The smoothing factor -- based on scale.
    float sf = 1./resolution.y*gSc;
  
    // Wobbling the coordinates, just a touch, in order to give a subtle hand drawn appearance.
    p += vec2(n2D3G(p*3.5), n2D3G(p*3.5 + 7.3))*.02;
    
    // Optional cell boundary display.
    #ifdef SHOW_GRID
    float grid = gridField(p);
    #endif
    
    // Take two pattern samples, and save the IDs. I made the IDs global out
    // of sheer laziness. :D
    vec3 d = pattern(p);
    vec2 ip = gID;
    vec3 d2 = pattern(p - vec2(.05, -.05));
    vec2 ip2 = gID;
    //col = mix(col2, col.xzy, dot(col2, vec3(.299, .587, .114)));
 
    // Highlighting the large and smaller objects. How you do that is up to you, but you
    // have to produce two samples, then take the difference. Here, I've mixed the 
    // distance field value with a blurrier smoothstepped version of it, then compared
    // it to the other sample. You have to keep the resultant value above zero, since 
    // negative highlight values don't make a lot of physical sense.
    float ba = mix(d.y, smoothstep(0., sf*4., d.y), .35);
    float bb = mix(d2.y, smoothstep(0., sf*4., d2.y), .35);
    float b = max(bb - ba, 0.)/.07;
    ba = mix(d.z, smoothstep(0., sf*4., d.z), .35);
    bb = mix(d2.z, smoothstep(0., sf*4., d2.z), .35);
    float b2 = max(bb - ba, 0.)/.07;
    
    

    // Set the background to a... brown paper bag color? It must've been in 
    // style at the time. :)
    vec3 col = vec3(.725, .7, .675);
    
    // Add a very subtle portion of the highlights to the background.
    #ifdef HIGHLIGHTS
    col *= (1. + (b)*.03);
    #endif
    
    // Apply the line shadows and the fist layer object shadows.
    #ifdef SHADOWS
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*1.65, d2.x))*.9);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d2.y))*.9);
    #endif
    
    
    // Some random numbers, for random palette production and so forth.
    vec2 rnd = hash22(ip)*.5 + .5;
    vec2 rndb = hash22(ip + .25)*.5 + .5;
    vec2 rndc = hash22(ip + .35)*.5 + .5;
    
    
    // Use the random numbers above to produce a couple of varying layer palettes.
    //
    // First layer color.
    vec3 lCol = vec3(1, .25 + rndb.x*.55, .2 + rndb.y*.6);
    
    // Second layer color.
    vec3 lCol2 = (vec3(1, .5 + rndc.y*.5, .2 + rndc.x*.5)*.8 + .2);
    
    #ifdef CANDY_PALETTE
    // Fabrices candy colored palette.
    lCol = .62 + .25*cos(6.3*rndb.x + vec3(0, 23, 21));
    lCol2 = .65 + .16*cos(6.3*rndb.x + vec3(0, 23, 21) + .5);
    #endif
    
    #ifdef VARIED_PALETTE
    lCol = (1. - vec3(1, .25 + rndb.x*.75, .2 + rndb.y*.8).zyx*.5);
    #endif

    #ifdef RANDOM_COLOR_FLIP
    // Flip the colors on some tiles.
    //if(mod(ip.x + ip.y, 2.)<.5){ 
        if(rnd.x<.35) lCol = lCol.xzy;
    //}
    
        if(rnd.y<.35) lCol2 = lCol2.xzy;
    #endif
    
    #ifdef HIGHLIGHTS
    lCol *= (.95 + b*.25);
    lCol2 *= (.95 + b2*.25); 
    #endif
    //lCol2 = vec3(1)*dot(lCol2, vec3(.299, .587, .114));

    // Edge width.
    float ew = .0175;
    
    // The background lines.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*1.65, d.x)));
  
    
    // The larger outer objects.
    col = mix(col, vec3(0), (1. - smoothstep(-sf, sf, d.y - ew)));
    col = mix(col, lCol, (1. - smoothstep(-sf, sf, d.y + ew)));
   
    // The smaller object overlays.
    #ifdef SHADOWS
    col = mix(col, vec3(0), (1. - smoothstep(-sf, sf, d2.z - ew))*.9);
    #endif
    col = mix(col, vec3(0), (1. - smoothstep(-sf, sf, d.z - ew)));
    col = mix(col, lCol2, (1. - smoothstep(-sf, sf, d.z + ew)));
    
    
    #ifdef SHOW_GRID
    // Display the grid boundaries. Usually used for debug purposes.
    col = mix(col, vec3(1), (1. - smoothstep(0., sf*2., grid - .02))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid)));
    #endif
    
    
    // POST PROCESSING
    
    #ifdef SKETCH
    // Applying a very basic pencil shading look.
    // Based on one of Flockaroo's pencil sketch algorithms.
    col = pencil(col, oP);
    #else    
        #ifdef GRAYSCALE
        col = vec3(1)*dot(col, vec3(.289, .597, .114));
        #endif
        #ifdef GRAY_WITH_COLOR
        col = vec3(1)*dot(col, vec3(.289, .597, .114));
       #endif
    #endif
    

    #ifdef GRAY_WITH_COLOR
    vec3 svCol = col;
    
    float rndh = hash21(ip + .17);
    if(mod(ip.x + ip.y, 2.)>.5 && rndh<.5) col = mix(col, col*vec3(.5, .8, 1), 1. - smoothstep(0., sf, d.y));
    if(rndh<.35) col = mix(col, svCol*vec3(1, .2, .4), 1. - smoothstep(0., sf, d.z));
    
    //if(hash21(ip + .17)<.3)col = mix(col, svCol*vec3(.5, .8, 1), 1. - smoothstep(0., sf, d.z));
    //else if(hash21(ip + .17)<.6) col = mix(col, svCol*vec3(1, .2, .4), 1. - smoothstep(0., sf, d.z));
    #endif

    #ifdef LINE_OVERLAY
    // Just some line overlays.
    vec2 pt = p;
    float offs = -.5;
    //if(i<.5) offs += 2.;//pt.xy = -pt.xy;
    pt = rot2(6.2831/3.)*pt;
    float pat2 = clamp(cos(pt.x*6.2831*28. - offs)*2. + 1.5, 0., 1.);
    col *= pat2*.4 + .7;
    #endif
    
    #ifdef NAIVE_HATCH
    float hatch = doHatch(oP/gSc, iRes);
    col *= hatch*.5 + .7;
    #endif
    
    #ifdef PAPER_GRAIN
    // Cheap paper grain.
    oP = floor(oP/gSc*1024.);
    vec3 rn3 = vec3(hash21(oP), hash21(oP + 2.37), hash21(oP + 4.83));
    col *= .9 + .1*rn3.xyz  + .1*rn3.xxx;
    #endif
    
    col *= vec3(1.1, 1, .9);
    
    #ifdef REVERSE_PALETTE
    col = col.zyx;
    #endif
    
    // Subtle vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= min(pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./8.)*1.2, 1.);
    
    // Output to screen
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
