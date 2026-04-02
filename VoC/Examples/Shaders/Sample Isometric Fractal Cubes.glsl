#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttdfzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Isometric Fractal Cubes
    -----------------------    
    
    Applying simple fractal priciples to render isometric cubes in a 
    Sierpinski fashion. The result is something resembling stacked cubes.
    As you can see, this is a 2D process. However, in many ways, it
    would be easier to perform in 3D, but where's the fun in that? :)
    
    I started this a while back then forgot about it. I was motivated to 
    finish it after viewing Kali's cool polygon fractal example. Fizzer 
    also has an excellent hexagonal fractal demonstration that involves 
    similar principles. I've provided both links below for anyone 
    interested in this kind of thing.
    
    The idea behind polygon fractals is pretty simple: Render a polygon,
    subdivide space into polar cells and render more objects in each of
    those cells, subdivide the resultant cells and render more objects 
    around the newly rendered objects... Continue ad infinitum, as they say. 
    Either way, I have a much cleaner, simpler version that I'll post soon.
    
    
    
    Other 2D polygon-based fractal examples:
    
    
    // Very watchable, and with virtually no code. 
    Pen Patterns - Kali
    https://www.shadertoy.com/view/tsdfWf
    
    // A very cool hexagon fractal pattern.
    Linked Rings Fractal Tiling - Fizzer
    https://www.shadertoy.com/view/3l3fRn

*/

// Showing that you can render this on a hexagonal grid... I thought it'd look
// more interesting that it does, but it's there as an option anyway. :)
//#define REPEAT_GRID

// Simple pixelated hatch.
#define NAIVE_HATCH

// Hexagon cell scale.
#define HSCALE vec2(.5, .8660254)

// Vertices and edge midpoints: Clockwise from the left.
vec2[6] vID = vec2[6](vec2(-.5, -2./6.)/vec2(.5, 1), vec2(-.5, 2./6.)/vec2(.5, 1), vec2(0, 2./3.)/vec2(.5, 1), 
                      vec2(.5, 2./6.)/vec2(.5, 1), vec2(.5, -2./6.)/vec2(.5, 1), vec2(0, -2./3.)/vec2(.5, 1));

/*
// Hexagon arrangement. Flat top or pointed top.
//#define FLAT_TOP

// This sets the scale of the extruded shapes.
#ifdef FLAT_TOP
#define HSCALE vec2(.8660254, .5)
#else 
#define HSCALE vec2(.5, .8660254)
#endif

#ifdef FLAT_TOP
//  Vertices and edge midpoints: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)
vec2[6] vID = vec2[6](vec2(-2./3., 0)/vec2(1, .5), vec2(-2./6., .5)/vec2(1, .5), vec2(2./6., .5)/vec2(1, .5), 
                      vec2(2./3., 0)/vec2(1, .5), vec2(2./6., -.5)/vec2(1, .5), vec2(-2./6., -.5)/vec2(1, .5)); 
vec2[6] eID = vec2[6](vec2(-.5, .25)/vec2(1, .5), vec2(0, .5)/vec2(1, .5), vec2(.5, .25)/vec2(1, .5), 
                      vec2(.5, -.25)/vec2(1, .5), vec2(0, -.5)/vec2(1, .5), vec2(-.5, -.25)/vec2(1, .5));
#else
// Vertices and edge midpoints: Clockwise from the left.
vec2[6] vID = vec2[6](vec2(-.5, -2./6.)/vec2(.5, 1), vec2(-.5, 2./6.)/vec2(.5, 1), vec2(0, 2./3.)/vec2(.5, 1), 
                      vec2(.5, 2./6.)/vec2(.5, 1), vec2(.5, -2./6.)/vec2(.5, 1), vec2(0, -2./3.)/vec2(.5, 1));
vec2[6] eID = vec2[6](vec2(-.5, 0)/vec2(.5, 1), vec2(-.25, .5)/vec2(.5, 1), vec2(.25, .5)/vec2(.5, 1), vec2(.5, 0)/vec2(.5, 1), 
                      vec2(.25, -.5)/vec2(.5, 1), vec2(-.25, -.5)/vec2(.5, 1));
#endif
*/
////////

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

#ifdef REPEAT_GRID
// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    vec2 s = HSCALE;
    vec4 ip = floor(vec4(p/s, p/s - .5));
    vec4 q = p.xyxy - vec4(ip.xy + .5, ip.zw + 1.)*s.xyxy;
    return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy) : vec4(q.zw, ip.zw + .5);

}
#endif

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

