#version 420

// original https://www.shadertoy.com/view/wlyfWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Pseudo Refraction
    -----------------
    
    For all intents and purpose, this is a rough reproduction of a cheap 
    pseudo refraction technique that Nusan used in his "Drop of Distortion" 
    shader. There's not much to it: Code up something blob-like above a 
    plane, take the intersection point, cast the refracted ray down to the 
    plane, then use the resultant XY position to index into whatever 
    texture you decide to use to cover the back plane.
    
    Back in the day, multiple refractive bounces weren't really an option, 
    so this was the next best thing. It definitely won't fool you into 
    believing it's a fully fledged refractive blobby material floating 
    above a plane, but it's visually interesting and has a refractive feel. 
    In addtion, Nusan added some glow, which I thought looked pretty cool, 
    so I put some of that in as well.
    
    Metaballs are one my favorite oldschool effects. When raymarching 
    wasn't a feasible option, it was necessary to use the marching cubes 
    algorithm. Ironically, achieving the oldschool polygonized faceted look 
    would be quite difficult in a pixel shader, but at some stage, I'm 
    going to attempt that... or wait for someone else on here to do it. 
    Whichever comes first. :)
    

    // Based on the following:
    
    Drop of Distortion - Nusan
    https://www.shadertoy.com/view/WdKXWt

*/

// Background pattern: Truchet checkers: 0, Circle checkers: 1.
#define PAT 0

// Colored glow.
#define COLOR

// Subtle textured lines.
#define LINES

// Object ID: Either the back plane or the metaballs.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

/*
// Exponential based smooth minimum: Nicer, but more expensive.
float smin(float a, float b, float k){
    
    k *= 12.;
    return -log(exp(-a*k) + exp(-b*k))/k;
}
*/

// Standard metaball routine: Either determine the overall potential of 
// multiple spherical charges at a given point, or take the smooth 
// minimum between multiple spheres. Regardless of the route you take, 
// the result will resemble an isofield surface at the zero potential mark.
float meta(vec3 p){ 

    float d = 1e5; // Start with .5, if using the potential version. 
    
    for (int i = 0 ; i < 5 ; i++){
        // Move the spheres around.
        vec3 a = p - sin(vec3(1, 2, 5)*float(i) + time)/vec3(2, 2, 4);
        //d -= .2/dot(a, a); // Potential between balls.
        d = smin(d, length(a) - .2, .5); // Smooth minimum.
    }
    
    return d; // Return the distance.
}

// Distance function.
float m(vec3 p){
    
    // Back plane.
    float fl = -p.z + .25;
    
    // Rotate the metaballs as a whole.
    p.xy = rot2(-time/4.)*p.xy;
    // Metaball distance.
    float obj = meta(p);
   
    // Object ID.
    objID = fl<obj? 0 : 1;
    
    // )verall minimum distance.
    return min(fl, obj);
    
}
  
// Standard normal function.
vec3 nr(in vec3 p){
    const vec2 e = vec2(.001, 0);
    return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),    
                          m(p + e.yyx) - m(p - e.yyx)));
}

