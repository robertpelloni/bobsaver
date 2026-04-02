#version 420

// original https://www.shadertoy.com/view/cdfGzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Hexagon Fractal Object
    ----------------------
    
    Fabrice Neyret and MLA (aka Matthew Arcus) have posted a few Gosper
    curve examples lately, which were much appreciated because it's one
    of those interesting and important topics that very little code 
    exists for.
    
    Anyway, the results very much reminded me a fractal curve example that 
    I'd left unfinished a while back. I'm not sure what the object is 
    technically called, but it's a hexagon fractal curve, so that'll do.
    It's not a common object, but I've seen it around.
    
    I took a polar cell partitioning approach, which was almost trivial
    for one level, reasonable for the second level, and downright
    annoying to code for the third due to cell overlap issues. I won't
    bore you with the details, since a lot of it is in the code, but 
    here's quick explanation:
    
    Divide space into six polar cells (sextants, I think), then render 
    S-curves in even cells and reverse S-curves in the remaining cells to 
    produce a flowing hexagonal boundary curve -- Set "cInd" to zero and 
    uncomment the define CNSTR_LINES for a visual reference. The S-curves 
    consist of circular arcs around three vertex points contained in each
    cell. For the next iteration, move to each of those three vertex points, 
    then render the same hexagonal curves around them, then do it again... 
    There are details I'm omitting, but that and the code should give 
    anyone interested in this sort of thing a start.
    
    Aesthetically speaking, I like the way the object looks with just two 
    levels. However, that seems a little too easy to construct, so I've 
    opted for the tri-level version. By the way, I'm going to make a more 
    interesting two level example later.
    
    
    
    Related examples:
    
    // The Gosper curves are different, but have a very similar feel.
    Gosper Closed Curves - mla
    https://www.shadertoy.com/view/mdXGWl
    
    // The original Gosper curve example on here.
    Gosper curve - FabriceNeyret2
    https://www.shadertoy.com/view/cdsGRj
    
*/

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
//float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

// Dividing line passing through "a" and "b".
float divLine(vec2 p, vec2 a, vec2 b){

   // I've had to put a hack on the end to get rid of fine lines
   // at the zero point. That, of course, invalidates the distance portion.
   // However, in this case, I only need it for a border check, not distances.
   // I'm not sure why the hack is needed... Some kind of float inaccuracy... 
   // I'll look into it later. :)
   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b))*1e8;
}

//////////////
// Background pattern code.
// vec2 to float hash.
float hash21( vec2 p ){ 

    return fract(sin(dot(p, vec2(1, 113)))*45758.5453); 
    // Animation, if preferred.
    //p.x = fract(sin(dot(p, vec2(1, 113)))*45758.5453);
    //return sin(p.x*6.2831853 + time)*.5 + .5; 
}

// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
const vec2 s = vec2(1, 1.7320508);

// This function returns the hexagonal grid coordinate for the grid cell, and the corresponding 
// hexagon cell ID -- in the form of the central hexagonal point. That's basically all you need to 
// produce a hexagonal grid.
vec4 getHex(vec2 p){
    
    // The hexagon centers.

    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    
    // Centering the coordinates with the hexagon centers above.
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    
    // Nearest hexagon center (with respect to p) to the current point. 
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);

}

// A very unimaginative background pattern. :)
float bgPat(vec2 p){

    vec4 h = getHex(p);// + s.yx*time/6.
    
    float cDist = length(h.xy); // Distance from the center.
    
    // Unique random number.
    float rnd = hash21(h.zw + .1)*.5 + .5;
    
    // Random circle size.
    float d = cDist - min(.5*rnd, .47);
    //d = abs(d + .2*rnd) - .2*rnd;
    
    return d;

}

//////////////////

// Fractal iteration depth. I'm only prividing 3 here, due to the 
// iteration count getting out of hand for values like 4, so the
// numbers are 0, 1, or 2.
int cInd = 2;

