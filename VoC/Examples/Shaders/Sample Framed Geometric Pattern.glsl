#version 420

// original https://www.shadertoy.com/view/tsKGzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Framed Geometric Pattern
    ------------------------

    I made this a while ago. It's not that exciting, but I thought I'd put
    it up anyway. :)

    The picture-framed image is a bit of a computer graphics cliche, but an 
    effective way to display an otherwise simple geometric pattern. Like a 
    lot of grid-based patterns out there, this one is Truchet based. The 
    picture frame itself was applied using standard distance field and 
    layering techniques.

    The background image is just some offset circles and is based on an
    underlying herringbone grid pattern. The timber is just an application of 
    an old layered noise technique, which I'd imagine was first oulined by 
    Ken Perlin, back in the day.

    
    Other Examples:

    // BigWIngs's popular Youtube channel. It's always informative seeing how 
    others approach various graphics topics.
    Shader Coding: Truchet Tiling Explained! -  The Art of Code
    https://www.youtube.com/watch?v=2R7h76GoIJM

    // Flipped Truchet pattern basics. Fabrice does it in a few of his 
    // examples too, if anyone wants to track them down.
    TruchetFlip - JT
    https://www.shadertoy.com/view/4st3R7

*/

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// IQ's animated vec2 to float hash.
float hash21A(vec2 p){  
    float x = fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); 
    return sin(x*6.2831 + time/3.)*.5 + .5;
}

// IQ's rounded box formula -- slightly modified.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// Textureless 3D Value Noise:
//
// This is a rewrite of IQ's original. It's self contained, which makes it much
// easier to copy and paste. I've also tried my best to minimize the amount of 
// operations to lessen the work the GPU has to do, but I think there's room for
// improvement. I have no idea whether it's faster or not. It could be slower,
// for all I know, but it doesn't really matter, because in its current state, 
// it's still no match for IQ's texture-based, smooth 3D value noise.
//
// By the way, a few people have managed to reduce the original down to this state, 
// but I haven't come across any who have taken it further. If you know of any, I'd
// love to hear about it.
//
// I've tried to come up with some clever way to improve the randomization line
// (h = mix(fract...), but so far, nothing's come to mind.

float n3D(vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
    const vec3 s = vec3(27, 113, 57);
    
    vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
    p -= ip; // Cell's fractional component.
    
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Smoother version of the above. Weirdly, the extra calculations can sometimes
    // create a surface that's easier to hone in on, and can actually speed things up.
    // Having said that, I'm sticking with the simpler version above.
    //p = p*p*p*(p*(p * 6. - 15.) + 10.);
    
    // Even smoother, but this would have to be slower, surely?
    //vec3 p3 = p*p*p; p = ( 7. + ( p3 - 7. ) * p ) * p3;    
    
    // Cosinusoidal smoothing. OK, but I prefer other methods.
    //p = .5 - .5*cos(p*3.14159);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
    
}

// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(27, 57)));
    //return fract(vec2(262144, 32768)*n)*2. - 1.; 
    
    // Animated.
    p = fract(vec2(262144, 32768)*n);
    return sin(p*6.2831853 + time*1.57); 
    
}