// Hexagon bound -- Accurate enough for this example.
float hDist(vec2 p, float sc){
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x) - sc;
}

// Entirely based on IQ's signed distance to a 2D triangle -- Very handy.
// I have a generalized version somewhere that's a little more succinct,
// so I'll track that down and drop it in later.
float quad(in vec2 p, in vec2[4] q){

    vec2 e0 = q[1] - q[0];
    vec2 e1 = q[2] - q[1];
    vec2 e2 = q[3] - q[2];
    vec2 e3 = q[0] - q[3];

    vec2 v0 = p - q[0];
    vec2 v1 = p - q[1];
    vec2 v2 = p - q[2];
    vec2 v3 = p - q[3];

    vec2 pq0 = v0 - e0*clamp(dot(v0, e0)/dot(e0, e0), 0., 1.);
    vec2 pq1 = v1 - e1*clamp(dot(v1, e1)/dot(e1, e1), 0., 1.);
    vec2 pq2 = v2 - e2*clamp(dot(v2, e2)/dot(e2, e2), 0., 1.);
    vec2 pq3 = v3 - e3*clamp(dot(v3, e3)/dot(e3, e3), 0., 1.);
    
    float s = sign(e0.x*e3.y - e0.y*e3.x);
    vec2 d = min( min( vec2(dot(pq0, pq0), s*(v0.x*e0.y - v0.y*e0.x)),
                       vec2(dot(pq1, pq1), s*(v1.x*e1.y - v1.y*e1.x))),
                       vec2(dot(pq2, pq2), s*(v2.x*e2.y - v2.y*e2.x)));
    
    d = min(d, vec2(dot(pq3, pq3), s*(v3.x*e3.y-v3.y*e3.x)));

    return -sqrt(d.x)*sign(d.y);
}

// Returns the 3 viewable cube face distances.
vec3 cubeQuads(vec2 p, float sc){

    vec2 hSc = HSCALE*sc;
    vec3 d;
    
    // Iterate through the three cube faces.
    for(int j = 0; j<3; j++){
        
        // Using the hexagon vertices to constructing the 3 viewable cube quad faces.
        vec2[4] v = vec2[4](vID[(j*2 + 5)%6]*hSc, vID[(j*2)%6]*hSc, vID[(j*2 + 1)%6]*hSc, vec2(0));

        // Face quad.
        d[j] = quad(p, v);
            
    }
    
    return d;

}

