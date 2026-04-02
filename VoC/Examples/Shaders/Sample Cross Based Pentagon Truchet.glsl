#version 420

// original https://www.shadertoy.com/view/lXsczH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Cross-Based Pentagon Grid
    -------------------------
    
    A while back, I came across a few really cool looking Truchet tiling images
    by Swedish generative artist, Roni Kaufman. As is often the case, I thought 
    it would be fun to reproduce one in pixelshader form, do I did, then forgot 
    about it, until now.
    
    I've affixed various Truchet patterns to quite a few tiling configurations,
    but not this particular one. At the time, I was working on a cross-based 
    traversal, so quickly modified it to accommodate the tiling you see. I should
    point out that the pentagon pattern is in a Cairo tiling arrangement (type 4,
    non-adjacent right angles), but the method used to produce it is not the way 
    to approach generalized Cairo tiling. In fact, I could think of one way to 
    produce this specific pattern by using some simple edge trickery on strategic 
    squares... Either way, the process is pretty straight forward:    
    
    Lay down a square grid of crosses that are resized and rotated in such a way 
    as to leave room for another set of equal sized crosses -- It's pretty easy, 
    and the details are below. Create another grid half a diagonal cell away, then 
    fill it with the same cross configuration. Choose the closest cross, partition 
    it into four pentagons, and you're done with the grid setup. At that point, 
    you can do whatever you want, but these pentagons are filled with a blobby 
    Truchet pattern, which can be achieved with some very basic CSG operations.
    
    In regard to design, I've rendered this in a faux 3D layered style. It's hard 
    to beat the simplistic original pattern -- which I've provided a link to below,
    but at least it's a little different. I used similar colors to pay homage to 
    the original. I'll probably put together a proper 3D version at some stage.
    
    
    
    // Based on the following:
    
    // Cairo Pentagonal Tiling - Roni Kaufman 
    https://x.com/KaufmanRoni/status/1475457931806228485/photo/4
    

*/

// Display the reverse Truchet pattern.
//#define REVERSE_PATTERN

// Show the grid that contains the crosses. The pentagons are
// obviously contained within those.
//#define SHOW_GRID

// Show vertices, or not.
//#define SHOW_VERTICES

// Directional derivative based bump mapping.
//#define BUMP

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

    b -= a; 
    return dot(p - a, vec2(-b.y, b.x)/length(b));
}

/*
// IQ's signed box formula.
float sBox(in vec2 p, in vec2 b){

    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}
*/

// Cross bound: We don't need a proper distance field to check
// boundary lines, so we should save ourselves some extra calculations.
// It was nice to have IQ's proper distance field cross function to 
// refer to when checking the workings. You can find it, here: 
// iquilezles.org/articles/distfunctions2d
// 
// "b.x" represents the height and width of the entire cross, and
// "b.y" the cross thickness.
float bndCross(in vec2 p, in vec2 b){
     
    // There's probably a more succinct and faster way to write
    // this, but it will do.
    p = abs(p);
    p = p.x<p.y ? p - b.yx : p - b;
    return max(p.x, p.y);
}

// Global scale.
vec2 gSc = vec2(1)/2.5;

vec2 gP; // Global local coordinates.
vec2[12] gCList; // Cross vertex list.
vec2[5] gPList;  // Pentagon vertex list.

vec2 gID; // Global square ID.