// The Truchet distance field. Truchet patterns, in their various forms, are 
// pretty easy to put together; Render some rotationally symmetric tiles, then
// randomly rotate them. If you know how to render simple 2D objects like 
// squares, circles, arcs, etc, you should be good to go. As you can see from
// the imagery, these tiles consist of a line of circles and some chopped
// out circles.
float distField(vec2 p){
    
    // Saving the original position.
    vec2 oP = p;
 
    // Cell ID and local coordinates.
    vec2 ip = floor(p);
    p -= ip + .5;
    
    // Random value for the tile. This one is time based.
    float rnd = hash21A(ip);
    
    // If the random number generated by the unique ID for the
    // tile is above a certain threshold, flip it upside down.
    if(rnd<.5) p.y = -p.y;
  
    
    // Distance field.
    float d = 1e5;
    
    // Radius.
    float r = .09;
    
    // Two circles on diagonally opposite corners.
    d = min(d, length((p) - vec2(-.5, .5)) - .5);
    d = min(d, length((p) - vec2(.5, -.5)) - .5);

    // Some small circles down the center.
    float d2 = length(p - .3) - r*.9;
    d2 = min(d2, length(p - .1) - r*.7); 
    d2 = min(d2, length(p + .1) - r*.7); 
    d2 = min(d2, length(p + .3) - r*.9);  
    
    // Flip checkered tiles. It's a necessary operation to perform
    // for this style of Truchet tile.
    if(mod(ip.x + ip.y, 2.)<.5) d = -d;
    if(rnd>=.5) d = -d;
    
    // Put in some decorative borders. I like them, but you can take
    // them out if you feel it's too much.
    d = max((d - r*1.25), -(abs(abs(d ) - .05) - r/3.));
    
    // Combining the dotted lines and circles, whilst allowing for
    // the checkerboard flipping.
    if(mod(ip.x + ip.y, 2.)<.5){
        if(rnd<.5) d = max(d, -d2);
        else d = min(d, d2);
    }
    else {
       if(rnd<.5) d = min(d, d2);
        else d = max(d, -d2); 
    }
    
    // Adding a grid. Not necessary, but I like it.
    p = abs(p);
    float grid = abs(max(p.x, p.y) - .5) - .015;
    d = min(d, grid);
    
   
    // Rendering circles at the grid vertices, whilst accounting
    // for checkerboard flipping.
    vec2  q = oP - .5;
    vec2 iq = floor(q);
    q -= iq + .5;

    if(mod(iq.x + iq.y, 2.)<.5){
        d = min(d, length(q) - r*1.4);
    }
    else {
       d = max(d, -(length(q) - r*1.4));
    }
    

    // Return the distance field value.
    return d;
}

// Skewing and unskewing.
vec2 skewXY(vec2 p, vec2 v){ return mat2(1, -v.y, v.x, 1)*p; }
vec2 unskewXY(vec2 p, vec2 v){ return inverse(mat2(1, -v.y, v.x, 1))*p; }

