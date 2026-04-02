#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdySWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Wang Tile Border Animation
    --------------------------

    Shadertoy user MathMasterZach put together a very nice, cleverly made maze
    recently, complete with a surrounding conveyor belt system, then Fabrice put
    in some really clever suggestions. I effectively brought nothing to the table,
    but I was part of the cheer squad, so I felt like I was contributing. :D 

    Anyway, I'm aware of the concept of an animated border -- I applied it in my
    "Hexagonal Maze Flow" example. I've also been vaguely aware that an animated 
    border can be applied to all kinds of patterns, but figured it would be too 
    much of a book-keeping mission to produce one around anything but the simplest
    of grid arrangements.
    
    However, after perusing the code for a while, I realized that either Zach or 
    Fabrice had employed a neat trick that involved producing a pattern on a
    standard grid, then subdividing each grid cell into four squares, which in turn
    would provide the scaffolding upon which to mold a path around the original 
    structure in a simplistic and manageable fashion. It's quite clever, and the 
    kind of thing that would have taken me forever to realize.

    In this particular example, I'm applying a very similar principle to a Wang 
    tile pattern. As usual, I got a bit excited with the prettying up portion,
    which has a tendency to drown out the relevant logic. However, the imagery 
    itself is kind of self explanatory and should give people enough to go on.
    Here's a brief summary:

    Straight horizontal segments on the bottom of each cell travel west, and the 
    top ones travel east. Straight vertical segments on the left side of the cell
    move north, and those on the right travel south. Arcs with their centers at 
    the physical cell center turn clockwise, whereas those with their centers 
    fixed on the cell edges move in the counter-clockwise direction.

    I've also provided some options below and explained the notable segments.
    Plus, you can always refer the original, which contains much more elegant and 
    succinct code. The link is below.

    Based on:

    // A really nice example on so many different levels. The maze code itself is
    // also pretty interesting and clever. The path itself visits every node exactly
    // once without crossing its own path, and is useful for all kinds of 
    // things -- See the link below this one. I'm going to produce a couple of 
    // examples along these lines too.
    Self-Avoiding Random Road - mathmasterzach
    https://www.shadertoy.com/view/wdySWm

    Other examples:

    // This example is really pleasing to watch.
    Indexed Space Fill Random Path - mathmasterzach
    https://www.shadertoy.com/view/wdySRy

    // A similar animated flow line example, but this was easier to construct.    
    Hexagonal Maze Flow - Shane
    https://www.shadertoy.com/view/llSyDh

    // Dr2 has already put together an extruded 3D example.
    Long Loop - Dr2
    https://www.shadertoy.com/view/wdKSDy

*/

// Display the inner Wang tile structure that the border flows around. Essentially, 
// you could apply the same concept to heaps of things. Aesthetically, I prefer 
// turning this option off, but it helps visualize the concept more.
#define SHOW_INNER_STRUCTURE

// Show the straight rails, instead of the beaded structure.
//#define SHOW_RAILS

// A visual aid to display the original grid boundaries. Although, things get
// a bit cluttered at this point, so it's probably better with the SHOW_RAILS
// option turned on.
//#define SHOW_ORIGINAL_GRID

// A plainer palette to declutter things a bit. The colors vary ever so slightly,
// so technically, it's not monochrome, but that doesn't write well as a define. :)
//#define MONOCHROME

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){ 
    
    return fract(sin(dot(p, vec2(137.609, 157.583)))*43758.5453);
}

// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values.
float n2D(vec2 p) {

    vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
    
    return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }

float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

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

// Distance formula.
float dist(vec2 p, vec2 b){
    
    //return length(p) - b.x;
    return sBoxS(p, b, .2);
    
}

// Use the unique edge point IDs to produce a Wang tile ID for the tile.
float edges(vec2 ip, vec2[4] ep, float rnd){
    
    // Initial ID: Trivial, and converts to a binary string of "0000," which indicates
    // the cell has no edge points, or an empty tile.
    float id = 0.;
    
    // Note: exp2(i) = pow(2., i).
    for(int i = 0; i<4; i++) id += hash21(ip + ep[i])>rnd? exp2(float(i)) : 0.;
    
    return id; // Range [0-15] inclusive.
    
}

// Hacky global. Just a regional ID for coloring purposes.
vec2 regID;

