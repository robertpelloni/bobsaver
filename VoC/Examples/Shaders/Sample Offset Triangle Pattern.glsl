#version 420

// original https://www.shadertoy.com/view/3tlfDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Offset Triangle Pattern
    -----------------------

    Just something I coded for fun. It's an offset triangle pattern in the form 
    of an instant algorithmic Zentangle work, which completely defeats the purpose 
    of the Zentangle methodology, but here it is anyway. :)
    
    The idea is pretty simple. Render an offset triangle grid, then with the minimum 
    returned triangle information, render a pattern inside it. I see this particular 
    arrangement a lot. The Zentangle crowd make things like this all the time... 
    Although, they have the benefit of hand drawing, whereas I had to make do with 
    time constraints, some rushed math and half the artistic talent. :D

    You can happily ignore most of the code and just use the "blocks" function to
    obtain the required triangle information, then take it from there. I'm going
    to put up a few more examples along these lines. I might also put together an 
    offset triangle jigsaw pattern at some stage.

    Related examples:

    // Mattz put one of these together ages ago.
    ice and fire - mattz
    https://www.shadertoy.com/view/MdfBzl

    // An offset triangle heightfield -- Very cool. I have one of these coming
    // that takes a different approach.
    Triangulated Heightfield Trick 3 - fizzer
    https://www.shadertoy.com/view/ttsSzX

    // An extruded offset triangle grid.
    Extruded Offset Triangle Grid - Shane
    https://www.shadertoy.com/view/WtsfzM

*/

// Offsetting the triangle coordinates. The look is a lot cleaner without it.
#define OFFSET_TRIS

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// vec2 to vec2 hash.
vec2 hash22B(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(1, 113)));
    p = fract(vec2(262144, 32768)*n)*2. - 1.; 
    return sin(p*6.2831853 + time/2.); 
}

// vec2 to vec2 hash.
vec2 hash22C(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(289, 41)));
    p = fract(vec2(262144, 32768)*n)*2. - 1.; 
    return sin(p*6.2831853 + time); 
}

