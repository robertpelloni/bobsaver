#version 420

// original https://www.shadertoy.com/view/3tGBWV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Extruded Octagon Diamond Truchet
    --------------------------------
    
    This is an extruded octagon diamond blobby Truchet that features all tile
    combinations. The template itself has been repurposed from my recent extruded
    Truchet example.
    
    The Truchet part itself was coded up pretty quickly, so there'd be more 
    efficient ways to go about it, like encoding the 2D field into a texture and 
    reading from that, but this was easier. :) 
    
    Other versions of the octagon diamond Truchet have already been posted, so 
    the blobby version is here mainly to complete the set. I like the pattern 
    because it has a weird sea creature feel to it. It'd be cool to see other dual 
    multitile blobby Truchet patterns, if anyone feels up to it.
    

    References:
    
    // Fizzer put together a Truchet pattern based on an octagonal diamond grid a
    // while back. The Truchet here is a different kind (blobs instead of arcs), but 
    // is essentially based on the same premise.
    4.8^2 Truchet - Fizzer
    https://www.shadertoy.com/view/MlyBRG
    
    // An extruded ocatagon diamond blobby Truchet pattern using 2D techniques.
    Faux Layered Extrusion - Shane
    https://www.shadertoy.com/view/Wsc3Ds

*/

// Subtle textured lines.
#define LINES

// Object ID: Either the back plane or the metaballs.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// The ocatagonal-dimond grid boundaries.
vec4 gridField(vec2 q){
    
    // Offsetting the diamond tiles by half a unit. 
    vec2 p = q - .5;
    vec2 ip = floor(p) + .5;
    p -= ip;

    
    // 2D diamond field... The dimensions are calculated using basic trigonometry. 
    // Although, I was still too lazy to do it myself.
    float dia = abs(p.x) + abs(p.y) - (1. - sqrt(2.)/2.);
    
    float d = 1e5;
    
    // If we're inside a diamond, then render the diamond tile. Anything outside of this
    // will obviously be inside an octagon tile.
    if(dia<.0){
        
        d = dia;
        
        ip += .5;
        
    }
    else {
        
        // If we're inside an octagon cell (outside a diamond), then obtain the 
        // ID (similar to the diaomond ID, but offset by half a cell) and 
        // fractional coordinates.
        p = q;
        ip = floor(p) + .5;
        p -= ip; // Equivalent to: fract(p) - .5;
        
        
        
        float oct = max((abs(p.x) + abs(p.y))/sqrt(2.), max(abs(p.x), abs(p.y))) - .5;
        d = oct;
    } 
    
    return vec4(d, ip, dia);
    
}
 

// Adx's considerably more concise version of Fizzer's circle solver.
// On a side note, if you haven't seen it before, his "Quake / Introduction" 
// shader is well worth the look: https://www.shadertoy.com/view/lsKfWd
void solveCircle(vec2 a, vec2 b, out vec2 o, out float r){
    
    vec2 m = a + b;
    o = dot(a, a)/dot(m, a)*m;
    r = length(o - a);
    
}

// Truchet distance formula. It's set to circles, but you could try
// the octagonal distance metric, if you wanted.
float distT(vec2 p){
    
    return length(p);
    
    /*
    // Straight and curved.
    p = abs(p);
    return max(length(p) - .04, max((p.x + p.y)*.7071, max(p.x, p.y)));
    */
    
    /*
    // 16 sided, for that straight edged look.
    p = abs(p);
    float d = max(max(p.x, p.y), (p.x + p.y)*.7071);
    p *= rot2(3.14159/8.);
    return max(d, max(max(p.x, p.y), (p.x + p.y)*.7071));
    */

}

