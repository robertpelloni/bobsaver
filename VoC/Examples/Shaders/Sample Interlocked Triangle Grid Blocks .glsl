#version 420

// original https://www.shadertoy.com/view/XffBzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Interlocked Triangle Grid Blocks
    --------------------------------
    
    Using a triangle grid to produce a cliche geometric block design... I'm not
    exactly sure how you'd describe the pattern in the mathematical sense, but it's 
    very common in the geometric stock image world.
    
    There'd be numerous ways to produce this, and I'm pretty certain that I didn't
    choose the best one. To be fair, these things tend to be hand drawn. In fact, 
    I've never seen it produced algorithmically, so consider this a first attempt. 
    
    I chose a triangle grid, because I figured that would require the least amount 
    of rendering, but with the benefit of hindsight, a hexagon grid-based approach 
    might have made life easier, so don't take the code too seriously.
    
    Basically, I've rendered a few quads at strategic places within each triangle. 
    If you wish to see the repeat nature of the pattern, uncomment the "SHOW_GRID" 
    define and comment out the "INNER_EDGES" one. 
    
    Hopefully, Fabrice Neyret -- or someone along those lines, will eventually see 
    this and render it in a more efficient way. In fact, it'd be great to see more 
    of the less common grid-based patterns in general.
 
 
 
    
    Other patterns:
    
    // Just one of many simple patterns that can be created with
    // a triangle grid.
    tuto: triangle/hex coord + 3syms - FabriceNeyret2
    Other Hexagonal Pattern Examples:

    
    // There are so many triangle grid-based patterns on here. I like the
    // way this one looks, and the way it was produced.
    Sine Wave Tiling - fizzer
    https://www.shadertoy.com/view/fdtXRn
    

*/

// Color scheme - Primary and grey: 0, Secondary and grey: 1, 
// Red and colors: 2, Earthtone: 3, Greyscale: 4.
#define COLOR 0

// Coloring the inner edges.
//#define COL_EDGES

// Applying a subtle pencil sketch style.
#define PENCIL

// Show inner edges. Taking them away allows you to see the geometric
// pattern a little more clearly.
#define INNER_EDGES

// Faux ambient occlusion... I did it in a hurry, so it needs work.
#define AO

// Show the triangle grid that the pattern is constructed from.
//#define SHOW_GRID

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    
}

////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning. By the way, this
// will partition all repeat grid triangles, not just equilateral ones.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
const float scale = 1./4.5;
 
float gTri;

vec4 getTriVerts(in vec2 p, inout mat3x2 vID, inout mat3x2 v){

    // Rectangle scale.
    const vec2 rect = (vec2(1./.8660254, 1))*scale;

    // Skewing half way along X, and not skewing in the Y direction.
    const vec2 sk = vec2(rect.x*.5, 0)/scale; // 12 x .2

    // Skew the XY plane coordinates.
    p = skewXY(p, sk);
    
    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
    vec2 id = floor(p/rect) + .5; 
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
    p -= id*rect; 
    
    
    // Equivalent to: 
    //gTri = p.x/rect.x < -p.y/rect.y? 1. : -1.;
    // Base on the bottom (-1.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 1. : -1.;
   
    // Puting the skewed coordinates back into unskewed form.
    p = unskewXY(p, sk);
    
    
    // Vertex IDs for each partitioned triangle: The numbers are inflated
    // by a factor of 3 to ensure vertex IDs are precisely the same. The
    // reason behind it is that "1. - 1./3." is not always the same as
    // "2./3" on a GPU, which can mess up hash logic. However, "3. - 2."
    // is always the same as "1.". Yeah, incorporating hacks is annoying, 
    // but GPUs don't work as nicely as our brains do, unfortunately. :)
    if(gTri<0.){
        vID = mat3x2(vec2(-1.5, 1.5), vec2(1.5, -1.5), vec2(1.5));
    }
    else {
        vID = mat3x2(vec2(1.5, -1.5), vec2(-1.5, 1.5), vec2(-1.5));
    }
    
    // Triangle vertex points.
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect/3., sk); // Unskew.
    
    // Centering at the zero point.
    vec2 ctr = v[2]/3.; // Equilateral equivalent to: (v[0] + v[1] + v[2])/3;
    p -= ctr;
    v[0] -= ctr; v[1] -= ctr; v[2] -= ctr;
    
     // Centered ID, taking the inflation factor of three into account.
    vec2 ctrID = vID[2]/3.; //(vID[0] + vID[1] + vID[2])/3.;//vID[2]/2.; //
    id = id*3. + ctrID;   
    // Since these are out by a factor of three, "v = vertID*rect/3.".
    vID[0] -= ctrID; vID[1] -= ctrID; vID[2] -= ctrID;

    // Triangle local coordinates (centered at the zero point) and 
    // the central position point (which acts as a unique identifier).
    return vec4(p, id);
}