// Based on IQ's gradient noise formula.
float n2D3G( in vec2 p ){
   
    // Cell ID and local coordinates.
    vec2 i = floor(p); p -= i;
    
    // Four corner samples.
    vec4 v;
    v.x = dot(hash22C(i), p);
    v.y = dot(hash22C(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22C(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22C(i + 1.), p - 1.);

    // Cubic interpolation.
    p = p*p*(3. - 2.*p);
    
    // Bilinear interpolation -- Along X, along Y, then mix.
    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
    
}

// Two layers of noise.
float fBm(vec2 p){ return n2D3G(p)*.57 + n2D3G(p*2.)*.28 + n2D3G(p*4.)*.15; }

// IQ's signed distance to a 2D triangle.
float sdTri(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2){
 
    vec2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;

    vec2 v0 = p - p0, v1 = p - p1, v2 = p - p2;

    vec2 pq0 = v0 - e0*clamp( dot(v0, e0)/dot(e0, e0), 0., 1.);
    vec2 pq1 = v1 - e1*clamp( dot(v1, e1)/dot(e1, e1), 0., 1.);
    vec2 pq2 = v2 - e2*clamp( dot(v2, e2)/dot(e2, e2), 0., 1.);
    
    float s = sign( e0.x*e2.y - e0.y*e2.x);
    vec2 d = min( min( vec2(dot(pq0, pq0), s*(v0.x*e0.y - v0.y*e0.x)),
                       vec2(dot(pq1, pq1), s*(v1.x*e1.y - v1.y*e1.x))),
                       vec2(dot(pq2, pq2), s*(v2.x*e2.y - v2.y*e2.x)));

    return -sqrt(d.x)*sign(d.y);
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

// Triangle's incenter and radius.
vec3 inCentRad(vec2 p0, vec2 p1, vec2 p2){
    
    // Side lengths.
    float bc = length(p1 - p2), ac = length(p0 - p2), ab = length(p0 - p1);
    vec2 inCir = (bc*p0 + ac*p1 + ab*p2)/(bc + ac + ab);   
    
    // Area.
    float p = (bc + ac + ab)/2.;
    float area = sqrt(p*(p - bc)*(p - ac)*(p - ab));
    
    return vec3(inCir, area/p);
}

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){
    
    return mat2(1, -s.y, -s.x, 1)*p;
}

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){
    
    //float idm = 1. - s.x*s.y;
    //if(idm == 0.) idm += 1e-6;
    //mat2 inM = 1./(idm)*mat2(1, s.y, s.x, 1);
    //return inM*p;
    return inverse(mat2(1, -s.y, -s.x, 1))*p;
}

/*

// Rounded triangle routine. Not used here, but handy.
float sdTriR(vec2 p, vec2 v0, vec2 v1, vec2 v2){
     
    vec3 inC = inCentRad(v0, v1, v2);
    float ndg = .0002/inC.z;
    return sdTri(p, v0 - (v0 - inC.xy)*ndg,  v1 - (v1 - inC.xy)*ndg,  v2 - (v2 - inC.xy)*ndg) - .0002;      
        
}  

// Rectangle dimentions, and consequently, the grid dimensions.
//const vec2 rect = vec2(1.25, .8)*scale;
//const vec2 rect = vec2(1., 1.5)*scale;
// Equilateral dimensions: Basically, the base needs to be lengthened by
// a factor involving sqrt(3), which easily relates back to equilateral geometry.
//const vec2 rect = (vec2(1./.8660254, 1))*scale; // "1/.8660254 = 2*sqrt(3)/3". 

// Skewing half way along X, and not skewing in the Y direction. Skewing is 
// inversely effected by scale.
//const vec2 sk = vec2(rect.x*.5, 0)/scale;
// Irregular skewing is possible too, since it's all just math.
//const vec2 sk = vec2(rect.x*.5, -rect.y*.25)/scale;

// From the the following example:
// Random Delaunay Triangulation - Tomkh
// https://www.shadertoy.com/view/4sKyRD
//
// Use "parabolic lifting" method to calculate if two triangles are about to flip.
// This is actually more reliable than circumscribed circle method.
// The technique is based on duality between Delaunay Triangulation
// and Convex Hull, where DT is just a boundary of convex hull
// of projected seeds onto paraboloid.
// We project (h1 h2 h3) triangle onto paraboloid
// and return the distance of the origin
// to a plane crossing projected triangle.
float flipDistance(vec2 h1, vec2 h2, vec2 h3){

   // Projects triangle on paraboloid.
   vec3 g1 = vec3(h1, dot(h1, h1));
   vec3 g2 = vec3(h2, dot(h2, h2));
   vec3 g3 = vec3(h3, dot(h3, h3));
   // Return signed distance of (g1, g2, g3) plane to the origin.
   //#if FLIP_ANIMATION
    // return dot(g1, normalize(cross(g3-g1, g2-g1)));
   //#else
     // If we don't do animation, we are only interested in a sign,
     // so normalization is unnecessary.
        return dot(g1, cross(g3-g1, g2-g1));
   //#endif
}
*/

// Global vertices, local coordinates, etc, of the triangle cell.
struct triS{
    
    vec2[3] v; // Outer vertices.
    vec2 p; // Local coordinate.
    vec2 id; // Position based ID.
    float dist; // Distance field value.
    float triID; // Triangle ID.
};

// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.

triS blocks(vec2 q){
    

    const float tf = 2./sqrt(3.);
    // Scale.
    const vec2 scale = vec2(tf, 1)*vec2(1./4.);

    // Brick dimension: Length to height ratio with additional scaling.
    const vec2 dim = vec2(scale);
    // A helper vector, but basically, it's the size of the repeat cell.
    const vec2 s = dim*2.;
    
     // Skewing half way along X, and not skewing in the Y direction.
    const vec2 sk = vec2(tf/2., 0);
    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual block ID and block center.
    vec2 id = vec2(0), cntr;
    
    // For block corner postions.
    const vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5), vec2(.5, -.5), vec2(-.5)); 
    
    float triID = 0.; // Triangle ID. Not used in this example, but helpful.

    // Height scale.
    const float hs = .5;

    // Initializing the global vertices and local coordinates of the triangle cell.
    triS gT, tri1, tri2;
    
    for(int i = 0; i<4; i++){

        // Block center.
        cntr = ps4[i]/2. -  ps4[0];
        // Skewed local coordinates.
        p = skewXY(q.xy, sk);// - cntr*s;
        ip = floor(p/s - cntr) + .5; // Local tile ID.
        p -= (ip + cntr)*s; // New local position.
        // Unskew the local coordinates.
        p = unskewXY(p, sk);
        
       
        // Correct positional individual tile ID.
        vec2 idi = ip + cntr;
 
        // Skewed rectangle vertices. 
        vec2[4] vert = ps4;  
     
        #ifdef OFFSET_TRIS
        // Offsetting the vertices.
        vert[0] += hash22B((idi + vert[0]/2.))*.2;
           vert[1] += hash22B((idi + vert[1]/2.))*.2;
        vert[2] += hash22B((idi + vert[2]/2.))*.2; 
        vert[3] += hash22B((idi + vert[3]/2.))*.2;
        #endif
        
        
        // Unskewing to enable rendering back in normal space.
        vert[0] = unskewXY(vert[0]*dim, sk);
        vert[1] = unskewXY(vert[1]*dim, sk);
        vert[2] = unskewXY(vert[2]*dim, sk);
        vert[3] = unskewXY(vert[3]*dim, sk); 
        
         
        // Unskewing the rectangular cell ID.
        idi = unskewXY(idi*s, sk);  
  
      
        // Some triangle flipping to ensure a Delaunay triangulation... Further non-Delaunay
        // subdivisions will occur, so it's probably redundant, but it's here for completeness.
        //float f = flipDistance(vert[0] - vert[2], vert[1] - vert[2], vert[3] - vert[2])<0.? 1. : -1.;
 
        
        // Partioning the rectangle into two triangles.
        
        
        // Triangle one.
        tri1.v = vec2[3](vert[0], vert[1], vert[2]); 
         //if(f>.5) tri1.v = vec2[3](vert[0], vert[1], vert[3]); // Delaunay flipping.
        tri1.id = idi + inCentRad(tri1.v[0], tri1.v[1], tri1.v[2]).xy; // Position Id.
        tri1.triID = float(i); // Triangle ID. Not used here.
        tri1.dist = sdTri(p, tri1.v[0], tri1.v[1], tri1.v[2]); // Field distance.
         
        // Triangle two.
        tri2.v = vec2[3](vert[0], vert[2], vert[3]);
        //if(f>.5) tri2.v = vec2[3](vert[1], vert[2], vert[3]);  // Delaunay flipping.
        tri2.id = idi + inCentRad(tri2.v[0], tri2.v[1], tri2.v[2]).xy; // Position Id.
        tri1.triID = float(i + 4); // Triangle ID. Not used here.
        tri2.dist = sdTri(p, tri2.v[0], tri2.v[1], tri2.v[2]); // Field distance.
         
        // Doesn't work, unfortunately, so I need to write an ugly "if" statement.
        //triS gTi = tri1.dist<tri2.dist? tri1 : tri2;
        triS gTi; 
        // Obtain the closest triangle information.
        if(tri1.dist<tri2.dist) gTi = tri1; 
        else gTi = tri2;
        
        
        // If applicable, update the overall minimum distance value,
        // then return the correct triangle information.
        if(gTi.dist<d){
            d = gTi.dist;
            gT = gTi;
            gT.p = p;
            //gT.id = idi + inCentRad(gT.v[0], gT.v[1], gT.v[2]).xy;
        }
        
    }
    
    // Return the distance, position-based ID and triangle ID.
    return gT;
}