void main(void) { //WARNING - variables void (out vec4 c, vec2 u){ need changing to glFragColor and gl_FragCoord.xy

    vec2 u=gl_FragCoord.xy;
    vec4 c=glFragColor;

    //u += (hash21(u*57. + fract(time)) - .5)*5.;
    
    // Aspect correct coordinates. Only one line necessary.
    u = (u - resolution.xy*.5)/resolution.y;
    
    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(0, 0, -2), l = vec3(.25, .25, -1.5);
    
    // Rotating the camera about the XY plane.
    r.xy = rot2(time/8.)*r.xy;
    //r.xz = rot2(.1)*r.xz;
    
 
  
    
    // Standard raymarching setup.
    float d, t = hash21(r.xy*57. + fract(time))*.5, glow = 0.;
    // Raymarch.
    for(int i=0; i<96; i++){ 
        
        d = m(o + r*t); // Surface distance.
        if(d<.005) break; // Surface hit.
        t += d*.5; // Advance the overall distance closer to the surface.
        
        //float rnd = hash21(r.xy + float(i)/113. + fract(time)) - .5;
        glow += .2/(1. + abs(d)*5.);// + rnd*.2;
        
         
    }
    
    // Object ID: Back plane (0), or the metaballs (1).
    int gObjID = objID;
    
    
    // Very basic lighting.
    // Hit point and normal.
    vec3 p = o + r*t, n = nr(p);
    
    
    
    // UV texture coordinate holder.
    vec2 uv;
    
    // If we've hit the metaball surface, refract the ray and 
    // calculate the UV coordinates.
    if(gObjID==1){
    
        // Refractive ray at the surface: I'm pretending the blobs are
        // filled with something gelatinous, which has a rough refractive
        // index of 1.5... Sounds good anyway. :D
        vec3 ref = refract(r, n, 1./1.5);
        float flDist = 2.25; // Floor distance from camera.
        
        // Starting at the surface, cast a ray in the refracted direction
        // then get the XY component of the resultant back plane hit point.
        // This will be your UV components, which you'll use to index into
        // a texture. In this case, we'll generate a texture pattern with
        // the coordinates.
        uv = p.xy*flDist/(t*ref.z); 
 
    }
    else uv = p.xy; // Back XY plane texture coordinates.
    
 
    
    
    // Cell ID and local cell coordinates for the texture we'll generate.
    //
    float sc = 1./3.; // Scale: .5 to about .2 seems to look OK.
    vec2 iuv = floor(uv/sc) + .5; // Cell ID.
    uv -= iuv*sc; // Local cell coordinates.
    
    // Construct a simple background texture. It doesn't need to be too fancy,
    // but a small amount of detail can help bring out the refractive effect
    // a little more. These simple patterns took less than five minutes, and
    // were made up on the spot.
    //
    #if PAT == 0
    float rnd = hash21(iuv); // Random threshold number.
    if(rnd<.5) uv.y = -uv.y; // Flip random cell coordinates.
    d = min(length(uv - .5*sc), length(uv + .5*sc)) - .5*sc; // Two diagonal circles.
    float arc = abs(d) - .005; // Make a Truchet arc.
    d = min(d, (length(uv) - .02)); // Add some little circles.
    if(rnd<.5) d = -d; // Reverse the field for each random threshold.
    //if(mod(iuv.x + iuv.y, 2.)<.5) d = -d; // Reversing checkers.
    // Double up on some lines.
    d = min(d + .02, abs(d));
    #else
    d = length(uv) - sc*.25;
    if(mod(iuv.x + iuv.y, 2.)<.5) d = -d;// + .02;
    d = min(d + .02, (abs(d) + .0));
    #endif
  
    
    
    // Begin rendering the background texture. 
    vec4 oCol = mix(vec4(.05), vec4(1), 1. - smoothstep(0., .01, d));
    
    // Save the current color.
    vec4 svCol = oCol; 
    
    // Smooth borders.
    float bord = max(abs(uv.x), abs(uv.y)) - .5*sc;
    bord = abs(bord) - .001;
    // Omit the middle of edges where the Truchet passes through.
    oCol = mix(oCol, vec4(0), 1. - smoothstep(0., .01, bord));
    
    #ifdef LINES
    // Subtle lines for a bit of texture.
    vec2 luv = uv;
    float pat = abs(fract((luv.x + luv.y)*40. + .5) - .5)*2. - .25;
    vec4 lCol = mod(iuv.x + iuv.y, 2.)<.5? vec4(.25) : vec4(.125);
    oCol = mix(oCol, lCol, (1. - smoothstep(0., .01*40., pat))*.35);
    #endif
    
    #if PAT == 0
    // Render the background arcs.
    oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01*8., arc - .01))*.5);
    oCol = mix(oCol, vec4(0), 1. - smoothstep(0., .01, arc - .005));
    oCol = mix(oCol, svCol, 1. - smoothstep(0., .01, arc)); 
    #endif

    // Basic point lighting.   
    vec3 ld = l - p;
    float lDist = length(ld);
    ld /= lDist; // Light direction vector.
    float at = 1./(1. + lDist*lDist*.75); // Attenuation.
    float df = max(dot(n, ld), 0.); // Diffuse.
    float sp = pow(max(dot(reflect(r, n), ld), 0.), 32.); // Specular.
    
      
    // Apply the lighting. 
    c = oCol*(df/4. + vec4(1)*sp*2. + .75); // Coloring, diffuse plus ambience.
    
    // Cheap edging. 
    // Used for cheap edging. It only works for particular objects.
    float edge = dot(r, n);
    c = mix(c, vec4(0), (1. - smoothstep(0., .1, -.35 - edge))*.5);
    c = mix(c, vec4(1), (1. - smoothstep(0., .05, -.2 - edge))*.5);
    
     
 
    #ifdef COLOR
    vec4 gCol = vec4(4, 2, 1, 0);
    #else
    vec4 gCol = vec4(2);
    #endif
    // Coloring the glow, which is not to be confused with applying
    // the glow.
    c *= mix(mix(vec4(1), gCol, min(glow/4., 1.)), 
         vec4(1), float(1 - gObjID)*(1. - smoothstep(0., 1., glow - 1.5)));
    

    // Laying down something slightly shadowy looking -- Totally fake.
    c *= (max(1. - glow/2., .0))*1.5 + .2;
 
    // Very very cheap shadows -- Not used here.
    //c *= max(min(min(m(p + ld*.1), m(p + ld*.2)), m(p + ld*.3))/.1, 0.) + .15;
    
  
    // Reverse, of sorts.
    //c = pow((1. - c.zyxw), vec4(8));

    // Applying the glow and attenuation, then applying some fake
    // spotlight attenuation for a bit more atmosphere.
    c *= glow*at*(1. - smoothstep(0., 1.5, length(p.xy) - .5)*.85);
    
    
    // Time based color transition.
    //c = mix(c.yxzw, c, smoothstep(-.05, .05, sin(time/4. + .2)));
   
    
    // Mixing the color a bit more.
    c = mix(c, c.xzyw, length(u));
    c = mix(c.zyxw, c, smoothstep(-.15, .15, u.y));
    
        
    // Just the diffuse metaballs. 
    //float fr = pow(max(1. + dot(r, n), 0.), 5.);
    //c = vec4(1)*(df + fr); 

    // Rough gamma correction.
    c = sqrt(max(c, 0.));  

    glFragColor=c;
}