/*
// IQ;s signed distance to an equilateral triangle.
// https://www.shadertoy.com/view/Xl2yDW
float sdEqTri(in vec2 p, in float r){

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if(p.x + k*p.y>0.) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.;
    p.x -= clamp(p.x, -2.*r, 0.);
    return -length(p)*sign(p.y);
}
*/

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

////////////////
// Compact, self-contained version of IQ's 2D value noise function.
float n2D(vec2 p){
   
    // Setup.
    // Any random integers will work, but this particular
    // combination works well.
    const vec2 s = vec2(1, 113);
    // Unique cell ID and local coordinates.
    vec2 ip = floor(p); p -= ip;
    // Vertex IDs.
    vec4 h = vec4(0., s.x, s.y, s.x + s.y) + dot(ip, s);
   
    // Smoothing.
    p = p*p*(3. - 2.*p);
    //p *= p*p*(p*(p*6. - 15.) + 10.); // Smoother.
   
    // Random values for the square vertices.
    h = fract(sin(mod(h, 6.2831589))*43758.5453);
   
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }

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
    const vec2 sc = vec2(1, 12);
    q += (vec2(n2D(q*4.), n2D(q*4. + 7.3)) - .5)*.03;
    q *= rot2(-3.14159/2.5);
    // Extra toning.
    col /= 1./3. + dot(col, vec3(.299, .587, .114));
    // I always forget this bit. Without it, the grey scale value will be above one, 
    // resulting in the extra bright spots not having any hatching over the top.
    col = min(col, 1.);
    // Underlying grey scale pixel value -- Tweaked for contrast and brightness.
    float gr = (dot(col, vec3(.299, .587, .114)));
    // Stretched fBm noise layer.
    float ns = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    // Compare it to the underlying grey scale value.
    ns = gr - ns;
    //
    // Repeat the process with a couple of extra rotated layers.
    q *= rot2(3.14159/2.);
    float ns2 = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    ns2 = gr - ns2;
    q *= rot2(-3.14159/5.);
    float ns3 = (n2D(q*sc)*.64 + n2D(q*2.*sc)*.34);
    ns3 = gr - ns3;
    //
    // Mix the two layers in some way to suit your needs. Flockaroo applied common sense, 
    // and used a smooth threshold, which works better than the dumb things I was trying. :)
    ns = min(min(ns, ns2), ns3) + .5; // Rough pencil sketch layer.
    //ns = smoothstep(0., 1., min(min(ns, ns2), ns3) + .5); // Same, but with contrast.
    // 
    // Return the pencil sketch value.
    return vec3(ns);
    
}

// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop. However,
   // this isn't a GPU intensive example, so it doesn't matter here.
   //return max(dot(p - ro, n), 0.)/max(dot(rd, n), 1e-8);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   
   //return dn>0.? max(dot(p - ro, n), 0.)/dn : 1e8;   

} 

// Block size.
float getSize(float sL, vec2 ip){
   
   //return sL/4.5;//
   //return sL*(sin(ip.y/6. - cos(ip.x/4. + time*2.)*1.57)*.25 + .5)/2.5;
   return mix(sL/6., sL/3.25, smoothstep(.5, .7, sin(6.2831*hash21(ip) + time)*.5 + .5));
   //return mix(sL/8., sL/2.5, hash21(ip));

}

