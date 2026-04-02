#version 420

// original https://www.shadertoy.com/view/XfBBWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Log Spiral Pinwheel Pattern
    ---------------------------
    
    I like pinwheel patterns. They look interesting, and they're pretty easy to
    code up. This is a subdivided pinwheel pattern... It probably has a formal
    name, but that'll do. Subdividing adds a level of complexity, but I'd still
    say this would be easy for anyone to put together.
    
    I've explained the construction below, for anyone interested. I originally
    had rounded polygons, which look nicer, but it complicated the code too
    much, so I left them out. If I find an easy way to put them back in, I'll do
    so.
  
  
    
    // Other examples:
    
    // SnoopethDuckDuck makes some pretty elegant shaders.
    Square Tiling Example - SnoopethDuckDuck
    https://www.shadertoy.com/view/fdSyWd
    
    // A pinwheel pattern using far, far less code than I did. :)
    Simpler Pinwheel Tiling - Golfed - FabriceNeyret2 
    https://www.shadertoy.com/view/Dll3Rn
    
    // A different kind of infinite pinwheel spiral. Ttoinou posts a 
    // lot of beautiful shaders.
    Pinwheel Infinite Spiral - ttoinou
    https://www.shadertoy.com/view/MdjBDm
    
*/

// Log spherical transformation.
#define LOG_SPHERICAL

// Polygon holes, or not.
#define HOLES

// Subdivide the pinwheel pattern.
#define SUBDIVIDE

// Flipping colors on either side of the screen diagonal... I wasn't
// sure about this, but I left it in. Commenting it out will produce
// a cleaner look.
#define SPLIT_COLORS

// Show the grid. If you comment out the "LOG_SPHERICAL" and "HOLES"
// defines, the structure should become a little clearer.
//#define SHOW_GRID

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}

// IQ's box formula.
float sBox(in vec2 p, in vec2 b){

  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// Different scales, depending on the transformation used.
#ifdef LOG_SPHERICAL
vec2 gSc = vec2(1)/3.;
#else
vec2 gSc = vec2(1)/4.;
#endif

// Global copy of the local coordinates.
vec2 gP;

// The pinwheel distance field.
vec4 distField(vec2 p){
    
    // Scale, cell ID and local coordinates.
    vec2 sc = gSc;
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Global copy of the local coordinates.
    gP = p;
    
    //float sq = sBox(p, sc/2.);
    
    // Grid square vertices.
    mat4x2 vID = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));
    // Mid-edge vertices. Not used here.
    //mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));
 
    // Pinwheel rotation and angle.
    float a = (smoothstep(-.15, .15, sin(time/3. + .5)) - .5)*.5*3.14159/2.;
    mat2 mR = rot2(-a);
    
    
    // Central box.
    vec2 q = mR*p;
    float vBox = sBox(q, sc/2.*abs(sin(a)));
    
    // Initiate the overall distance field, ID, and box ID.
    float d = vBox;
    vec2 id = ip;
    // Central box, and four surrounding boxes, make five.
    // The four surrounding boxes are each subdivided into a
    // further five, so that makes 21.
    int boxID = 21;
    
    // The four surrounding boxes.
    for(int i = 0; i<4; i++){
        
        q = mR*(p - vID[i]*sc);
        vBox = sBox(q, sc/2.*cos(a));
    
        if(vBox<d){
            d = vBox;
            id = ip + vID[i];
            // Prior to subdivision, there are 4 surrounding objects, 
            // plus the center.
            boxID = i; 
        }
    
    }
    
    // If we decide to subdivide and we're in one of the surrounding four boxes, 
    // move the local coordinates to the box we're subdividing and do so. You
    // can see from the pattern that the subdivision involves four larger
    // surrounding boxes.
    
    #ifdef SUBDIVIDE
    if(boxID<21){
      
      // Make copies of the distance field and IDs above.
      float sD = d;
      // Prior to subdivision, there are 4 surrounding objects, plus the center. 
      // After, there will be 20, plus the center, so we'll adjust accordingly.
      int newBoxID = boxID*5;
      vec2 oID = id;
      
      // Split the side box into five components, then choose the smallest.
      
      // Move the coordinates to the new frame of reference.
      vec2 newP = p - vID[boxID]*sc;
      gP = newP;
      boxID = newBoxID + 4;
      mR = rot2(a); // Rotating in the opposite direction this time.
      q = mR*newP;
      
      // Set the minimum distance to the subdivided central box.
      d = sBox(q, sc/2.*abs(sin(a)));
      
      // Check if the four surrounding pentagons are closer.
      for(int j = 0; j<4; j++){
          // Neighboring box.
          q = mR*(newP - vID[j]*sc);
          vBox = sBox(q, sc/2.*cos(a));
          // The maximum of the current box and its reverse rotated
          // neighboring box will form a pentagonal floret.
          float pent = max(vBox, sD);
          // Check to see if it's closer, then update.
          if(pent<d){
          
             d = pent; // New distance.
             boxID = newBoxID + j; // New box ID.
             
             id = oID + vID[j]/2.; // New position based ID.
             gP = (newP - rot2(a/2.)*vID[j]/2.*sc); // New local coordinates.
             
          }
      }
    
    }
    #endif
    
    #ifdef LOG_SPHERICAL
    // The ID needs to wrap with the angle number (see the log transformation), 
    // which is 5, in this case.
    id.y = mod(id.y, 5.);
    #endif
    
    //d = max(d, sq);
    
    // Including some holes. Standard CSG stuff.
    #ifdef HOLES
    //if((boxID%5) == 4 || boxID == 21){
    //if((boxID%5) < 4 && boxID != 21){
        
        float hSc = sc.x;

        #if 0
        float hole = length(gP);
        // Inner boxes.
        if((boxID%5) == 4 || boxID == 21) hole -= hSc/12.*abs(sin(a));
        else {
            #ifdef SUBDIVIDE
            hole -= hSc/24.*cos(a);
            #else
            hole -= hSc/12.*cos(a);
            #endif
        }
        d = max(d, -hole);
        #else
        
        #ifdef SUBDIVIDE
        d = abs(d + hSc/12.) - hSc/12.;
        #else
        if((boxID%5) == 4 || boxID == 21) d = abs(d + hSc/12.) - hSc/12.;
        else  d = abs(d + hSc/6.) - hSc/6.;
        #endif
        #endif
    //}
    #endif
    
    // Return the polygon distance, ID and position-based ID.
    return vec4(d, boxID, id);
}