// A blobby octagonal diamond structure. Test to see whether the pixel is inside
// a diamond tile or an octagonal tile, then render the appropriate tile.
// A diamond tile will have two circles cut out at opposite ends, and an octagon
// will have various circles cut out at the correct positions. It's all pretty simple.
// However blobby Truchet tiles on square-based grids need to have their distances
// flipped on alternating checkered tiles. It slightly complicates the code, but
// I'm sure it's nothing that people can't handle. :)
//
// Uncomment the "SHOW_GRID" define and refer to imagery get a better idea.
vec3 distFieldT(vec2 q){
    
    
    float d = 1e5;
    
    // Offsetting the diamond tiles by half a unit.
    vec2 p = q - .5;
    
    // Tile ID and local coordinates.
    vec2 ip = floor(p) + .5;
    p -= ip;
    
    
    const float sqrt2 = sqrt(2.);
    
    
    // Side length. Due to the symmetry, it's the side length of both the
    // octagon and diamond.
    float s = 1./(1. + sqrt2);
    
    
    // 2D diamond field... The dimensions are calculated using basic trigonometry. 
    // Although, I was still too lazy to do it myself.
    float dia = (abs(p.x) + abs(p.y))/sqrt2 - s/2.;
    
   
    
    
    float shape = 1e5;
    
    // If we're inside a diamond, then render the diamond tile. Anything outside of this
    // will obviously be inside an octagon tile. In case it isn't obvious, you could test
    // for an octagonal hit too, but a diamond is easier.
    if(dia<.0){
        
        
        // Rotate random tiles.
        float rnd = hash21(ip);
        if(rnd<.5) p = rot2(3.14159/2.)*p;
        
        // Chop out two circles on opposite corners. Use the define to display
        // the grid and refer to the imagery.
        p.y = abs(p.y);
        d = min(d, distT(p - vec2(0, s/sqrt2)) - s/2.);
        
        // Flip the distances on alternating checkered tiles.
        float ch = mod(ip.x + ip.y, 2.);
        if(ch<.5) d = -d;
        
        // Flip the distances on random tiles as well.
        if(rnd<.5) d = -d;
        
        // Moving the tile ID away from the center of the octagonal tile
        // to the center of the diamond tile.
        ip += .5;
        
        shape = dia;
        
    }
    else {
    
       
        
        // If we're inside an octagon cell (outside a diamond), then obtain the 
        // ID (similar to the diaomond ID, but offset by half a cell) and 
        // fractional coordinates.
        p = q;
        vec2 ip = floor(p) + .5;
        p -= ip; // Equivalent to: fract(p) - .5;
        
        shape = max((abs(p.x) + abs(p.y))/sqrt2, max(abs(p.x), abs(p.y))) - .5;
        
        // Rotate random tiles. You don't really the extra addition, but I 
        // figured it might mix things up more... maybe. :)
        float rnd = hash21(ip + vec2(.11, .41));
        float rnd2 = hash21(ip + vec2(.17, .31));
        
        if(rnd<.5) p = rot2(3.14159/4.)*p;
        
        if(rnd2<.333){
            // Chop out four circles on opposite corners. Use the define to display
            // the grid and refer to the imagery. 
        
            // Four small circles.
            d = min(d, distT(p - vec2(-.5, s/2.)) - s/2.);
            d = min(d, distT(p - vec2(s/2., .5)) - s/2.);
            d = min(d, distT(p - vec2(.5, -s/2.)) - s/2.);
            d = min(d, distT(p - vec2(-s/2., -.5)) - s/2.);
        }
        else if(rnd2<.666){
            
            // Two large arcs with two small circle cutouts.
            
            // Random rotation.
            float rnd3 = hash21(ip + vec2(.27, .53));
            p = rot2(3.14159/2.*floor(rnd3*64.))*p;
            
            
            vec2 o; float r;
            solveCircle(vec2(-.5, 0), vec2(sqrt2/4.), o, r); 
            // Top left;
            d = min(d, distT(p - o) - r);
            d = max(d, -(distT(p - vec2(-s/2., .5)) - s/2.));
            
            // Bottom right.
            d = min(d, distT(p + o) - r);
            d = max(d, -(distT(p - vec2(s/2., -.5)) - s/2.));
            
            
        
        }
        else {
        
            // One large arc with three small circle cutouts.
        
            // Random rotation.
            float rnd4 = hash21(ip + vec2(.34, .67));
            p = rot2(3.14159/2.*floor(rnd4*64.))*p;
            
            vec2 o; float r;
            solveCircle(vec2(-.5, 0), vec2(sqrt2/4.), o, r); 
            // Top left;
            d = min(d, distT(p - o) - r);
            d = max(d, -(distT(p - vec2(-s/2., .5)) - s/2.));
            
            
            d = min(d, distT(p - vec2(.5, -s/2.)) - s/2.);
            d = min(d, distT(p - vec2(-s/2., -.5)) - s/2.);
            
            
        
        }
        
        // Tile flipping: As an aside, I've never been able to logically 
        // combine the two following lines, but surely there's a way?
        // Probably a question for Fabrice Neyret to answer. :)
        
        // Flip the distances on alternating checkered tiles.
        if(mod(ip.x + ip.y, 2.)>.5)  d = -d;
        
        
        // Flip the distances on random tiles as well.
        if(rnd<.5) d = -d;
       
    }
    
    
    
    //d = max(d - .03, -(abs(shape) - .01));// - .02;
    //d = min(d + .05, abs(d + .02) - .05); // Truchet border.
    d -= .03; // Extra width.
    //d = mix(max(d - .03, -(abs(shape) - .01)), d - .03, smoothstep(-.1, .1, sin(time)));
    
    // Return the distance and center tile ID.
    return vec3(d, ip);
    
}