// The cross-based pentagon pattern.
vec4 distField(vec2 p){
    
    
    // Overall coordinates and scale.
    vec2 oP = p;
    vec2 sc = gSc;
    
    // Box vertex and mid-edge IDs. Each are handy to have when working with squares.
    mat4x2 vID = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));
    mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));
    
    
    // The cross has thickness one third of the height, which is evident from
    // the imagery. If you turn on the grid settings, you'll see that a one to
    // three ratio perpendicular triangle is involved, etc.
    // Cross rotation angle.
    float a = atan(1., 3.);
    // Cross height: This follows from the above. Feel free to get out a pen and
    // paper, or you could take a lazy coder's word for it. :D
    float ht = cos(a); // sqrt(9./10.);
    // The width needs to be one third of the height in order for two equal size
    // crosses to tile the plane.
    vec2 si = sc*vec2(ht, ht/3.)/2.;
    
    // Cross ID. Only two crosses are needed to tile the plane.
    int crossID = 0;
    // Each cross can be subdivided into four pentagons.
    int pentID = 0;
    
    
    // Square grid setup. Cell ID and local coordinates.
    vec2 q = p;
    vec2 iq = floor(q/sc);
    q -= (iq + .5)*sc;
    
    // More debugging.
    //float sq = sBox(q, sc/2.);
    
    // Copying and rotating local coordinates.
    q = rot2(a)*q;    
    gP = q;
    
    // The first cross, distance field value and ID.
    float d0 = bndCross(q, si);
    float d = d0;
    vec2 id = iq;
    
    // Saving the original box ID... Not sure what this is for. Probably debugging.
    gID = iq;
    
    // Next cross.
    q = oP - vID[2]*sc;
    iq = floor(q/sc);
    q -= (iq + .5)*sc;
 
    q = rot2(a)*q;
    float d1 = bndCross(q, si);
        
    if(d1<d){
       d = d1;
       id = iq + .5;
       gP = q;
       crossID = 1;
    }
    

    // Calculating the cross vertices: Not that it matters here, but if you
    // were doing something inside a raymarching loop, you'd take all this stuff
    // outside of this function... and condense it down.
    //
    // Four inner vertices.
    mat4x2 vIn, vOutA, vOutB;
    
    // Precalculating the inner vertices.
    for(int i = 0; i<4; i++){
        // Inner vertices.
        vIn[i] = vID[i]*ht/3.*sc.x; // "ht/3" is the cross width.
    }
    
    for(int i = 0; i<4; i++){
        // Outer vertices clockwise (two each).
        vOutA[i] = vIn[i] + eID[i]*2.*ht/3.*sc.x; // Inner plus cross-width.
        vOutB[i] = vIn[(i + 1)%4] + eID[i]*2.*ht/3.*sc.x; // Next inner plus cross-width.
        
        // Cross list in clockwise order.
        gCList[3*i] = vIn[i];
        gCList[3*i + 1] = vOutA[i];
        gCList[3*i + 2] = vOutB[i];
         
    }
    
    
    // Splitting the crosses into four pentagons.
    float oD = d;
    vec2 oID = id;
    
    // Two diagonal lines across the center to partition the cross
    // into pentagons.
    float ln0 = -distLineS(gP, vec2(0), vID[0]);
    float ln1 = distLineS(gP, vec2(0), vID[1]);
    
    for(int i = 0; i<4; i++){
        // Easier logic, but more line calls.
        //float ln0 = distLineS(gP, vec2(0), vID[i]);
        //float ln1 = distLineS(gP, vec2(0), vID[(i + 1)%4]);
        //float pent = max(d, max(ln0, -ln1));
        
        // Use the lines above to subdivide the cross into pentagons,
        vec2 dir = sign(vID[i]);
        // Pentagon on one side of the lines.
        float pent = max(d, max(dir.x*ln0, dir.y*ln1));
        // The remainder of the partitioned cross on the other.
        d = max(d, -pent);
        
        // Update the minimum pentagon distance, if necessary.
        if(pent<d){
           d = pent; // Pentagon distance.
           id = oID + eID[i]/2.; // Pentagon ID.
           pentID = i; // Pentagon number.
        }
  
    }
    
    // Pentagon vertex list. Not really used here, but handy to have.
    int n = 3*pentID;
    gPList[0] = gCList[n];
    gPList[1] = gCList[n + 1];
    gPList[2] = gCList[n + 2];
    gPList[3] = gCList[(n + 3)%12];
    gPList[4] = vec2(0);
    
    // Center point.
    //vec2 cntr = mix(gPList[0], gPList[2], .5);
    //d = max(d, -(length(gP - cntr) - .015));
    
    
    /*
    #if 1
    
    vec2[12] tmp = gCList;
    
    // Line up the vertices.
    for(int i = 0; i<12; i++){
    
        int j = i;
        if(crossID==0){
        
           // Line up alternative checkers.
           if(mod(oID.x + oID.y, 2.)==0.) j = (i + 6)%12;
           
        }
        else{
           // Line up alternative checkers.
           if(mod(oID.x + oID.y, 2.)==0.) j = (i + 6)%12;
           
           // Reverse the vertices on the second lot of crosses
           // and advance by one... Trial and error.
           j = (13 - j)%12;
        }
        
        gCList[i] = tmp[j];
        
    }
    
    #endif
    */
    
    // Debugging.
    //d += .01*sc.x;
    //d = abs(d + .035*sc.x) - sc.x*.035;
    //d = max(d, sq);
    
    // Distance, cross and pentagon ID, and cell ID.
    return vec4(d, crossID*4 + pentID, id);
}