// The square grid.
float gridField(vec2 p){
    
    // Scale, cell ID and local coordinates.
    vec2 sc = gSc;
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Boundary.
    p = abs(p);
    float grid = abs(max(p.x - sc.x*.5, p.y - sc.y*.5)) - sc.x*.005;
    
    return grid;
}

void main(void) {

    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Coordinate copy.
    vec2 oUV = uv;
    
    
    // Log spherical transformation. There is some ID wrapping that needs to 
    // be considered, but it's pretty standard.
    float r = 1.;
    #ifdef LOG_SPHERICAL
    r = length(uv);
    uv = vec2(log2(1./r)/2. + time/3.,fract(atan(uv.y, uv.x)/6.2831853)*5. + time/6.);
    #endif

    
    // Scaling, smoothing factor and translation.
    float cSc = 1.; // Things won't wrap at under one.
    float sf = cSc/resolution.y;
    vec2 p = uv*cSc;
    r /= cSc;

    
    #ifdef LOG_SPHERICAL
    float ew = .004; // Edge width.
    #else
    float ew = .005; // Edge width.

    // Animation, if not performing a polar transformation.
    p -= vec2(-1, -.5)*time/12.;
    #endif
    
        

    // Transformed coordinate copy.
    vec2 oP = p;

    // Highlight and regular distance field samples.
    vec4 d4Hi = distField(p - normalize(vec2(-1, -2))*.003);
    vec4 d4 = distField(p);
    
    // Multiplying the distances by the radial length for more amenable
    // field values.
    d4Hi.x *= r;
    d4.x *= r;
    
  
    // Random polygon cell colors.
    float rnd = hash21(d4.zw + .021);
    vec3 oCol = .5 + .45*cos(6.2831*rnd/4. + vec3(0, 1, 2));
    // Coloring the central squares differently.
    if(d4.y==21. || mod(d4.y, 5.)==4.){
       oCol = oCol.zyx;//mix(oCol, vec3(1), .5);
       //oCol = .5 + .45*cos(6.2831*rnd/4. + vec3(0, 1, 2).zyx*1.5 - 1.);
    }
    
    // Hacking in some beveled edges.
    #ifdef LOG_SPHERICAL
    float eCut = .03;
    #else
    float eCut = .04;
    #endif
    float b = max(max(d4Hi.x/gSc.x, -eCut) + d4Hi.x*.5 - 
                  (max(d4.x/gSc.x, -eCut) + d4.x*.5), 0.)/.003;
    oCol = oCol*(.8 + vec3(1, .9, .7)*b*.6);
    
    /*
    // Forrest (forest) cube map... Not for this example.
    vec3 tx = texture(iChannel0, 
               reflect(normalize(vec3(b, b, 1.)), normalize(vec3(oUV, 1)))).xyz;
    tx *= tx;
    oCol *= (.5 + tx);
    */
    
    // Initializing the overall color.
    vec3 col = vec3(.05);

    // Pattern edges and face color.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d4.x)));
    col = mix(col, oCol, (1. - smoothstep(0., sf, d4.x + ew)));
    
    // Diagonal split screen gradient.
    #ifdef SPLIT_COLORS
    col = mix(col, col.zyx, smoothstep(.5, .8, oUV.y + oUV.x/3. + .65));
    #endif
    
    #ifdef SHOW_GRID
    // Render the grid.
    float grid = gridField(p);
    col = mix(col, vec3(0), 
                   1. - smoothstep(0., sf*2.*resolution.y/450., grid*r - ew));
    col = mix(col, vec3(1), 1. - smoothstep(0., sf, grid*r));
    #endif
    
    // Time based color changes.
    col = mix(col.yxz, col, smoothstep(-.15, .15, sin(time/3. + .5)));
   
    
    // Rough gamma correction and screen presentation.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