void main(void) {

    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Scaling and translation.
    const float gSc = 1.;//2./3.;
    
    // Smoothing factor.
    float sf = gSc/resolution.y;
    
    // Scaling, translation, etc.
    vec2 p = uv*gSc + vec2(1, 0)*time/4.;//HSCALE*time/4.;
    
    vec2 oP = p;
   
    p.y += 1./8./gSc; 
    
  
    #ifdef REPEAT_GRID
    vec4 p4 = getGrid(p); 
    vec2 id = (p4.zw + .5)*HSCALE;//
    p = p4.xy;
    #else
    vec2 id = floor(vec2(p.x*.8660254, 0));
    p.x -= (id.x + .5)/.8660254;
    //float ndg = .25*pow(.5, 5.);
    //p.x = mod(p.x, sqrt(3.)/2. + ndg) - (sqrt(3.)/2. + ndg)*.5;
    #endif
 
     // Distance field holders for the cubes, lines and the previous
    // cube (used for CSG related to overlap).
    float d = 1e5, ln = 1e5, prevD = 1e5; 
    
    // Edge width. 
    const float ew = .0015;
    
    // Render a simple gradient background... There'd be a neater way to do
    // this, but I was in a hurry. :)
    float shd = .5 - uv.y*.5;
    vec3 bg = mix(vec3(.25, .5, 1).xzy, vec3(.25, .5, 1), 1./(1. + shd*shd));
    bg = mix(bg, bg.zyx, .5*shd*shd);
    vec3 col = bg;
    
    
    // Cube scale and height. These will be scaled further on each fractal level.
    float sc = .25;
    float sch = sc/.8660254;
    
    // Shadow normal and shadow scale.
    vec2 n = normalize(vec2(1, -2));
    float shF = resolution.y/450.; // Shadow resize factor.
    float scSh = .025*shF;
    
    
    vec2 cntr = vec2(0);
    
    #ifdef REPEAT_GRID
    int nn = 4;
    #else
    int nn = 3 + int(abs(mod(id.x, 4.) - 2.));
    #endif
    
    for(int i = 0; i<nn; i++){
    
        
        #ifndef REPEAT_GRID 
        if(mod(id.x, 3.)<1.5 && hash21(id + cntr + .1)<float(i)/float(nn)*.5) break;
        #endif
        
         
        
        float rnd = hash21(id + cntr);
        float rnd2 = hash21(id + cntr + .17);
        
        #ifdef REPEAT_GRID 
        rnd = (float((i + 2)%nn))*.3;
        #endif
      
        // Fake AO and drop shadow.
        float dsh = hDist(p, sc);
        col = mix(col, vec3(0)*.1, (1. - smoothstep(0., sf*10.*shF, dsh))*.2);
        dsh = hDist(p - n*scSh, sc);
        col = mix(col, vec3(1.1, 1, .9)*.1, (1. - smoothstep(0., sf*10.*shF, dsh))*.3);
        scSh *= .7;
        
        // Obtain the individual cube face quad distances. There are three
        // visible to the viewer.
        vec3 d3 = cubeQuads(p, sc*2.);
        
        
        // Iterate through the cube faces for this level.
        for(int j = 0; j<3; j++){
            
            // Face ID... A mixture of common sense and trial and error, as always. :D
            int fid = 2 - (i - j + 4)%3;
            
            // Normal based shade.
            float sh = .5 + (float(fid)/2.)*.5;
            // Distance based shade.
            float shd = max(1. + d3[j]/sc/2., 0.);
            
            // Produce a shaded color for the face.
            vec3 fCol = .65 + .35*cos(6.2831*rnd/2.5 + vec3(0, 1, 2) - 1.);
            fCol *= sh*sh*1.5;
            if(i<nn - 1) fCol *= vec3(1)*shd;
            
            // Render the shaded face color and a mild inner edge.
            col = mix(col, min(fCol, 1.), (1. - smoothstep(0., sf, d3[j])));
            col = mix(col, vec3(0), (1. - smoothstep(0., sf, abs( d3[j] + ew*5.5) - ew/2.))*.5);
       
            
        
        }
        
        
        // Apply edges over the top of the quads.
        float cube = min(min(d3[0], d3[1]), d3[2]);
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, abs(cube) - ew/2.))*.95);
       
        // Cube centers, for debugging purposes.
        //col = mix(col, vec3(0), 1. - smoothstep(0., sf, length(p) - .015));
        
        // Here's the fun polar fractal stuff.. And by that I mean, it wasn't fun. It never is. :D
        // Having said that, it's based on a simple fractal setup, which involves making 
        // copies of objects, then rendering them in coordinated places at different scales,
        // rotations, etc.
        
        // Obtain three repeat polar angles around the cube.
        float aNum = 3.;
        p = rot2(6.2831/6.)*p;
        float a = mod(atan(p.x, p.y), 6.2831);
        float ia = floor(a/6.2831*aNum);
        ia = (ia + .5)/aNum*6.2831;
        
        // Rotate the object by this particular polar angle.
        p = rot2(ia)*p;
        // Move it out from the object at the angle above.
        p -= vec2(0, sch);
        // Rotate the object in situ.
        p = rot2(ia*2.)*p;

        
        // Do the same for the object center. The center doubles
        // as a unique ID point, which is used for coloring.
        cntr = rot2(6.2831/6.)*cntr;
        cntr = rot2(ia)*cntr;
        cntr += vec2(0, sch);
        cntr = rot2(ia*2.)*cntr;
        
        // Rotate the shadow direction vector to in unison with the
        // above, so the shadows face the same way on each cube -- Note 
        // that normal translation isn't necessary... Sometimes, 2D is 
        // more annoying than 3D. :) 
        n = rot2(6.2831/6.)*n;
        n = rot2(ia)*n;
        n = rot2(ia*2.)*n;
        
     
        // Reduce vertical cube distace and scale for the next iteration.
        sch *= .5; // Reduce scale height.
        sc *= .5; // Reduce scale.
        
         
        
     
    }
    
    // Apply a simple pixelated hatch to give the scene an oldschool look.
    #ifdef NAIVE_HATCH
    float hatch = doHatch(oP/gSc, resolution.y);
    col *= hatch*.35 + .8;
    #endif

    // Rough gamma correction and output to screen.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