// Local stud position. Bad global hack, but it was a
// last minute addition. :)
vec2 stdP;
 
// Distance function.
float m(vec3 p){
    
    // Back plane.
    float fl = -p.z;
    
    // Octagon diamond Truchet object.
    vec3 o3 = distFieldT(p.xy);
    // Extruding the 2D field above.
    float obj = max(o3.x, abs(p.z) - .125) - smoothstep(.03, .1, -o3.x)*.05;// + obj*.5;
    
    
    // The cylindrical beacon like objects. I added them in out of sheer
    // bordom. I guess they're anaolgous to eyes, or something. :)
    float sc = 1.;
    vec2 q = p.xy;
    vec2 iq = floor(q/sc) + .5;
    q -= iq*sc;
    
    // Placing cylinders on alternate octagon vertices.
    const float s = 1./(1. + sqrt(2.));
    vec2 ep = vec2(s/2., .5);
    // Rotating alternate checkered octagons to align things.
    if(mod(iq.x + iq.y, 2.)<.5) q = rot2(3.14159/4.)*q;
    // Polar repetition.
    float a = atan(q.x, q.y);    
    a = (floor(a/6.2831*4.) + .5)/4.*6.2831;
    ep = rot2(a)*ep;
    stdP = q - ep; // Centered local beacon coordinates.
    float cyl = length(stdP) - .06*sc;
    
    // The cylindrical beacon.
    float beacon = max(cyl, abs(p.z) - .25);
       

     
    // Object ID.
    objID = fl<obj && fl<beacon? 0 : obj<beacon? 1 : 2;
    
    // )verall minimum distance.
    return min(min(fl, obj), beacon);
    
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int iter = 16; 
    
    ro += n*.0015; // Bumping the shadow off the hit point.
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    //rd = normalize(rd + (hash33R(ro + n) - .5)*.03);
    

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<iter; i++){

        float d = m(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

    float sca = 2., occ = 0.;
    for( int i = min(frames, 0); i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        // Deliberately redundant line that may or may not stop the 
        // compiler from unrolling.
        if(sca>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);
}
  

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 nr(in vec3 p) {
    
    const vec2 e = vec2(.001, 0);
    
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),    
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(frames, 0); i<6; i++){
        mp[i] = m(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}

void main(void) {

    vec2 u = gl_FragCoord.xy;
    vec4 c = glFragColor;

    // Aspect correct coordinates. Only one line necessary.
    u = (u - resolution.xy*.5)/resolution.y;
    
    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(0, time/2., -3), l = o + vec3(.25, .25, 2);
    
    // Rotating the camera about the XY plane.
    r.yz = rot2(.15)*r.yz;
    r.xz = rot2(-cos(time*3.14159/32.)/8.)*r.xz;
    r.xy = rot2(sin(time*3.14159/32.)/8.)*r.xy;
    
 
  
    
    // Standard raymarching setup.
    float d, t = hash21(r.xy*57. + fract(time))*.5, glow = 0.;
    // Raymarch.
    for(int i=0; i<96; i++){ 
        
        d = m(o + r*t); // Surface distance.
        if(abs(d)<.001) break; // Surface hit.
        t += d*.9; // Advance the overall distance closer to the surface.
        
        //float rnd = hash21(r.xy + float(i)/113. + fract(time)) - .5;
        glow += .2/(1. + abs(d)*5.);// + rnd*.2;
        
         
    }
    
    // Object ID: Back plane (0), or the metaballs (1).
    int gObjID = objID;
    
    // Saving the local beacon coordinates.
    vec2 lStdP = stdP;
    
    
    // Very basic lighting.
    // Hit point and normal.
    vec3 p = o + r*t, n = nr(p); 
    
    
    // UV texture coordinate holder.
    vec2 uv = p.xy;
    // Cell ID and local cell coordinates for the texture we'll generate.
    float sc = .5; // Scale: .5 to about .2 seems to look OK.
    vec2 iuv = floor(uv/sc) + .5; // Cell ID.
    uv -= iuv*sc; // Local cell coordinates.
  
     
    // Smooth borders.
    vec4 b2 = gridField(p.xy*5. + vec2(.5, 0));
    float bord = abs(b2.x/5.) - .004;
 

    // Subtle lines for a bit of texture.
    #ifdef LINES
    float lSc = 20.;
    float pat = (abs(fract((uv.x - uv.y)*lSc - .5) - .5)*2. - .5)/lSc;
    float pat2 = (abs(fract((uv.x + uv.y)*lSc + .5) - .5)*2. - .5)/lSc;
    #else
    float pat = 1e5, pat2 = 1e5;
    #endif  

    
    // Colors for the floor and extruded face layer. Each were made up and 
    // involve subtle gradients, just to mix things up.
    float sf = dot(sin(p.xy - cos(p.yx*2.)), vec2(.5));
    float sf2 = dot(sin(p.xy*1.5 - cos(p.yx*3.)), vec2(.5));
    vec4 col1 = mix(vec4(1., .75, .6, 0), vec4(1, .85, .65, 0), smoothstep(-.5, .5, sf));
    vec4 col2 = mix(vec4(.4, .7, 1, 0), vec4(.3, .85, .95, 0), smoothstep(-.5, .5, sf2)*.5);
    col1 = pow(col1, vec4(1.6));
    col2 = mix(col1.zyxw, pow(col2, vec4(1.4)), .666);   
    col1 = mix(col1, col1.xzyw*col1, smoothstep(.25, .75, sf2)*.5);
    //col1 = mix(col1, col1.yxzw, smoothstep(.4, .8, sf3)*.5); 

    // Object color.
    vec4 oCol;
    
    
    // Use whatever logic to color the individual scene components. I made it
    // all up as I went along, but things like edges, textured line patterns,
    // etc, seem to look OK.
    //
    if(gObjID == 0){
    
       // Blue background:
       
       // Blue with some subtle lines.
       oCol = mix(col2, vec4(0), (1. - smoothstep(0., .01, pat2))*.35);
       // Square borders: Omit the middle of edges where the Truchet passes through.
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);
       
       // Darken alternate checkers. 
       if(mod((b2.y) + (b2.z), 2.)<.5 && b2.w>0.) oCol *= .8;
       
       // Using the Truchet pattern for some bottom edging.
       float edge = distFieldT(p.xy).x;
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, edge - .015))*.8);
  
    }
    else if(gObjID == 1){
       
        // 2D Truchet pattern.
        d = distFieldT(p.xy).x;
    

        // Light sides with a dark edge. 
        oCol = mix(col1*.5 + .5, col2, .5);
        oCol = mix(oCol, vec4(0), 1. - smoothstep(0., .01, d + .03));
        
        // Colored gradient with subtle line pattern,
        vec4 fCol = mix(col1, vec4(0), (1. - smoothstep(0., .01, pat))*.35);
        // Borders: Omit the middle of edges where the Truchet passes through.
        fCol = mix(fCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);
        
        // Darken alternate checkers. 
        if(mod((b2.y) + (b2.z), 2.)<.5 && b2.w>0.) fCol *= .8;
        
        // Apply the gradient face to the Truchet, but leave enough room
        // for an edge.
        oCol = mix(oCol, fCol, 1. - smoothstep(0., .01, d + .05));
        
        // If the cylindrical markers are included, render dark rings just under them.
        float beacons = length(lStdP) - .14*sc;
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, beacons)));

    }
    else {
    
        // The cylinder markers:
        
        // Color and apply patterns, edges, etc.

        float beacons = length(lStdP);
        oCol = mix(col1*.5 + .5, col2, .5);
        
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, abs(beacons - .103*sc) - .0035)));
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, beacons - .03*sc)));
    
    }

    // Basic point lighting.   
    vec3 ld = l - p;
    float lDist = length(ld);
    ld /= lDist; // Light direction vector.
    float at = 1./(1. + lDist*lDist*.125); // Attenuation.

    
    // Very, very cheap shadows -- Not used here.
    //float sh = min(min(m(p + ld*.08), m(p + ld*.16)), min(m(p + ld*.24), m(p + ld*.32)))/.08*1.5;
    //sh = clamp(sh, 0., 1.);
    float sh = softShadow(p, l, n, 8.); // Shadows.
    float ao = calcAO(p, n); // Ambient occlusion.
    
    
    float df = max(dot(n, ld), 0.); // Diffuse.
    float sp = pow(max(dot(reflect(r, n), ld), 0.), 32.); // Specular.
    
      
    // Apply the lighting and shading. 
    c = oCol*(df*sh + sp*sh + .5 + glow/16.)*at*ao;
    // Very metallic: Interesting, but ultimately, a bit much. :)
    //c = oCol*oCol*1.5*(pow(df, 3.)*2.*sh + sp*sh*2. + .25)*at*ao;    
      
 
    // Rough gamma correction.
    c = sqrt(max(c, 0.));  

    glFragColor = c;

}