// The background pattern.
vec4 bgField(vec2 q2){
    
    // Helper variables: Scale, skewing vector, 
    // individual cell dimension, and block dimension.
    const float scale = 1./1.25;
    const vec2 sk = vec2(1, -1)/5.; // 12 x .2
    vec2 dim = vec2(1.5, 1)*scale;
    vec2 s = (vec2(2.5, 2.5) - abs(sk)/2.)*scale; // 12 x .2

    
    
    float d = 1e5;
    vec2 cntr, p, ip;
    
    vec2 id = vec2(0);
    vec2 l = dim;
    cntr = vec2(0);
    float boxID = 0.;
    vec2 offs = vec2(1, 0);
    
    for(int i = 0; i<4; i++){
         
        // With herringbone arrangements, the rectangular tile needs to
        // be intermittently rotated by 90 degrees, which means flipping
        // dimensions, etc.
        if(i==2) {
            cntr = vec2((dim.x + dim.y)/2., -dim.y/4.);
            l = l.yx;
            offs = offs.yx;
        }
        
        p = q2 - cntr; // Local coordinates, based on a square grid.
        p = skewXY(p, sk); // Skewing by the X and Y skewing values.
        ip = floor(p/s); // Local tile ID.
        p -= (ip + .5)*s; // New local position.
        p = unskewXY(p, sk); // Unskewing.

        
        // Individual positional tile ID.
        vec2 idi = ip*s + cntr + l/2.;
        // Don't forget to unskew the ID... Yeah, skewing is confusing. :)
        idi = unskewXY(idi, sk);
        
        // The brick dimension itself. Not used here.
        //float di2D = sBoxS(p, l/2., .04);
       
 
        // We're rendering a large circle and two smaller circles in each 
        // rectangular tile, which are randomly flipped in accordance with
        // the tile ID.
        if(hash21(idi)<.5) p = -p;
        
        float lw = dim.y/4.; // Offset.
        float sz = dim.y/2.; // Size.
        float ew = .04*scale; // Empty border width, or margin, to CSS folk.
        
        vec3 df;
        
        // Large circle, and two smaller circles.
        df.x = length(p - offs*lw) - (sz - ew);
        df.y = length(p + offs*lw*2. + offs.yx*lw) - (sz/2. - ew);
        df.z = length(p + offs*lw*2. - offs.yx*lw) - (sz/2. - ew);

        // A little offset circle inside the large circle.
        vec2 rnd22 = hash22(idi);
        df.x = max(df.x, -(length(p - offs*lw - rnd22*(lw/2. + .05*scale)) - lw/2.5));          
 
        // Obtain the smallest of the three circles for this particular tile.
        vec3 dfi = df.x<df.y && df.x<df.z? vec3(df.x, offs*lw) :
                   df.y<df.z? vec3(df.y, offs*lw*2. + offs.yx*lw) :
                   vec3(df.z, offs*lw*2. - offs.yx*lw);
        
        // If one of the circle objects in this particular tile is smaller than the
        // overall smallest object, update the distance field, object ID, and make
        // a note of the rectangular tile ID.
        if(dfi.x<d){
            
            d = dfi.x;
            id = idi + dfi.yz;
            boxID = float(i);
            
        }
        
        // Move the position down by the longest length.
        cntr -= -dim.y;
        
    }
    
    // Return the distance, ID and rectangular tile ID.
    return vec4(d, id, boxID);
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

    // Return the hatch value.
    return hatch;
    
}

 
// One of many simple wood grain formulas. Not much thought was put into it.
// This one has accentuated grain marks for a more cartoonish look, but more
// realistic grains can be created in a simpilar fashion.
vec4 woodGrain(in vec3 p){

   
    // Noise.
    float ns = (n3D(p*96.)*.67 + n3D(p*192.)*.33);
    
    // Slight perturbation.
    //p += (n3D(2.5*p)*.66 + n3D(5.*p)*.34)*.5;
    p += (n3D(2.*p)*.57 + n3D(4.*p)*.28 + n3D(8.*p)*.15)*.5;
    
    // Stretching things out along one of the axes -- In this case the Y axis.
    p *= vec3(1, 80, 1)*4.;
    
    // Cheap fract lines.
    float v = fract(-p.y*.1);
    //float v = fract(dot(p, vec3(-.1)));
    v *= v;
    v = min(v, v*(1. - v)*5.); // Smoothing the fract lines.

    // Using the value above to produce the timber color. I did this a while
    // ago, but I'm sure I knew what I was doing at the time. :D
    vec3 rWood = pow(min(vec3(1.5, 1, 1)*mix(.3, .9, v), 1.), vec3(1, 3, 12));
    vec3 wood = mix(vec3(.6, .4, .2), vec3(1.2, .8, .4), v);
    //vec3 wood = mix(vec3(.5, .125, .025)/1.25, vec3(.75, .27, .05)*1.5, v);
    //vec3 wood = mix(vec3(1, .8, .6)/3., vec3(1.2, 1, .8), v);
    
    wood = mix(wood, rWood, .25 - v*.25);
    
    // Adding in a sprinking of noise.
    vec3 rNoise = pow(min(vec3(1, 1, 1)*mix(.8, 1., ns), 1.), vec3(1, 2, 3));
    wood = min(wood*rNoise*1.1, 1.);
    
    // Toning things down, just a touch.
    //wood = pow(wood, vec3(.95));
    
    // Returning the timber color value, and the distance value -- which in this
    // case, is just the red channel, but it could be something more sophisticated.
    return vec4(wood, wood.x);
}

