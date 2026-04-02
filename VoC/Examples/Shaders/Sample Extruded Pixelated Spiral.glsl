#version 420

// original https://www.shadertoy.com/view/fsGXzG

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Extruded Pixelated Spiral
    -------------------------

    On Shadertoy I often come across very simple 2D examples that I like.
    Sometimes, if I think the base pattern is interesting enough, I might
    extrude it just to see what it looks like. Extruded imagery is a bit
    of a computer graphics cliche, but I like it.
    
    This particular image is loosely based on a minimal spiral image by
    Foxic -- The link is below, for anyone interested. To adhere to the 
    spirit of the original, I've extruded it in a pixelized manner and kept 
    roughly the same palette. However, it looks pretty interesting in other 
    colors too.
    
    Technically, there's not a lot to this. Hopefully, it'll run fine on
    most systems. It'd be a lot more efficient to render the 2D spiral on
    a backbuffer first, but I wanted to keep things simple.
    

    Inspired by:
    
    // I like the minimal design.
    Pixelized IceCreamSwirl - foxic
    https://www.shadertoy.com/view/NdVXWz
    
    // Tater's been putting up some pretty nice shaders lately.
    Spiraled Layers - Tater
    https://www.shadertoy.com/view/Ns3XWf

*/

// Global tile scale.
const vec2 scale = vec2(1./8., 1./8.);

// Off the rows by half a cell to produce a brickwork feel. The staggered 
// effect can also make a quantized image look smoother.
#define ROW_OFFSET

// Boring out holes on alternate blocks to give it more of a tech feel and
// to provide a little extra visual stimuli. Without the holes, the image
// looks cleaner, but less interesting, I feel.
#define HOLES

// Raising the faces of the pylon tops. I find it can help bounce the light 
// off the surface in a more reflective way.
//#define RAISED

// Putting a ridge decoraction on the pylon tops.        
//#define RIDGES

// Max ray distance.
#define FAR 20.

// Scene object ID to separate the mesh object from the terrain.
float objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

// Height map value.
float hm(in vec2 p){ 

    
    // Render the swirl by adding polar coordinates. You can apply the logarithm to
    // the length for a different kind of feel, but I'll leave it in its current form.
    float swirl = fract(atan(p.y, p.x)/6.2831 + length(p)*1.25 - time/4.);
    // Alternative octagon swirl -- Other metrics are also possible.
    /*
    vec2 ap = abs(p);
    float oct =  max(max(ap.x, ap.y), (ap.x + ap.y)*.7071);
    float swirl = fract(atan(p.y, p.x)/6.2831 + oct*1.5 - time/4.);
    */

    //swirl = abs(swirl - .5)*2.; swirl = smoothstep(.15, .85, swirl);
    swirl = sin(swirl*6.2831)*.5 + .5;
    
    
    // In the form above, the height transitions between zero and one.
    // The following simply manipulates the way in which that happens.
    
    // Number of quantization levels.
    #define lNum 4.
    float iswirl = floor(swirl*lNum*.9999)/lNum;

    // Arrange for the pylons to smoothly transition between quantization
    // levels whilst honoring the pixelated look... I could have described
    // that better, but hopefully, you know what I mean. :D
    return mix(iswirl, iswirl + 1./lNum, smoothstep(0., 1., swirl));
    // Popping unnaturally from one state to the next.
    //return iswirl*lNum/(lNum - 1.); 
    // Continuous, smooth motion.
    //return swirl; 
    
    
}

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
      return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}

/*
// Signed distance to a regular hexagon, with a hacky smoothing variable thrown
// in. -- It's based off of IQ's more exact pentagon method.
float sHexS(in vec2 p, float r, in float sf){
    
    
      const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.

      // X and Y reflection.  
      p = abs(p); 
      p -= 2.*min(dot(k.xy, p), 0.)*k.xy;

      r -= sf;
      // Polygon side.
      return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r) - sf;
    
}
*/

/*
// IQ's unsigned box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}
*/

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}

 
// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.