// Block color.
vec3 getCol(vec3 a, vec3 b){

 
    float rnd = hash31(a);//hash31(a + b);
    float rnd2 = hash31(a + .23);//hash31(a + b + .1);
    float rnd3 = hash31(a + .34);//hash31(a + b + .1);
    float rnd4 = hash31(a + .41);//hash31(a + b + .1);
        
    //vec3 col = .5 + .4*cos(6.2831589*rnd/4. + vec3(0, 1, 2));
    vec3 col = mix(a, b, .25);
  
    #if COLOR < 2
    if(rnd2<.4) col = mix(col, vec3(1.2)*dot(col, vec3(.299, .587, .114)), .9);
    #endif
    
    #if COLOR == 4
    col = mix(col, vec3(1.2)*dot(col, vec3(.299, .587, .114)), .9);
    #endif
    
    #if COLOR < 3
    if(rnd3<.35){
    
        #if COLOR < 2
        col = col.zyx;
        #else
        if(rnd4<.33) col = col.zyx;
        else if(rnd4<.66) col = col.yxz;
        else col = col.xzy/(3. + col.xzy)*3.5;
        #endif
    }
    #endif
    
    #if COLOR==1
    col = col.yxz;
    col /= (3. + col)/3.5;
    #endif
    
    return col;

}

// Inner edge color.
vec3 getEdgeCol(vec3 a){

    #ifdef COL_EDGES
    a *= vec3(1.2, 1, .8);
    #endif
    return (a + .9)*a;
}