void main(void) {
    

    // Aspect correct screen coordinates.
    float iRes = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
    
    // Scaling only.
    float gSc = 10.;
    vec2 p = uv*gSc;
    
    // Saving a copy of the original.
    vec2 oP = p;
    
    // Resolution based scaling.
    float sf = gSc/resolution.y;

    // The framed distance field.
    float d = distField(p);
    
    // The background pattern.
    vec4 dBg = bgField(rot2(-3.14159/4.)*oP);
    
    // Frame width, rounding factors and frame dimensions.
    const float frW = .45;
    const float rF = .05, rF2 = .01;
    const vec2 fDim = vec2(14, 6);
    
    // The square frame.
    vec2 q = p;
    float sqr = sBoxS(q, fDim/2. + frW*2., rF);
    float fr = max(sqr, -sBoxS(q,fDim/2., rF2)); 
  
    // The frame shadow.
    q = (p - vec2(frW/2., -frW/2.));
    float sqr2 = sBoxS(q, fDim/2. + frW*2., rF);
    float fr2 = max(sqr2, -sBoxS(q, fDim/2., rF2));
    
    
    // Using a standard distance filed operation to cut down the size of 
    // the cavas to the frame.
    d = max(d, sqr + frW*2.);

    
    // A hatch value, just to add a little extra texture here and there.
    float hatch = doHatch(oP/gSc, iRes);
    
    
    // The timber color.
    float frSh = clamp(.25 - fr/frW*2., 0., 1.);
    vec4 wGrain = woodGrain(vec3(oP/4., 1. + frSh*.1));
    // Last minute adjustment: Toning the wood grain down a bit, if desired.
    //wGrain.xyz = mix(wGrain.xyz, wGrain.w*wGrain.w*vec3(.85, .8, .75), .25);
 
    
    // Applying some cheap hatching.
    wGrain.xyz *= hatch*.3 + .8;

    
    // The scene color. Initialized to zero.
    vec3 col = vec3(0);
     
    
    // Applying the background circle pattern.
    vec4 wGrainBg = woodGrain(vec3(oP/3. + .5, 1.));
    col = vec3(.95, .8, .7)*(wGrainBg.w*.3 + .85);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*1.5, dBg.x))*.35);
    col = mix(col, vec3(.95, .8, .7)*(hatch*.2 + .9), (1. - smoothstep(0., sf, dBg.x + .05))*.7);

    // A cleaner background.
    //col = vec3(.95, .8, .7);
    //col *= wGrainBg.w*.5 + .7;     
    
    // Applying some subtle hatching.
    col *= hatch*.35 + .75;
         
    
    // Putting the frame shadow down first.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*15., fr2 - .05))*.65);
    
    // The frame.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., fr))*.5);
    col = mix(col, wGrain.xyz*frSh, (1. - smoothstep(0., sf, fr)));
   
   
    // The frame content: In this case, the dot-like Truchet pattern.
    col = mix(col, vec3(.8) + hatch*.3, (1. - smoothstep(0., sf, sqr + frW*2.)));
    col = mix(col, vec3(.01, .005, 0) + hatch*.05, (1. - smoothstep(0., sf, d)));
    
    // Outer edging.
    col = mix(col, vec3(.1, .05, 0), (1. - smoothstep(0., sf*1.5, abs(fr + .01) - .01))*.85);
    
    // Inner edging... or something like that -- Like everyone else, I make this stuff 
    // up as I go along. :)
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*1.5, abs(fr + .15) - .01))*.75);
    
    // Subtle highlighting.
    col = mix(col, col*1.35, (1. - smoothstep(0., sf*4., max((fr + .02), -(fr2 + .02)))));

  
    // Cheap paper grain.
    oP = floor(oP/gSc*1024.);
    vec3 rn3 = vec3(hash21(oP), hash21(oP + 2.37), hash21(oP + 4.83));
    col *= .9 + .1*rn3.xyz  + .1*rn3.xxx;    

     
     
    // Applying a subtle silhouette, for art's sake.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./32.); 
    
    // Output to screen
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