vec4 distField(vec2 p){
    
    // Tile ID and local coordinate.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    
    // Set the region ID to the main tile ID.
    regID = ip;
    
    // Distance field holders.
    float d = 1e5, d2 = d, d3 = d;
    
    // Wang tile constrction. Pretty standard, and I've explained it in other
    // examples, if you feel like looking them up.
    //
    const float thresh = .5; // Threshold.
    vec2[4] eps = vec2[4](vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));
    vec2[4] cp = eps; 
    
    // Edge ID for the 
    float id = edges(ip, eps, thresh);
    // Decode each binary digit.
    vec4 bit = mod(floor(id/vec4(1, 2, 4, 8)), 2.);

    
    int iNum = 0; // Edge point index.
    
    for(int i = 0; i<4; i++){
        // Edge numbers.
        if(bit[i]>.5) {
            
            d2 = min(d2, lBoxHV(p, vec2(0), eps[i], 0.));
            cp[iNum++] = eps[i];
        }
        
    } 
    
    
    
    // Subdividing each cell into four squares, then using the existing
    // structure to perform  bit checks.
    
    // Subdividing further into four squares.
    vec2 q = mod(p, .5) - .25;
    
    
    // Quadrant identification.
    int quadID;
    
    if(p.x<0.){
        if(p.y<0.) quadID = 0;
        else quadID = 1;
    }
    else {
        if(p.y<0.) quadID = 3;
        else quadID = 2;
    }
    
    
     
    // Object angle variable. Moving clockwise.
    float ang = -time/2.;
    // Quadrant sign variable. It was used to great effect in Zach's example.
    vec2 s = sign(p);
    
    
    
    // This mess was written quickly off the top of my head. In concept, it's
    // simple though. For each quadrant, construct an edge list by referencing
    // the main Wang structure, then render the Wang structure for it using
    // standard Wang tile methods.
    
    for(int j = 0; j<4; j++){
        
        // If the line from the main cell is blocking the 
        // direction, head in that direction also, since you want to
        // avoid the line and not run into it. Otherwise, head
        // toward the open space.
        
        // Border count.
        int borders = 0;
        
        // Quad ID.
        float qID = 0.;
        
        // Contrucing the edge IDs for this particular quadrant. 
        if(bit[j]>.5) { 
            qID += float(1<<(j)); // 1, 2, 4, 8.
            borders++;
        }
        else qID += float(1<<((j + 1)&3)); // 2, 4, 8, 1.
        
        if(bit[(j + 3)&3]>.5) {
            qID += float(1<<((j + 3)&3)); // 8, 1, 2, 4. 
            borders++;
        }
        else qID += float(1<<((j + 2)&3)); // 4, 8, 1, 2.
        
        
        // Edge bit extraction.
        vec4 qBit = mod(floor(qID/vec4(1, 2, 4, 8)), 2.);

        // Fill in the point structure. Actually, this isn't
        // technically needed, as you can constuct things with
        // the quadrant sign variable "s," but I'll need it later.
        int cnt = 0;
        vec2[4] qCp = eps; 
        for(int i = 0; i<4; i++){
            if(qBit[i]>.5){
                qCp[cnt++] = eps[i]/2.;
            }
        }
        
        
        // Contruct the distance fields for this quadrant in any empty
        // cells. By the way, you don't need to leave empty cells empty,
        // but I prefer it that way.
        if(quadID == j && iNum>0){
            
            // Refering to the imagery. If there's one border, render
            // a straight line.
            if(borders == 1){
                
                // Straight line.
                d = min(d, lBoxHV(q,  qCp[0], qCp[1], 0.)); 
                //d = min(d, lBoxHV(q, vec2(0), qCp[0], 0.)); 
                //d = min(d, lBoxHV(q, vec2(0), qCp[1], 0.)); 
              
                
                // Vertical.
                if(abs(qCp[0].x - qCp[1].x)<.001) {
                    
            
                    // If you take a look at the imagery, you'll see that vertical
                    // lines on the left need to travel in opposite directions, 
                    // depending which side of the "p.x = 0" line they're on. Hence
                    // the "s.x" term. The same applies for the horizontal term
                    // below.
                    // 
                    // On a side note. If you choose the right number of repeat 
                    // segments, you can manipulate the angle (or spacing, in this
                    // case) to make things look more consistant -- since the perimeter
                    // of a square is larger than that of its circumscribed circle.
                    //
                    // For instance, with three segments in each quarter circle, you 
                    // could increase the three here to four by multiplying s.x by 4/3. 
                    // You'd want to do it for the horizontal case below as well.
                    ang += -(q.y + .25)*s.x;
                    
                    // Region ID.
                    regID = ip + .3;
                    
                }
                else {
                    
                    // See the comments above.
                    ang += (q.x + .25)*s.y;
                    
                    // Region ID.
                    regID = ip + .1;
                    
                }
               

            }
            else if(borders == 2){
                
                // Two borders mean a curved inner bend rendering.
                
                vec2 offs = qCp[0] +  qCp[1];
                d = min(d, dist(q - offs, vec2(.25)));
                
                // Quarter circles, so four segments per complete
                // revolution, which means... Carry the one... The
                // figure Zach chose works perfectly, so that's good
                // enough for me. :D
                //
                // Current angle. You could use the "s" variable too.
                //ang += atan(q.y - s.y/4., q.x - s.x/4.)/6.283*4.;
                ang += -atan(q.x - offs.x, q.y - offs.y)/3.14159;
                
               
                   // Region ID.
                regID = ip + .2;
                
            }
            else {
                
                 // No borders in a non-empty quadrand requre a curved 
                // outer bend rendering.
                
                 vec2 offs = qCp[0] +  qCp[1];
                 d = min(d, dist(q - offs, vec2(.25)));
                 
                 // Current angle. You could use the "s" variable too.
                 //ang += atan(q.y - s.y/4., q.x - s.x/4.)/6.283*4.;
                 ang += atan(q.x - offs.x, q.y - offs.y)/3.14159;
                

                 // Region ID.
                 regID = ip + .4;
                 
            }
            
        }
            
        
    }
    
    
    // Rendering lines around the original Wang tile borders, which is a
    // bit wasteful, but this is a cheap 2D example.
    d3 = min(d3, lBoxHV(p, vec2(-.5, -.5), vec2(-.5, .5), 0.));
    d3 = min(d3, lBoxHV(p, vec2(.5, -.5), vec2(.5, .5), 0.));
    d3 = min(d3, lBoxHV(p, vec2(-.5, .5), vec2(.5, .5), 0.));
    d3 = min(d3, lBoxHV(p, vec2(-.5, -.5), vec2(.5, -.5), 0.));
    
    #ifdef SHOW_ORIGINAL_GRID
    d3 -= .045;
    #endif

    //#ifndef SHOW_ORIGINAL_GRID
    // Region border construction: Ugly coding at its finest. :)
    //
    // I wanted to render region borders, and needed a quick working
    // method. It works, but I'm pretty sure there are way more 
    // streamlined ways to get the job done.
    if(id==1. || id==4.){
        d3 = min(d3, lBoxHV(p, eps[1], eps[3], 0.));
    }
    
    if(id==2. || id==8.){
        d3 = min(d3, lBoxHV(p, eps[0], eps[2], 0.));
    }
    
    if(id==3. || id==6. ||id==9. ||id==12.){
        d3 = min(d3, lBoxHV(p, eps[0], eps[2], 0.));
        d3 = min(d3, lBoxHV(p, eps[1], eps[3], 0.));
       
    }
    
    if(id==7. || id==13.) d3 = min(d3, lBoxHV(p, eps[0], eps[2], 0.));
    if(id==11. || id==14.) d3 = min(d3, lBoxHV(p, eps[1], eps[3], 0.));
    //#endif

    

    
    // Returning the border, main structure and current angle.
    return vec4(d, d2, d3, ang);
}