// Display the closed curve... Technically, the dark edges are the closed
// curve, but this presents it more fully.
//#define CURVE

// Arc shape. Circular: 0, Hexagon: 1.
#define SHAPE 0

// Show the construction lines: These make more sense when the variable 
// "cInd" (above) is set to zero. The long lines represent the six individual
// cell borders, and the remaining disecting lines are hexagon boundaries. 
// The object in each cell consists of three curves surround three points.
//#define CNSTR_LINES

//////////////////

// Arc shape.
float dist(vec2 p){
  
    #if SHAPE == 0
    return length(p);
    #else
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x);
    #endif

}

// The construction lines for this cell.
float cnstLines(vec2 p, mat3x2 ctr, vec2 s){

    float ln = 1e5;
    // Borders.
    ln = min(ln, distLine(p, vec2(0), ctr[0]*s.x));
    ln = min(ln, distLine(p, vec2(0), ctr[2]*s.y));
    // Dividing lines.   
    ln = min(ln, distLine(p, ctr[1], ctr[0]));
    ln = min(ln, distLine(p, ctr[2], ctr[1]));
    
    return ln;
}

vec2 polRot(vec2 p, inout float na, int m){

    const float aN = 6.;
    float a = atan(p.y, p.x);
    na = mod(floor(a/6.2831*aN) + float(m - 1), aN);
    float ia = (na + .5)/aN;
    p *= rot2(-ia*6.2831);
    // Flip alternate cells about the center.
    if(mod(na, 2.)<.001) p.y = -p.y;

    return p;
}

// Partition lines.
vec3 prtnLines(vec2 p, mat3x2 ctr){

                
    // Cell partition lines.
    float div1 = divLine(p, ctr[1], ctr[0]);
    float div2 = divLine(p, ctr[2], ctr[1]);  
     // Cell border.
    float bR = divLine(p, vec2(0), ctr[2]);
    //bL = divLine(p, vec2(0), ctr[0]);

    return vec3(div1, -max(div1, div2), max(div2, bR));
}

/*
int colID(vec3 c, vec3 oDiv, int index, inout float gCol){
    c = max(c, oDiv);
    int colID = c.x<c.y && c.x<c.z? 0 : c.y<c.z? 1 : 2;
    if(c[colID]<gCol){ gCol = c[colID]; index = colID; }
    return index;
}
*/

