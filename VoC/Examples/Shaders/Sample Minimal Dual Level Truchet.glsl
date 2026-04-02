#version 420

// original https://www.shadertoy.com/view/ltcfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    
    Minimal Dual Level Truchet
    --------------------------

    This is a fairly minimal dual-level Truchet pattern implementation -- utilizing 
    a large non-overlapping tile and a complimentary smaller one. Obviously, it's 
    less interesting than the multiscale version constructed with overlapping tiles, 
    but it has a certain clean appeal to it.

    I've put it together for anyone who's interested in the process, but doesn't have 
    time to decipher the logic in my "Quadtree Truchet" example. By the way, Abje has 
    an interesting version, which I've linked to below.

    I've made the two-iteration quadtree loop as minimal, yet readable, as possible,
    but it could be cut down further. However, I'll leave it to the code golfers to 
    write the one or two tweet version. :)

    I really held back on the rendering, but I at least wanted to make it look 
    presentable. When rendering a 2D distance field, I usually like to take advantage 
    of the pixel shader environment and mix in a few layers. This has the standard 
    shadow, edge and opaque layers, with some additional field-based patterns and 
    highlighting. For anyone not familiar with the process, it's worth learning,
    because you can add a some extra dimension to your flat 2D imagery, which, on a
    lot of occasions, can provide more viual interest.

    Anyway, 2D extruded and 3D versions are next. I also have a more interesting 
    looking tri-level example, so I should probably post that as well.

    
    // Multiscale versions with overlapping tiles:

    // More elaborate quadtree example.
    Quadtree Truchet - Shane
    https://www.shadertoy.com/view/4t3BW4

    // Abje always has an interesting way of coding things. :)
    black and white truchet quadtree - abje
    https://www.shadertoy.com/view/MtcBDM

    // A really simple non-overlapping quadtree example.
    Random Quadtree - Shane
    https://www.shadertoy.com/view/llcBD7
    

*/

// Standard single scale (one level) Truchet pattern -- otherwise knows as a 
// Truchet pattern. :) Actually, I find it effectively illustrates how the
// dual scale pattern relates to the regular one.
//#define SINGLE_SCALE

// vec2 to vec2 hash.
vec2 hash22(vec2 p){ 

    // Faster, but doesn't disperse things quite as nicely.
    return fract(vec2(262144, 32768)*sin(dot(p, vec2(57, 27))));
}
 

void main(void) {

    
    // Screen coordinates, plus some screen resolution restriction to stop the
    // fullscreen version from looking too bloated... unless people are on a high
    // PPI device, in which case you'd need a PPI variable to account for that,
    // which isn't standard or trivial at present. Either way, it's all too hard,
    // so I'll make do with this hack. :)
    float iRy = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRy;
    
    // Scaling and translation.
    vec2 oP = uv*4. + vec2(.5, time/2.);

    
    // Distance tile values and random entries. Each represents the chance that
    // a tile for each layer will be rendered. For instance, the large tile 
    // will have a 50% chance, and the remaining smaller tiles will have a 100% 
    // chance. I.e., they'll fill in the rest of the squares.
    vec2 d = vec2(1e5), rndTh = vec2(.5, 1);
    
    #ifdef SINGLE_SCALE
    rndTh.x = 1.;
    #endif

    // Initial cell dimension.
    float dim = 1.;    
    
    for(int k=0; k<2; k++){
        
        // Base cell ID.
        vec2 ip = floor(oP*dim);
        
        // Unique random ID for the cell.
        vec2 rnd = hash22(ip);

       
        // If the random cell ID at this particular scale is below a certain threshold, 
        // render the tile. 
        if(rnd.x<rndTh[k]){
            
            // Tile construction: By the way, the tile designs you use are limited by your imagination. 
            // I chose the ones that seemed most logical at the time -- Arcs and grid vertice circles.

           
            // Local cell coordinate.
            vec2 p = oP - (ip + .5)/dim; // Equivalent to: mod(oP, 1./dim) - .5/dim;
            
            // Grid lines.
             d.y = abs(max(abs(p.x), abs(p.y)) - .5/dim) - .0075;
         
             
            // Use the unique random cell number to flip half the tiles vertically, which,
            // in the case, has the same effect as rotating by 90 degrees.
            p.y *= rnd.y>.5? 1. : -1.;
           
            // Arc width: Arranged to be one third of the cell side length. This is half that
            // length, but it gets doubled below.
            float aw = .5/3./dim;

            // Rendering the two arcs by rendering one arc flipped across the diagonal: It's an old 
            // trick that works in some situations, like this one. Alternatively, you could uncomment 
            // the diagonal reflection line below and render another arc on the opposite diagonal.
            p = p.x>-p.y? p : -p.yx;
            d.x = abs(length(p - .5/dim) - .5/dim) - aw;
            
            // Negate the arc distance field values on the second tile.
            d.x *= k==1? -1. : 1.;
          
            #ifndef SINGLE_SCALE 
            // Placing circles at the four corner grid vertices. If you're only rendering one 
            // level (rndTh[0]=1.), you won't need them... unless you like the look, I guess. :)
            d.x = min(d.x, (length(abs(p) - .5/dim) - aw));
            #endif
             
            // Increasing the overall width of the pattern slightly.
            d.x -= .01;
 
            // Since we don't need to worry about neighbors
            break;

        }
        
        // Subdividing. I.e., decrease the cell size by doubling the frequency.
        // Equivalent to writing "dim = exp2(float(k))" at the top of the loop.
        dim *= 2.;
        
    }
    
    // RENDERING.
    //
    // A lot of the following lines are for decorative purposes.
    
    // Scene color. Initiated to the background.
    vec3 col = vec3(.1);

    // Render the grid lines.
    float fo = 4./iRy;
    col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d.y - .01))*.5); // Shadow.
    col = mix(col, vec3(1), (1. - smoothstep(0., fo, d.y))*.15); // Overlay.
 

    // Render the tiles. This is a lazy way to do things, but it gets the job done.
    fo = 10./iRy/sqrt(dim);
    float sh = max(.75 - d.x*10., 0.); // Distance field-based shading.
    sh *= clamp(-sin(d.x*6.283*18.) + .75, -.25, 1.) + .25; // Pattern overlay.

    col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d.x))*.75); // Shadow.
    col = mix(col, vec3(0), 1. - smoothstep(0., fo, d.x)); // Outline.
    // Greyish, shaded, pattern overlay.
    col = mix(col, vec3(.3)*sh, 1. - smoothstep(0., fo, d.x + .015)); 
    // Pinkish, shaded color.
    // abs(d.x + .12) - .02 = max(d.x + .1, -(d.x + .14))));
    col = mix(col, vec3(.8, .03, .1)*sh, 1. - smoothstep(0., fo, abs(d.x + .12) - .02));
      
    
     
    // UV color mixing.
    col = mix(col, col.xzy, uv.y*.5 + .5);
    
    // Mild spotlight.
    col *= max(1.25 - length(uv)*.25, 0.);
    

    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