void main(void) {

    // Aspect correct screen coordinates.
    float iRes = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
    
    // Subtle barrel distortion.
    float r = dot(uv, uv);
    uv *= 1. + .025*(r*r*.5 + r);
    
    // Scaling and translation.
    float gSc = 6.;
    //rot2(3.14159/4.)*
    // Depending on perspective; Moving the oject toward the bottom left, 
    // or the camera in the north east (top right) direction. 
    vec2 p = uv*gSc - vec2(-.5, 0)*time;
    
   
    
    // Keeping a copy.
    vec2 oP = p;
    
    // Smoothing factor, based on scale and resolution.
    float sf = gSc/resolution.y;
  
    // The animated border distance field and the field for the shadow, 
    // which we're calling first, so as not to disturb some globals.
    vec4 dSh = distField(p - vec2(-.08, -.12));
    vec4 d = distField(p);
    
    // The straight rail, which we're not using at present.
    float oD = d.x;
    float oDSh = dSh.x;
    
    // Current angle. Used for animated object construction. 
    float ang = d.w;
    float angSh = dSh.w;
    
    // // The straight rail, which we're not using at present.
    d.x = abs(d.x) - .15;
    // The inner Wang tile structure.
    d.y -= .055;
    
    // The corresponding shadows.
    dSh.x = abs(dSh.x) - .15;
    dSh.y -= .055;
       
    
    
    // Use the region ID to generated a random palette color.
    // Four color palette.
    vec3[4] pal = vec3[4](vec3(1, .8, .2), vec3(1, .4, .2), vec3(.2, .8, 1), vec3(.2, .4, 1));
    vec3 col = pal[int(floor(hash21(regID)*3.999))];
    col = mix(col, col.yzx, uv.y*.75 + .5);
    
    #ifdef MONOCHROME
    float cRnd = hash21(regID); // Random cell color.
    col = vec3(1, .75 + cRnd*.1, .45 + cRnd*.2);
    #endif
    

    // Rendering the region borders.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.z - .01)));

    
     
    // If you increase the number of segments, you'll often have to
    // change the repeat shape width. Otherwise, you'll end up with
    // a continuous blob.
    const float aNum = 2.;
    // This is something I occasionally need to remind myself of: There are two
    // ways to render repeat objects around a curved surface. One is to obtain the
    // the angular position to the object's center on a curve, then render with 
    // aspect correct local coordinates -- That way, if you draw a square, it won't 
    // be mutated.
    //
    // However, there are times, like this, when you want the object to mold to the
    // underlying distance field's shape. The difference, in this case, is that I'm 
    // allowing the angle to vary from one side of the shape to the other, instead 
    // of snapping it to a central position. Obviously, for repeat objects, you 
    // still need to do the repetition thing, which is the case below.
    float a = (mod(ang*2., 1./aNum) - .5/aNum);
    
     // Distance field coordinates -- For a circle, you'd use something like 
    // vec2(angle, radiusDistance), but that's just a special case. In a more general
    // sense, it's vec2(angleOnSurface, surfaceDistance).
    vec2 distP = abs(vec2(a/2., oD));
    float rObj = sBoxS(distP, vec2(.05, .05), .025);
    rObj = rObj - .12;
    
    // The corresponding shadows.
    float aSh = (mod(angSh*2., 1./aNum) - .5/aNum);
    vec2 distPSh = abs(vec2(aSh/2., oDSh));
    float rObjSh = sBoxS(distPSh, vec2(.05, .05), .025);
    // Cutting a whole out of the shadow to give it a caustic effect.
    // Completely fake, of course. The correct line is below it. 
    rObjSh = max(rObjSh - .12, -(rObjSh - .04));
    //rObjSh = rObjSh - .12;
    
    
    // It's possible to rotate object colors, but not many.
    //float objID = mod(floor(ang*aNum*2.), aNum);
    
    // Object color.
    vec3 oCol = vec3(1);
    
    
    #ifdef SHOW_RAILS
    // With the translucent rails option, decrease the size of the
    // rounded square objects slightly.
    rObj += .01;
    rObjSh += .01;
    #endif
    

    
    #ifdef SHOW_INNER_STRUCTURE
    // When dispaying the inner structure, merge its shadow with the 
    // outer framework.
    #ifdef SHOW_RAILS
    dSh.x = min(max(dSh.x, -rObjSh), dSh.y);
    #else
    rObjSh = min(rObjSh, dSh.y);
    #endif    
    #endif
    
    #ifdef SHOW_ORIGINAL_GRID
    #ifdef SHOW_RAILS
    dSh.x = min(dSh.x, dSh.z);
    #else
    rObjSh = min(rObjSh, dSh.z);
    #endif
    #endif
    
    // Lay down the shadows.
    #ifdef SHOW_RAILS
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., dSh.x))*.7);
    #else
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., rObjSh))*.7); 
    #endif
    
    #ifdef SHOW_ORIGINAL_GRID
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, d.z + .02)));
    #endif
    
    // Render the objects themselves, in a fake translucent manner.
    vec3 svCol = col;
    #ifdef SHOW_RAILS
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.x)));
    col = mix(col, min(svCol*2., 1.), (1. - smoothstep(0., sf, d.x + .03)));
    #else
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, rObj)));
    col = mix(col, min(svCol*2., 1.), (1. - smoothstep(0., sf, rObj + .03)));
    #endif
    
   
    // Applying the middle section of the repeat animated pattern.
    svCol = col;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, rObj + .06)));
    col = mix(col, mix(svCol*2., oCol, .75), (1. - smoothstep(0., sf, rObj + .09)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., max(rObj + .09, rObjSh + .02)))*.15);
     
    
    #ifdef SHOW_INNER_STRUCTURE
    // Render the inner Wang tile structure.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.y)));
    col = mix(col, mix(svCol*2., vec3(1, .85, .35), .75), (1. - smoothstep(0., sf, d.y + .03)));
    #endif
    
    // Apply some subtle noise.
    float ns = fbm(oP/gSc*96.*max(iRes/450., 1.));
    vec3 tx = mix(vec3(1, .8, .7), vec3(.05, .1, .15), ns);
    col *= tx*.5 + .7;
    
    // Subtle vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    float vig = pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./6.);
    col *= min(vig*1.25, 1.);
    
    
    // Rough gamma correction, then output to the screen.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