void main(void) {

    
    // Aspect correct screen coordinates.
    float res = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/res;
    
    // Global scale factor.
    const float sc = 1.;
    // Smoothing factor.
    float sf = sc/res;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = mat2(1, 0, 0, 1);//rot2(3.14159/12.); // Scene rotation.
    vec2 camDir = sRot*normalize(vec2(1.732, 1)); // Camera movement direction.
    vec2 ld = sRot*normalize(vec2(1, -1)); // Light direction.
    vec2 p = sRot*uv*sc + camDir*time*scale/3.;
    
    // Perturbing coordinates for that unpredictable hand-drawn feel.
    #ifdef PENCIL
    vec2 offs = vec2(fbm(p*64.), fbm(p*64. + .35));
    const float oFct = .001;
    p -= (offs - .5)*oFct;  
    #endif
 
    // Keep a copy of the overall coordinates.
    vec2 oP = p;
    
    // Vertex IDs and vertice points.
    mat3x2 vID, v;
    
    // Returns the local coordinates (centered on zero), cellID, the 
    // triangle vertex ID and relative coordinates.
    vec4 p4 = getTriVerts(p, vID, v);
    // Local cell coordinates
    p = p4.xy;
    // Unique triangle ID (cell position based).
    vec2 ctrID = p4.zw; 
    

    // Equilateral triangle cell side length.
    float sL = length(v[0] - v[1]);
    
 
    
    // Edge width.
    #ifdef PENCIL
    float ew = .0055*(fbm(p*40.)*.35 + .65);
    #else
    float ew = .004;
    #endif
    
    // Precalculating the edge points and edge IDs. You could do this inside
    // the triangle grid function, but here will be fine.
    mat3x2 e, eID;
    for(int i = 0; i<3; i++){
        int ip1 = (i + 1)%3;
        eID[i] = mix(vID[i], vID[ip1], .5);
        e[i] = mix(v[i], v[ip1], .5);
    }
 
    
    // Quads.
    vec3 quad = vec3(1e5);  // Large quads.
    vec3 quad1 = vec3(1e5); // Block tops.
    vec3 quad2 = vec3(1e5); // Block sides (in the triangle centers).
    vec3 quad3 = vec3(1e5); // Block ends.

    // A dividing line varible -- I think it's used to divide an "L" shape
    // into two quads, or something like that.
    vec3 lnDivC;

    // Producing the quads. I haven't provided a great explanation here. However,
    // a lot of it is simple: Start with the triangle vertices, then move points
    // out by various angle vectors to produce the remaining quad points, etc.
    //
    for(int i = 0; i<3; i++){
    
        int ip1 = (i + 1)%3;
        int ip2 = (i + 2)%3;
        
        // Varibale rotation angle and matrix. 
        float ang = -3.14159/32.;
        mat2 rA = rot2(ang);
        
          
        // Three ray line intersection points.
        vec2 rd = -rA*normalize(v[i]);
        float t = rayLine(v[i], rd, v[ip2], rot2(ang)*normalize(v[ip2].yx*vec2(1, -1)));
        
        // Start at the vertex positions, then render slightly rotated lines that meet
        // one another just past the center.
        vec2 rV0 = v[i] - rA*normalize(v[i])*t;
        vec2 rV1 = v[ip1] - rA*normalize(v[ip1])*t;
        vec2 rV2 = v[ip2] - rA*normalize(v[ip2])*t;
        
        
        // Dividing lines.
        float ln0 = distLineS(p, rV0, v[i]);
        //float ln1 = distLineS(p, rV1, v[ip1]);
        float ln2 = distLineS(p, rV2, v[ip2]);

        
        // Large quads and block tops.
        quad[i] = max(ln0, -ln2);
        
        // Small inner triangle side length.
        float triL = length(rV0 - rV2);
 
        
        // Different dividing lines, quads, etc, for the opposing triangles.
        if(gTri>0.){ 
    
            // Random small side length.
            float smSL = getSize(sL, ctrID + eID[ip2]*2.);
         
            // More dividing lines.
            float lnA = distLineS(p, rV0, rV1);   
            float lnB = distLineS(p, rV1, rV2); 
            float lnC = distLineS(p, rV2, rV0); 
            
            // Line between points rV0 and rV1, pushed out by the base height 
            // of the triangle.
            quad1[i] = max(lnA + (t - smSL - triL)*.8660254, lnB - triL*.8660254);  

            // Chips on the sides.
            quad2[(i + 1)%3] = max(-lnC + (t - smSL - triL)*.8660254, -(lnB - triL*.8660254)); 
    
            // Line to split the "L" shape into two quads.
            vec2 sp = rV0 - normalize(rV2 - v[ip2])*(t - triL - smSL);
            lnDivC[i] = -distLineS(p, sp, sp + rV1 - rV0);

      
        } 
        else {
        
            // Random small side length.
            float smSL = getSize(sL, ctrID); 
        
            // Key points.
            vec2 rVA = rV0 + normalize(v[i] - rV0)*(triL + smSL); 
            vec2 rVB = rVA + normalize(v[ip2] - rV2)*(smSL); 
            vec2 rVC = rVB - normalize(v[i] - rV0)*(triL + smSL); 
            vec2 rVD = rV0 - normalize(v[i] - rV0)*smSL; 

        
            // Various dividing lines -- Used to construct the quads.
            float lnA = distLineS(p, rV1, rVB);
            float lnB = distLineS(p, rVB, rVC);
            float lnC = distLineS(p, rVC, rVD);
            float lnD = distLineS(p, rVD, rV1);  
            
            // Inner quad panel points.
            quad1[i] = max(max(lnA, lnB), max(lnC, lnD));

            // Line to split the "L" shape into two quads.
            lnDivC[i] = -distLineS(p, rVB, rVB + rV0 - v[i]);
        
        }
        
    
    }
    
    
    // Combined quads.
    float quads = min(min(quad1[0], quad1[1]), quad1[2]);
    quads = min(quads, min(min(quad2[0], quad2[1]), quad2[2]));
    quads = min(quads, min(min(quad3[0], quad3[1]), quad3[2]));
    
    // More CSG quad construction.
    for(int i = 0; i<3; i++){         
         quad3[(i + 1)%3] = max(max(quad[i], -quads), -lnDivC[i]); // Ends.
         quad[i] = max(quad[i], lnDivC[i]);
    }
    
  
    // Overall color, shade and random color variables.
    vec3 col = vec3(.1);
    vec3 shade = vec3(.9, .6, .3);
    vec3 c3B[3];
    
    #ifdef INNER_EDGES
    float rmW = sL/32.;
    #else
    float rmW = -ew*1.25;
    #endif
    
    // Set block colors.
    vec3[3] c3 = vec3[3](vec3(1, 1, .5), vec3(.2, .4, 1), vec3(1, .3, .6));
 
    // Rendering the main quads.
    for(int i = 0; i<3; i++){
    
        // Random block color.
        vec2 id = gTri<0.? ctrID : ctrID + eID[(i + 2)%3]*2.;
        // 
        c3B[i] = .5 + .45*cos(6.2831589*hash21(id)/6. + vec3(0, 1, 2)*1.2);

        // Shaded color.
        vec3 lCol = getCol(c3B[i], c3[i])*shade[i];
        
        // Top face.
        #ifdef AO
        col = mix(col, col*.5, (1. - smoothstep(0., sf*24.*res/450., quad[i])));
        #endif
        #ifdef INNER_EDGES
        col = mix(col, getEdgeCol(lCol), (1. - smoothstep(0., sf, quad[i] + ew)));
        col = mix(col, col*.2, (1. - smoothstep(0., sf, quad[i] + rmW + ew)));
        #endif
        col = mix(col, lCol, (1. - smoothstep(0., sf, quad[i] + rmW + ew*2.)));
        
    }
    
    // Rendering the rest of the smaller quads.
    for(int i = 0; i<3; i++){
    
        int ip1 = (i + 1)%3;
        int ip2 = (i + 2)%3;

        // Shaded color.
        vec3 lCol = getCol(c3B[i], c3[i])*shade[ip1];
        
        // Other faces.
        #ifdef INNER_EDGES
        col = mix(col, getEdgeCol(lCol), (1. - smoothstep(0., sf, quad1[i] + ew)));
        col = mix(col, col*.2, (1. - smoothstep(0., sf, quad1[i] + rmW + ew)));
        #endif
        col = mix(col, lCol, (1. - smoothstep(0., sf, quad1[i] + rmW + ew*2.)));
 
 
        lCol = getCol(c3B[ip2], c3[i])*shade[ip1];
        #ifdef INNER_EDGES
        col = mix(col, getEdgeCol(lCol), (1. - smoothstep(0., sf, quad2[i] + ew)));
        col = mix(col, col*.2, (1. - smoothstep(0., sf, quad2[i] + rmW + ew)));
        #endif
        col = mix(col, lCol, (1. - smoothstep(0., sf, quad2[i] + rmW + ew*2.)));

        lCol = getCol(c3B[ip2], c3[i])*shade[ip2];
        #ifdef INNER_EDGES
        col = mix(col, getEdgeCol(lCol), (1. - smoothstep(0., sf, quad3[i] + ew)));
        col = mix(col, col*.2, (1. - smoothstep(0., sf, quad3[i] + rmW + ew)));
        #endif
        col = mix(col, lCol, (1. - smoothstep(0., sf, quad3[i] + rmW + ew*2.)));

    }
    
    
    
    // Faux anisotopic effect.
    //float oShp = min(min(quad[0], quad[1]), quad[2]);
    //col *= (1. - smoothstep(0., 1., -oShp/sL*8.)) + .65;
    // Fake ambient occlusion.
    #ifdef AO
    col *= (smoothstep(0., .5, length(p)/sL))*.85 + .5;
    #endif
    
    /*
    // Color gradient.
    vec2 uv2 = gl_FragCoord.xy/resolution.xy;
    uv2 = smoothstep(.2, .8, uv2);
    col = mix(col.xzy, col, mix(uv2.x, uv2.y, .66)*.7 + .3);
    */
    
    
    
    // Display the background grid.
    #ifdef SHOW_GRID
    float ln = 1e5;
    // Lines between vertices.
    for(int i = 0; i<3; i++){
         ln = min(ln, distLine(p, v[i], v[(i + 1)%3]));
         //ln = min(ln, distLine(p, vec2(0), e[i]));
    }

    vec3 svCol = col;
    col = mix(col, col*.1, (1. - smoothstep(0., sf, ln - .005)));
    col = mix(col, svCol + .5, (1. - smoothstep(0., sf, ln - .001)));
    #endif

    
    #ifdef PENCIL
    // Subtle pencel overlay... It's cheap and definitely not production worthy,
    // but it works well enough for the purpose of the example. The idea is based
    // off of one of Flockaroo's examples.
    vec2 q = oP*9.;
    vec3 colP = pencil(col, q*res/450.);
    col *= colP*1.5 + .5; 
    //col = colP; 
    #endif

    
    /*
    // Vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);
    */
    
    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);;
}