// The blobby Truchet. Written in a few minutes, but it seems to work.
// A lot of this is common sense... to anyone with a basic knowledge of CSG.
float getTruchet(vec2 p, vec4 d4){

   
    // Truchet scale.
    vec2 sc = gSc;
    
    // Polygon ID.
    vec2 id = d4.zw;
    
    // Pentagon vertex list: gPList.

    // Cross ID, and pentagon ID.
    //int crossID = int(d4.y)/4;
    int pentID = int(d4.y)%4;
    
    // Two random numbers.
    float rnd = hash21(id + .01);
    float rnd2 = hash21(id + .02);
    
    
    // Square side length and pointed tip side length.
    float sL = length(gPList[0] - gPList[1]);
    float sL45 = length(gPList[0] - gPList[4]);

    // Line width and... dot width... I'm not sure why
    // I named it that, but it's for the dot at the pointed tip.
    float lw = sc.x/18.; // Line width.
    float dw = sL45 - (sL/2. - lw); // The dot width is dependent on the line width.
    
    // The distanc field.
    float d = 1e5;
    
    // There are three kinds of tiles here, and each have an equal chance of appearing
    // in the pattern. There are other combinations, but these three seem to work
    // best together.
    if(rnd2<1./3.){
    
        // Tile one: Pointed tip dot, arc and mid edge dot.
    
        // Point vertex.
        d = length(gP - gPList[4]) - dw;
        
        if(rnd<.5){
            if(pentID==0 || pentID==2) gP.y = -gP.y;
            else gP.x = -gP.x;
        }
        // Mid edge vertex;
        d = min(d, length(gP - mix(gPList[2], gPList[3], .5)) - lw);
        
        // Arc.
        float arc = length(gP - gPList[1]) - sL/2.;
        arc = abs(arc) - lw;
        d = min(d, arc);
    
    }
    else if(rnd2<2./3.){
    
        // Tile 2: The blobby tri-pronged line and the pointed dot tip.
    
        // Point vertex.
        d = length(gP - gPList[4]) - dw;
        
        vec2 e0 = mix(gPList[0], gPList[1], .5);
        vec2 e2 = mix(gPList[2], gPList[3], .5);
        // Half edge line.
        float ln = -distLineS(gP, e0, e2) - lw;
        // Cut out the end corners.
        ln = max(ln, -(length(gP - gPList[1]) - (sL/2. - lw)));
        ln = max(ln, -(length(gP - gPList[2]) - (sL/2. - lw)));
        
        d = min(d, ln);
    
    }
    else {
    
        // Tile 3: The four pronged blobby cross.
    
        // Four corners cut out.
        d = -1e5;
        d = max(d, -(length(gP - gPList[1]) - (sL/2. - lw)));
        d = max(d, -(length(gP - gPList[2]) - (sL/2. - lw)));
        
        d = max(d, -(length(gP - gPList[0]) - (sL/2. - lw)));
        d = max(d, -(length(gP - gPList[3]) - (sL/2. - lw)));
    
    }
    

    // Interesting, but not for this pattern.
    //d = abs(d + .0425*sc.x) - sc.x*.0425;
     
    // I think I like the reverse pattern more, but I thought I'd
    // default to the basics.
    #ifdef REVERSE_PATTERN
    d = -d;
    #endif
  
    // Return the Truchet distance.
    return d;

}

// The square grid.
float gridField(vec2 p){
    
    // Scale, cell ID and local coordinates.
    vec2 sc = gSc;
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Boundary.
    p = abs(p) - .5*sc;
    return abs(max(p.x, p.y)) - .005*sc.x;
}

// A very simple random line routine. It was made up on the
// spot, so there would certainly be better ways to do it.
float randLines(vec2 p){
    
    // Scaling.
    float sc = 32./gSc.x;
    p *= sc;
    
    // Offset the rows for a more random look.
    p.x += hash21(vec2(floor(p.y), 7) + .2)*sc;
    
    // Cell ID and local coordinates.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    // Distance field value and random cell number.
    float d;
    float rnd = hash21(ip + .34);
    
    // Randomly, but not allowing for single dots.
    if(rnd<.333 && mod(ip.x, 2.)==0.){
    
       // Dots on either side of the cell wall mid-points, to create a space.
       d = min(length(p - vec2(-.5, 0)), length(p - vec2(.5, 0)));
        
    }
    else {
        // Otherwise, just render a line that extends beyond the cell wall
        // mid-points.
        d =  abs(distLineS(p, vec2(-1, 0), vec2(1, 0)));
    }
    
    // Applying some width.
    d -= 1./6.;
    
    // Scaling down the distance value to match scaling up
    // the coordinates.
    return d/sc;
}