/*

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

*/

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
    vec2 q = p*24.;
    q += vec2(n2D3G(p*1.5), n2D3G(p*1.5 + 7.3))*.1;
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
    ns = smoothstep(0., 1., min(min(ns, ns2), ns3) + .6); // Rough pencil sketch layer.
    //
    // Mix in a small portion of the pencil sketch layer with the clean colored one.
    //col = mix(col, col*(ns + .3), .5);
    // Has more of a colored pencil feel. 
    //col *= vec3(.8)*ns + .4;    
    // Using Photoshop mixes, like screen, overlay, etc, gives more visual options. Here's 
    // an example, but there's plenty more. Be sure to uncomment the "softLight" function.
    //col = softLight(col, vec3(ns)*.75);
    // Uncomment this to see the pencil sketch layer only.
    //if(mod(ip.x + ip.y, 2.)<.5) 
    // Grayscale override.
    
    col = vec3(ns); 
    
 
    
    return col;
    
}

void main(void) {

    // Resolution and aspect correct screen coordinates.
    float iRes = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes; 
    
    // Warping the background ever so slightly. The idea is that
    // pencil drawings don't have perfectly straight lines.
    uv += vec2(fBm(uv*12.), fBm(uv*12. + .5))*.005;
    
    
    // Unit direction vector. Used for some mock lighting.
    vec3 rd = normalize(vec3(uv, .5));
    
    // Scaling and translation.
    const float gSc = 1.;
    vec2 p = uv*gSc;// + vec2(0, time/24.);
    vec2 oP = p; // Saving a copy for later.
    
    // Resolution and scale based smoothing factor.
    float sf = gSc/resolution.y;
    
    
    // Take a function sample. 
    triS gT = blocks(p);
    
 
    // Triangle vertices, local coordinates and position-based ID.
    // With these three things, you can render anything you want.
    vec2[3] svV = gT.v;
    vec2 svP = gT.p;
    vec2 svID = gT.id;

    
    // Initializing the scene color to black.
    vec3 col = vec3(0);  
     
    // Triangle color.
    vec3 tCol = vec3(0);
    
    
  
    // Bottom layer color, or shade.
    vec3 lCol = vec3(.05);
     
    
    
    // The triangle pattern: Render three wedged triangles with vertex points
    // at each line edge extreme and a third point on the adjacent tangential
    // edge (look at the top layer for a visual). Slide the adjacent edge
    // point back a bit, then render another layer. If you do this a few times,
    // a triangular spiral pattern will appear. You can add to the effect by
    // coloring and shading according to layer depth.
    //
    // The following is just the way I chose to effect the aforementioned, but 
    // there'd no doubt be better ways to go about it, so how you achieve the 
    // same is up to you.
    //  
    vec3 triPat = vec3(1e5);
    
    vec2[3] v = svV;
    
    vec2 rp = svP;
    //rp = rot2(time)*rp;
  
    // Start and end nudge factors. The third point needs to be moved along
    // a tangent edge. The further out it is, the more the triangles 
    // appear to rotate.
    
  
    float nfs = .45, nff = .07;
    const int iter = 4; // Iterations.
    for(int i = 0; i<iter; i++){
        
        // Normalized edge tangent vectors.
        vec2[3] tng = vec2[3](normalize(v[1] - v[0]), normalize(v[2] - v[1]),
                           normalize(v[0] - v[2])); 
        
        lCol *= 1.8; // Increase the color for each layer.
        
        // Interpolate the nudge point factor.
        float nf = mix(nfs, nff, float(i)/float(iter));

        // Three side triangles for this particular layer, which consist of 
        // two vertices and a third point that slides out from the adjoining
        // side... Just refer to the outer layer for a visual reference.
        
        vec2 atp; // Third, adjacent tangential edge point.
        float ndg;
        
        // Edge one triangle.
        ndg = length(v[2] - v[1])*nf; // Nudge length (decreasing each iteration).
        atp = v[1] + tng[1]*ndg; // Adjacent tangential edge point.
        triPat[0] = sdTri(rp, v[0], v[1], atp); // Wedge triangle for this edge.
 
        // Edge two triangle.
        ndg = length(v[0] - v[2])*nf;
        atp = v[2] + tng[2]*ndg;
        triPat[1] = sdTri(rp, v[1], v[2], atp);
        //vec2 nw1 = p2;

        // Edge three triangle.
        ndg = length(v[1] - v[0])*nf;
        atp = v[0] + tng[0]*ndg;
        triPat[2] = sdTri(rp, v[2], v[0], atp);
       
        // Rotated sprinkled noise for this layer.
        mat2 r2 = rot2(3.14159*float(i)/float(iter));
        float nsl = fBm((r2*(svP - svID.xy))*64.)*.5 + .5;//mix(tx, tx2, .8);
    
        // Fake shading and noise application.
        float sh = float(iter - i - 1)/float(iter);
        lCol = vec3(1)*1./(1. + sh*sh*2.5);
        lCol *= nsl*.5 + .5;
        
        // Failed experiment with color.
        //if((i&1)==0) lCol *= vec3(2, 0, 0);
        
        // Rendering the three triangle wedges to each side.
        for(int j = 0; j<3; j++){
            col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., triPat[j] - .002))*.5);
            col = mix(col, vec3(0), 1. - smoothstep(0., sf*2., triPat[j]));// + .005/3.
            col = mix(col, lCol, 1. - smoothstep(0., sf*2., triPat[j] + .0035));// .005*2./3.
        }
        
    }
    
    // Outer layer noise. This is applied to the border cords and points.
    float ns = fBm((svP - svID.xy)*64.)*.5 + .5;
 
    // Outside lines.
    float ln = 1e5;
    ln = min(ln, lBox(svP, svV[0], svV[1], 0.));
    ln = min(ln, lBox(svP, svV[1], svV[2], 0.));
    ln = min(ln, lBox(svP, svV[2], svV[0], 0.));
    ln -= .0055; 
     
    
    lCol = vec3(ns*.5 + .5);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*4.*iRes/450., ln - .002))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., ln)));
    col = mix(col, lCol*clamp(-ln/.005, 0., 1.), (1. - smoothstep(0., sf, ln + .0035)));  
     
    
    // Vertices.
    vec3 cir = vec3(length(svP - svV[0]), length(svP - svV[1]), length(svP - svV[2]));
    float verts = min(min(cir.x, cir.y), cir.z);
    verts -= .016;
 
    vec3 vCol = lCol*.7;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5.*iRes/450., verts))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., .005, verts)));  
    col = mix(col, vCol, (1. - smoothstep(0., sf, verts + .0035))); 
    //col = mix(col, vec3(0), (1. - smoothstep(0., sf, verts + .011))); // Pin staple hole. 
    
    
    // Slight pencil effect: Based on Flockaroo's pencil effect, which is far superior, so
    // I'd definitely refer to that one, if you're interested in that kind of thing.
    col = mix(col, pencil(col, oP), .5);
    
    // Applying a touch of color. It's a design cliche, but it works.
    col = mix(col, col*vec3(1, .05, .1)/.7, (1. - smoothstep(0., sf, verts)));
   
  
    // Subtle vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625)*1.05;
    // Colored variation.
    //col = mix(col*vec3(.25, .5, 1)/8., col, pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125));
    

    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