void main(void) {

    // Aspect corret coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;

    // Scale and smoothing factor.
    const float sc = 1.;
    float sf = sc*1.5/resolution.y;
    
    // Automatically rotate through all levels.
    //cInd = int(mod(floor(time/4.), 3.));
    
    
    // Scaling and translation.
    vec2 p = rot2(3.14159/6. - time/24.)*sc*uv;
    
    // Scene field calculations.

    vec2 op = p;
    
    // The distance field for each level.
    vec3 gDst = vec3(1e5);
 
    // Polar cell numbers.
    vec3 na, gNa = vec3(1);    
  
    /*
    // Index and global color value.
    ivec3 index = ivec3(0);
    vec3 gCol = vec3(1e5);
    */
    
    // Construction lines and maximum bounds for each level.
    vec3 ln = vec3(1e5);
    vec3 gBound = vec3(1e5);

    
    // I poached this from one of my hexagonal six petal geometry examples. I remember
    // working it out on paper and liking the fact that it was so weird but concise. 
    // Unfortunately, I didn't mention how I got there. :)
    const float shF = sqrt(1./7.);
    // The original radius of the circle that the curve is constucted around.
    const float r0 = .27;
    const float hr0 = r0/.8660254; // Hexaon radius.
    float r20 = hr0/3.; // Small circle radius.
    #if SHAPE != 0
    r20 *= .8660254; // Readjusting the radius for hexagonal shapes.
    #endif
    // Each polar cell has an S-shaped curve running through it, which is
    // constructed with three vertex points. There are two on the cell boundaries, 
    //and one in the center -- Check the figure with one iteration for a visual. 
    // The vetex scale changes for greater iteration depth, but not the direction, 
    // so we're going to precalculate the original scale and direction here.
    mat3x2 ctr0 = mat3x2(rot2(3.14159/6.)*vec2(hr0*2./3., 0), vec2(r0*4./3., 0), 
                         rot2(-3.14159/6.)*vec2(hr0*4./3., 0));
    
    // Precalculating the rotation matrices, which get used a few times.
    // The angle is a hexagonal rotation related number involving ratios...
    // The tangential angle between thrice the apothem and half the side
    // length... I worked it out long ago, and no longer care why it works. :D
    //
    // Angle between the vertical line and the line running through the 
    // left hexagon vertex to the right vertex on the hexagon above.
    float rotAng = atan(sqrt(3.)/9.); // Approx: 0.19012.
    mat2 mRot = rot2(rotAng);
    mat2 mRotP3 = rot2(rotAng + 3.14159/3.); // Inner curve needs extra rotation.

    for(int aI = 0; aI<3; aI++){

        // The radius of the circle that the curve is constucted around.
        float r2 = r20; // Small circle radius.
        p = op; // Original global coordinates.
       
        // Split this space into polar cells, and return the local coordinates
        // and the cell number, which is used later.
        p = polRot(p, na.x, aI);

        mat3x2 ctr = ctr0; // Curve center -- There are three in each segment.

        // Partition lines for each of the three vertices in the cell.
        vec3 oDiv = prtnLines(p, ctr);
        // Hexagon bounds for this scale. It's used to reverse coloring at the end.
        float bR = divLine(p, vec2(0), ctr[2]);
        gBound.x = min(gBound.x, max(-oDiv.y, oDiv.z)); // Previous hexagonal boundary lines.

    
        // Left, middle, right central point distances.
        vec3 c = vec3(dist(p - ctr[0]), dist(p - ctr[1]), dist(p - ctr[2])) - r2;
        
        /*
        //////////
        // Color ID.
        index.x = colID(c, oDiv, index.x, gCol.x);
        /////////
        */
        
        c = max(c*vec3(-1, 1, -1), oDiv);

        float crv = min(max(c.x, c.z), c.y);
        
        if(crv<gDst.x){ gDst.x = crv; gNa.x = na.x; }
        
        // Get the construction lines for this iteration.
        ln.x = min(ln.x, cnstLines(p, ctr, vec2(2.5, 1.25)));//vec2(3, 1.5)
        

        ////////////////////////  

        // Move to the new frame of reference, readjust r to the new scale
        // (the smaller circle, r2), then recalculate the curve.
        
        // Move to the new points.
        mat3x2 p3 = mat3x2(p, p, p) - ctr;
        //
        if(mod(na.x, 2.)<.001){
            // Flip the X-value in every second polar cell.
            p3[0].x = -p3[0].x; p3[1].x = -p3[1].x; p3[2].x = -p3[2].x;
        }
        // Rotate each point to the new orientation. The second point
        // needs to be rotated an extra 60 degrees.
        p3[0] *= mRot; p3[1] *= mRotP3; p3[2] *= mRot;
 

        for(int bI = 0; bI<3; bI++){
        for(int i = 0; i<3; i++){

            ctr = ctr0*shF; 
            r2 = r20*shF;
            
            p = p3[i];
            
            // Split this space into polar cells, and return the local coordinates
            // and the cell number, which is used later.
            p = polRot(p, na.y, bI); // bI - 1

            // Partition lines for each of the three vertices in the cell.
            vec3 oDiv2 = prtnLines(p, ctr);
            
       
            // Applying the previous clipping region to this one.
            oDiv2 = max(oDiv2, oDiv[i]);
            // Hexagon bound.
            gBound.y = min(gBound.y, max(max(-oDiv2.y, oDiv2.z), oDiv[i]));

            // Left, middle, right central point distances.
            c = vec3(dist(p - ctr[0]), dist(p - ctr[1]), dist(p - ctr[2])) - r2;
            ////
            
            /*
            //////////
            // Color ID.
            index.y = colID(c, oDiv2, index.y, gCol.y);
            /////////
            */
            
            c = max(c*vec3(-1, 1, -1), oDiv2);

           
            crv = min(max(c.x, c.z), c.y);
        
            if(crv<gDst.y){ gDst.y = crv; gNa.y = na.y; }

           
            // Get the construction lines for this iteration.
            ln.y = min(ln.y, cnstLines(p, ctr, vec2(1.25, 1.25))); //vec2(2.5, 1.5)
            
          
            // Move to the new points.
            mat3x2 q3 = mat3x2(p, p, p) - ctr;
            //
            if(mod(na.y, 2.)<.001){
                // Flip the X-value in every second polar cell.
                q3[0].x = -q3[0].x; q3[1].x = -q3[1].x; q3[2].x = -q3[2].x;
            }
            // Rotate each point to the new orientation. The second point
            // needs to be rotated an extra 60 degrees.
            q3[0] *= mRot; q3[1] *= mRotP3; q3[2] *= mRot;

            mat3x2 ctr2 = ctr*shF;
            r2 = r20*shF*shF;
        
            // Technically, we should allow for polar cells on either side, but that
            // would mean three times the total iterations, so since there are no 
            // cell border encroachments here, we'll save a heap of cycles.
            //for(int cI = 0; cI<3; cI++){
            for(int j = 0; j<3; j++){

                p = q3[j]; 
                
                // Split this space into polar cells, and return the local coordinates
                // and the cell number. Normally, you'd pass in a cell number variable
                // to the last position, but we only need the middle one.
                p = polRot(p, na.z, 1); // cI
                
                // Partition lines for each of the three vertices in the cell.
                vec3 oDiv3 = prtnLines(p, ctr2);

                // Applying the previous clipping region to this one.
                oDiv3 = max(oDiv3, oDiv2[j]);

                // Left, middle, right central point distances.
                c = vec3(dist(p - ctr2[0]), dist(p - ctr2[1]), dist(p - ctr2[2])) - r2;
                
                /*
                //////////
                // Color ID.
                index.z = colID(c, oDiv3, index.z, gCol.z); 
                /////////
                */
               
                c = max(c*vec3(-1, 1, -1), oDiv3);
                crv = min(max(c.x, c.z), c.y);
                

                if(crv<gDst.z){ gDst.z = crv; gNa.z = na.z; }
                ////

                if(oDiv[i]<0.){
                    // Get the construction lines for this iteration.
                    ln.z = min(ln.z, cnstLines(p, ctr2, vec2(1.1, 1.1)));
                }

            } // End "j".
            //} // End "cI".

        } // End "i".
        } // End "bI". 

    } // End "aI".   

    // RENDERING.
 
 
    // Background.
    vec3 bg = vec3(.08);//vec3(1, .15, .3);////vec3(.9, .95, 1)
    vec3 fg = vec3(.8, 1, .15);//.yyz; //vec3(1, .6, .4); vec3(.8, .9, 1);//
    fg = mix(fg, fg*vec3(1, .95, .2), uv.y*2. + .5);
    
    // The hexagon dot background.
    float hSc = 4.*float(cInd + 1)*2.; // Scale based on the main pattern level.
    vec2 hUV = rot2(3.14159/12. + time/24.)*uv; // Rotating the coordinates.
    float bgP = bgPat(hUV*hSc)/hSc;
    vec3 svBg = bg;
    
    bg = mix(bg, svBg*.8, (1. - smoothstep(0., sf*5., bgP)));  
    bg = mix(bg, svBg*.5, 1. - smoothstep(0., sf, bgP));   
    bg = mix(bg, svBg*1.1, 1. - smoothstep(0., sf, bgP + .0035));   

    /*
    // Adding subtle lines to the background.
    const float lnSc = 60.;
    vec2 pUV = rot2(3.14159/6. + time/24.)*uv; 
    float pat = (abs(fract(pUV.x*lnSc) - .5) - .15)/lnSc;
    bg = mix(bg, bg*1.2, (1. - smoothstep(0., sf, max(pat, bgP + .003))));    
    */
       
    // Scene color -- Set to the background.
    vec3 col = bg;
    
    // Debug cell indicators.
    //if(mod(gNa.x, 2.)==0.) col *= vec3(.8);
    //if(mod(gNa.y, 2.)==0.) col *= vec3(.8);
    //if(mod(gNa.z, 2.)==0.) col *= vec3(.8);
    //col *= mod(dot(gNa, vec3(1)), 18.)/17.;
    //col *= (gNa.x*36. + gNa.y*6. + gNa.z)/215.;
    
    // Clamp the level index between zero and two, since they're the only
    // one's that work.
    cInd = cInd<0? 0 : cInd>2? 2 : cInd;
    
    // Flipping patterns outside the bounds of previous levels... Yeah, it's confusing. :)
    // With Truchet patterns, there's usually some cell pattern flipping involved, but with 
    // this example, there's level flipping also. 
    if(gBound.x<0.){ gDst.y = -gDst.y; gDst.z = -gDst.z; /* index.y += 1; index.z += 1; */ }
    if(gBound.y<0.){ gDst.z = -gDst.z; /* index.z += 1; */ }
     
    // Giving the pattern some extra thickness.
    gDst -= .006*float(3 - cInd);
    
    #ifdef CURVE
    gDst = abs(gDst + .006*float(3 - cInd)) - .018*float(3 - cInd);
    #endif

    /*
    // Debug indicators.
    vec3 tCol =  mix(fg, vec3(1), .75);
    if((index[cInd]&1)==0) tCol = mix(fg, bg, .85);
    col = mix(col, tCol, 1. - smoothstep(0., sf, gCol[cInd]));
    fg = mix(fg, tCol, 1. - smoothstep(0., sf, gCol[cInd]));
    */
    

    // Edge, or stroke.
    float dst = gDst[cInd];
     
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*6., dst))*.35);
    col = mix(col, fg*fg*.65, 1. - smoothstep(0., sf,  dst));
    col = mix(col, fg, 1. - smoothstep(0., sf,  dst + .01*float(3 - cInd) + .002)); 
    
   
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(dst) - .001)); 
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(dst + .01*float(3 - cInd)) - .001)); 
     
/*
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., abs(gDst[2]) - .0045))*.35);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(gDst[2]) - .0045)); 
    col = mix(col, vec3(1, .8, .6), 1. - smoothstep(0., sf, abs(gDst[2]) - .001));
    if(cInd>1){
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(gDst[1]) - .0045)); 
        col = mix(col, vec3(1, .85, .7), 1. - smoothstep(0., sf, abs(gDst[1]) - .001));
    }
    if(cInd>0){
        col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(gDst[0]) - .0045)); 
        col = mix(col, vec3(1, .9, .8), 1. - smoothstep(0., sf, abs(gDst[0]) - .001)); 
    }
*/
    //if(cInd>0) col = mix(col, vec3(0), (1. - smoothstep(0., sf, gBound[cInd - 1]))*.35);
    
    #ifdef CNSTR_LINES
    // Display the cellular construction lines.
    //ln = max(ln, gDst + .01);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, ln[cInd] - .006)); 
    col = mix(col, min(fg.zyx + .7, 1.1), 1. - smoothstep(0., sf, ln[cInd] - .0002));
    #endif

    //col = mix(col, col.xzy, uv.y + .5);

    // Output to screen
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