void main(void) {

    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Stretched screen coordinates.
    vec2 uv2 = gl_FragCoord.xy/resolution.xy - .5;
    
    // Emulating a bit of camera tilting.
    uv.xy *= (.98 + .04/(uv.y + 1.5));
    
    // Add a bit of faux screen curvature.
    uv *= .95 + dot(uv2, uv2)*.1;
    
      
    // Scaling and translation.
    float gSc = 1.;
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera in the north east (top right) direction. 
    vec2 p = uv*gSc - vec2(-1, -.5)*time/12.;
    
    
    // Making a copy of the original coordinates.
    vec2 oP = p;

    
    // Faux extrusion.
    float zDist = length(vec3(0, 0, -1) - vec3(uv, 0.));
    vec4 d4Sd = distField(p - vec2(.005) + (uv)/(.5 + zDist)*.04);
    float trSd = getTruchet(gP, d4Sd);
    
    // Regular pattern vertices appear on the extruded layer.
    #ifdef SHOW_VERTICES
    #ifndef REVERSE_PATTERN
    float vert = 1e5;
    for(int i = 0; i<4; i++){
         vert = min(vert, length(gP - gPList[i]) - .017);
    }
    #endif
    #endif
    
    // Ground highlights.
    vec4 d4Hi2 = distField(p - vec2(.005) + (uv)/(.5 + zDist)*.04 - vec2(-.01, -.02)*.7);
    
    // Truchet hightlights.
    vec4 d4Hi = distField(p - vec2(-.01, -.02)*.7);
    float trHi = getTruchet(gP, d4Hi);
    // Truchet shadows.
    vec4 d4Sh = distField(p - vec2(-.01, -.02));
    float trSh = getTruchet(gP, d4Sh);
    
    // The Truchet face pattern.
    vec4 d4 = distField(p);
    float tr = getTruchet(gP, d4);
    
    // Reverse pattern vertices appear on the floor layer.
    #ifdef SHOW_VERTICES
    #ifdef REVERSE_PATTERN
    float vert = 1e5;
    for(int i = 0; i<4; i++){
         vert = min(vert, length(gP - gPList[i]) - .017);
    }
    #endif
    #endif
    
    // Smoothing function.
    float sf = 1./resolution.y*gSc;
    
    // Random reddish background color.
    float rnd = hash21(d4.zw + .11);
    vec3 oCol = .5 + .45*cos(6.2831*rnd/4. + vec3(0, 1, 2)*1.35);

   
    // Cross and pentagon IDs.
    int crossID = int(d4.y)/4;
    int pentID = int(d4.y)%4;
    
    // Alternate crosses. 
    //if(croosID == 0) oCol = oCol.zyx;
    
    //oCol = vec3(0, .487, .493); // Green.
    //oCol = vec3(1, .1, .175);   // Red.
     
    // Transition variable.
    float tran = smoothstep(-.1, .1, sin(time/3. + .1));
    // Time based color mixing... Not very elegant, but it'll do.
    oCol = mix(mix(vec3(.05, .487, .493), oCol.yxz/(.75 + oCol.yxz), .3), 
           mix(vec3(1, .1, .2), oCol, .2), tran);
    
    /*
    // Debug: Displaying the four pentagon colors. 
    // Yellow, Red, Green, Blue.
    mat4x3 sCol = mat4x3(vec3(1, .8, .2), vec3(1, .2, .2), 
                         vec3(.2, .8, .2), vec3(.2, .6, 1));
    oCol = sCol[pentID]*.8;
    */
    
    // Distance based color mixing.
    oCol = mix(oCol, mix(vec3(.2, .4, .9), oCol.zyx, tran), 
               smoothstep(.3,  .7, length(uv2)));
    
    #ifdef BUMP
    // Directional derivative bump mapping.
    float bmpFloor = max(d4Hi.x - d4.x, 0.)/.02;
    oCol = oCol*(.75 + bmpFloor*.7);
    #endif
    
    // Adding a random line pattern to the background.
    float pat = randLines(rot2(3.14159/4.)*p);
    oCol = mix(oCol*1.2, oCol*.8, (1. - smoothstep(0., sf, pat)));

    // Debug: Display the cross pattern.
    //if(crossID == 0) oCol = oCol.zxy/(1.5 + oCol.zxy)*2.;
    
    // Initiating the overal color, edge with and line width.
    vec3 col = vec3(.15);
    float ew = .006;
    float lnW = .01;

    // Rendering the background.
    //col = mix(col, col*.5, (1. - smoothstep(0., sf, d4Sh.x)));
    col = vec3(0);//mix(col, vec3(0), (1. - smoothstep(0., sf, d4Sd.x)));
    col = mix(col, oCol + .25, (1. - smoothstep(0., sf, d4Sd.x + ew)));
    
    col = mix(col, oCol, (1. - smoothstep(0., sf, max(d4Sd.x + ew, d4Hi2.x + ew*1.5))));

    /*
    vec2 cntr = mix(gPList[0], gPList[2], .5);
    float cVert = length(gP - cntr) - .0175;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, cVert)));
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, cVert + ew)));
    */
    
     
    // Interesting, but a bit much.
    //float lw = gSc/64.;
    //tr = abs(tr + lw) - lw;
    
    // Debug, to show the tiles better. Omitting the Truchet pattern
    // altogether would also work.
    //tr = max(tr, -(abs(d4.x) + ew/2.));
    
    // Base Truchet color.
    vec3 tCol = vec3(1, .7, .15); //vec3(.985, .685, .114)
    //vec3 tCol = vec3(.75);
    // More transparency.
    //tCol = mix(tCol, col*1.35, .85);
    
    // Length based Truchet color mixing.
    tCol = mix(tCol, mix(tCol.zyx, tCol.xzy, tran), smoothstep(.3,  .7, length(uv2)));

    // Adding a tiny bit of transparency.
    tCol = tCol*col*.3 + tCol*.8;//
    
    #ifdef BUMP
    // Directional derivative bump mapping.
    float bmpTruch = max(trHi - tr, 0.)/.02;
    tCol = tCol*(.75 + bmpTruch*.7);
    #endif
    
    // Render the Truchet side layers to give the appearance of extrusion.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, trSd - ew/2.));
    col = mix(col, mix(tCol, oCol, .5)*.7, 1. - smoothstep(0., sf, trSd + ew*1.5 - ew/2.));

    // Truchet shadow, followed by the Truchet face layer.
    float sdF = resolution.y/450.; // Shadow distance factor.
    col = mix(col, col*.5, 1. - smoothstep(0., sf*4.*sdF, trSh));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, tr));
    col = mix(col, tCol + .5, 1. - smoothstep(0., sf, tr + ew*1.5));

    // Adding in the highlights.
    col = mix(col, tCol, 1. - smoothstep(0., sf, max(tr + ew*1.5, trHi + ew*1.5)));
    
    /*
    // Debugging cross vertices.
    for(int i = 0; i<12; i++){
        
        float vert = length(gP - gCList[i]) - .017;
 
        vec3 vCol = mix(col, vec3(1), .5);
        //vec3 vCol = .5 + .45*cos(6.2831*float(i)/12. + vec3(0, 1, 2));//vec3(i)/12.;
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, vert)));
        col = mix(col, vCol, (1. - smoothstep(0., sf, vert + ew*1.25)));
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, vert + .005 + ew*1.25)));
    
    }
    */
    
    
    // Vertex points.
    #ifdef SHOW_VERTICES
    vec3 vCol = mix(col, vec3(1), .5);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, vert));
    col = mix(col, vCol, 1. - smoothstep(0., sf, vert + ew*1.25));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, vert + .005 + ew*1.25));
    #endif
    
    // The square grid.
    #ifdef SHOW_GRID
    float grid = gridField(p);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*2.*sdF, grid - ew/1.5));
    col = mix(col, vec3(1), 1. - smoothstep(0., sf, grid));
    #endif
    
    // Adding a random line pattern to the truchet face.
    col = mix(col*1.15, col*.85, 1. - smoothstep(0., sf, max(pat, tr)));
 
  
    // Rough gamma correction and screen presentation.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