vec4 blocks(vec3 q3){
    
    

    // Brick dimension: Length to height ratio with additional scaling.
    const vec2 l = scale;
    const vec2 s = scale*2.;
    const float minSc = min(scale.x, scale.y);
    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual brick ID.
    vec2 id = vec2(0); 
    
    // Four block corner postions.
    #ifdef ROW_OFFSET
    // Offset rows.
    vec2[4] ps4 = vec2[4](vec2(-.25, .25), vec2(.25), vec2(.5, -.25), vec2(0, -.25)); 
    #else
    vec2[4] ps4 = vec2[4](vec2(-.25, .25), vec2(.25), vec2(.25, -.25), vec2(-.25)); 
    #endif
    
    float boxID = 0.; // Box ID. Not used in this example, but helpful.
    
    for(int i = 0; i<4; i++){

        // Local coordinates.
        p = q3.xy;
        ip = floor(p/s - ps4[i]) + .5; // Local tile ID.
        
        // Correct positional individual tile ID.
        vec2 idi = (ip + ps4[i])*s;
        
        p -= idi; // New local position.

        // The extruded block height. See the height map function, above.
        float h = hm(idi);
        
        h *= .1;
            
        // One larger extruded block.
        float di2D = sBoxS(p, l/2. - .008, .02);        
        //float di2D = length(p) - l.x/2. + .004;
        // Hexagon option: Multiply scale by "vec2(1, 1.732/2.),"
        // and have the ROW_OFFSET define turned on.
        //float di2D = sHexS(p.yx, l.x/2. - .008, .02);

        #ifdef HOLES
        // Boring out some of the boxes.
        if((i&1)==0) di2D = max(di2D, -(di2D + minSc/4.));
        #endif
        
        // The extruded distance function value.
        float di = opExtrusion(di2D, (q3.z + h - .5), h + .5);
        
        
        #ifdef RAISED
        // Raised tops.
        di += di2D*.25;
        #endif
        
        #ifdef RIDGES
        // Putting ridges on the faces.
        di += sin(di2D/minSc*6.2831*3.)*.005;
        #endif
        
        /*
        // Lego.
        float cap = length(p) - scale.x/4.;
        cap = opExtrusion(cap, (q3.z + h - .5 + .035), h + .5);
        di = min(di, cap); //di = max(di, -cap)
        */
        
        

        // If applicable, update the overall minimum distance value,
        // ID, and box ID. 
        if(di<d){
            d = di;
            id = idi;
            // Not used in this example, so we're saving the calulation.
            //boxID = float(i);
        }
        
    }
    
    // Return the distance, position-base ID and box ID.
    return vec4(d, id, boxID);
}

// Block ID -- It's a bit lazy putting it here, but it works. :)
vec2 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = -p.z + .1;

    // The extruded blocks.
    vec4 d4 = blocks(p);
    gID = d4.yz; // Individual block ID.
    
 
    // Overall object ID.
    objID = fl<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded image
    return  min(fl, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(frames, 0); i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += d*.7; 
    }

    return min(t, FAR);
}

// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
    const vec2 e = vec2(.001, 0);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),    
                          map(p + e.yyx) - map(p - e.yyx)));
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 24; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.  
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, 
    // the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(frames, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
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

    float sca = 3., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}

void main(void) {

    
    // Screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Camera Setup.
    // Tilted camera, just to prove it's 3D. :)
    //vec3 ro = vec3(0, -1.3, -2.2); // Camera position, doubling as the ray origin.
    //vec3 lk = ro + vec3(0, .12, .25);//vec3(0, -.25, time);  // "Look At" position.
    // Front on camera.
    vec3 ro = vec3(0, 0, -2.2); // Camera position, doubling as the ray origin.
    vec3 lk = ro + vec3(0, 0, .25);//vec3(0, -.25, time);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
     vec3 lp = ro + vec3(-.25, .5, 1);// Put it a bit in front of the camera.
    

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.333; // FOV - Field of view.
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    // Swiveling the camera about the XY-plane.
    rd.xy *= rot2( sin(time)/32. );
    
     
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    vec2 svGID = gID;
    
    float svObjID = objID;
  
    
    // Initiate the scene color to black.
    vec3 col = vec3(0);
    
    // The ray has effectively hit the surface, so light it up.
    if(t < FAR){
        
      
        // Surface position and surface normal.
        vec3 sp = ro + rd*t;
        vec3 sn = getNormal(sp, t);
        
                // Light direction vector.
        vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
        float lDist = max(length(ld), .001);
        
        // Normalize the light direction vector.
        ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
        float sh = softShadow(sp, lp, sn, 16.);
        float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
        
        // Light attenuation, based on the distances above.
        float atten = 1./(1. + lDist*.05);

        
        // Diffuse lighting.
        float diff = max( dot(sn, ld), 0.);
        //diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
        
        // Specular lighting.
        float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
        
        // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
        // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
        float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
        float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
        
          
        // Obtaining the texel color. 
        vec3 texCol = vec3(.6);   

        // The extruded grid.
        if(svObjID<.5){
            
            float h = hm(svGID);
            
            texCol = mix(vec3(.05), vec3(1.4, .2, .6), h); // Pink.
            //texCol = mix(vec3(.05), vec3(.5, 1, .25), h); // Green.
            //texCol = mix(vec3(.05), vec3(.25, .7, 1.5), h); // Blue.
            //texCol = mix(vec3(.05), mix(vec3(1.4, .2, .6), vec3(2, .3, .3), diff*diff*1.5), h);
            
            // Extra blending options.
            //texCol = mix(texCol, texCol.xzy, h);
            //texCol = mix(texCol, texCol.zyx, clamp((ld.y - ld.x) - .5, 0., 1.));
            //texCol = mix(texCol.zyx, texCol, diff*diff*1.5);
             
            
            /*
            // Dark edges.
            vec2 lCoord = sp.xy - svGID;
            vec2 sc = scale;
            float lw = .005;
            float dS = abs(sBoxS(lCoord, sc/2. - .008, .02)) - lw;
            dS = max(dS, abs(sp.z + h*.1*2.) - lw/2.); // Just the rim.
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., .005, dS))*.8);
            */
 
        }
        else {
            
            // The dark floor in the background. Hiddent behind the pylons, but
            // you still need it.
            texCol = vec3(0);
        }
       

        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .3 + vec3(.25, .5, 1)*fre*0. + vec3(1, .97, .92)*spec*freS*2.*sh);
      
        // Shading.
        col *= ao*atten;
        
          
    
    }
          
    
    // Rought gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
