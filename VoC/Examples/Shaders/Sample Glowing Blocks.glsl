#version 420

// original https://www.shadertoy.com/view/Xl3cWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Glowing Blocks
    --------------

    Applying some volumetric glow to a scene full of random blocky objects, just for the 
    fun of it. Nothing that hasn't been tried before.

    I'm not even sure what this is supposed to represent. I was experimenting with cheapish 
    glow using a backlit point light, then boredom set in. Anyway, back to what I was 
    supposed to be coding. :) 

    By the way, uncommenting the defines "NO_XY_ROTATION" and "NO_GLOW" gives an abstract
    city block appearance. At some stage, I plan to write an example that expands on that.

*/

// Far plane.
#define FAR 25.

// Takes out the cell object rotaion, which gives it more of an abstract city block look.
//#define NO_XY_ROTATION

// Takes out the glow to focus more on the geometry.
//#define NO_GLOw

// If you prefer circles.
//#define DO_CIRCLES

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// vec2 to vec2 hash. Cheap version using an oldschool trick. Not super trustworthy,
// but it works well enough in a lot of situations.
vec2 hash22(vec2 p){ 
    
    float n = sin(dot(p, vec2(111, 157)));    
    return fract(vec2(262144, 32768)*n); 
}

// vec3 to float hash.
float hash31(vec3 p){
   
    float n = dot(p, vec3(13.163, 157.247, 7.951)); 
    return fract(sin(n)*43758.5453); 
}

// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D( sampler2D t, in vec3 p, in vec3 n ){ 
    
    n = max(abs(n) - .1, 0.001);
    n /= dot(n, vec3(1));
    vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}

/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 texBump( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(.299, .587, .114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
    
}
*/

// IQ's 3D signed box formula: I tried saving calculations by using the unsigned one, and
// couldn't figure out why the edges and a few other things weren't working. It was because
// functions that rely on signs require signed distance fields... Who would have guessed? :D
float sBox(vec3 p, vec3 b){

  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0.));
}

// IQ's 2D signed box formula.
float sBox(vec2 p, vec2 b){

  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

//vec2 objID;

// ID for inner or outer frame.
vec2 oID;

// The overlapping random block distance field: In order to render repeat object that either
// sit up against one another, or slightly overlap, you have to render more than one cell to
// avoid artifacts. In this case, I've rendered some repeat boxy objects across the XY plane
// with random heights. Four cells need to be considered, which means rendering everything
// four times. This would be better unrolled, tweaked, etc, but I think it reads a little 
// better this way. Anyway, I've explained the process in other examples, like the "Jigsaw"
// example, and so forth.

float m(vec3 p){

    // Warp the XY plane a bit to give the scene an undulated look.
    p.z -= 3. + sin(p.x + p.y)*.125;
    
    // Box scale. If you change this, you might need to make box size changes, etc.
    const float sc = .5;
    
    // Cell centering.
    p += sc*.5;
    
    // The initial distance. I can't remember why I wanted this smallish amount. Usually, 
    // you'd set it to some large number.
    float d = 0.25;
    
    //objID = vec2(0);
    oID = vec2(0);
    
    for (int i=0; i<=1; i++){ 
        for (int j=0; j<=1; j++){ 

            // The cell ID.
            vec2 ip = floor((p.xy/sc - vec2(i, j)/2.))*sc + vec2(i, j)/2.*sc;
            // Local cell position. I remember figuring these out a while
            // back... I'll take my own word for it. :D
            vec3 q = vec3((mod(p.xy + vec2(i, j)/2.*sc, sc) - sc/2.), p.z);

            // Two random numbers for each cell... to do some random stuff. :)
            vec2 rnd = hash22(ip);

            #ifndef NO_XY_ROTATION
            // Random object rotation about the XY plane.
            q.xy *= r2((dot(rnd.xy, vec2(.5)) - .5)*6.2831*.15);
            #endif

            // Another random number to be used for the heights.
            rnd.x = fract(dot(rnd, vec2(27, 57)))*.25 + .375;
            // Quantizing the heights -- Not absolutely necessary, but it makes things
            // look a little neater.
            rnd.x = floor(rnd.x*25.999)/25.; 

            // Also not that necessary, but it shifts the base of the objects to a level
            // point... that is behind the scene, which means you can't see it... but I
            // know it's there, and without this line the hidden backwall wouldn't be flat. :D
            q -= vec3(0, 0, -rnd.x);

            #ifndef DO_CIRCLES
            // The box objects. I'm using IQ's more expensive functions, just because I need
            // the distance fields to be more correct away from the centers to get more even
            // looking glow.
            float obj = sBox(q, vec3(sc/4. + .05, sc/4. + .05, rnd.x - .005)); // Outer box casing.
            float obj2 = sBox(q, vec3(sc/4. + .01, sc/4. + .01, rnd.x)); // Inner box.
            // Four window-like objects.
            q.xy = abs(abs(q.xy) - .055);
            float obj2D = sBox(q.xy, vec2(sc/4., sc/4.));
            #else
            // Alternative circles.
            float obj = max(length(q.xy) - (sc/4. + .05), abs(q.z) - rnd.x + .005); // Outer.
            float obj2 = max(length(q.xy) - (sc/4. + .01), abs(q.z) - rnd.x); // Inner.
            q.xy = abs(abs(q.xy) - .05);
            float obj2D = length(q.xy) - sc/4.;
            #endif
            
            
            
            // Combine the inner and outer boxex, then carve out the windows.
            float obj3D = max(min(obj, obj2), -(obj2D + .0975)); 
            
            oID = (obj3D<d)? vec2(obj, obj2) : oID; // ID for inner or outer frame.

            // Individual object ID. Not used here.
            //objID = (obj<d)? ip : objID;

            // Minimum of the four cell objects. Similar to the way Voronoi cells are handled.
            d = min(d, obj3D);

        }
    }
  
    
    // Return the scene distance, and include a bit of ray shortening to avoid a few minor
    // inconsistancies.
    return d*.85;
    
}

// Basic soft shadows.
float shd(in vec3 ro, in vec3 n, in vec3 lp){

    const float eps = .001;
    
    float t = 0., shadow = 1., dt;
    
    ro += n*eps*1.1;
    
    vec3 ld = (lp - ro);
    float lDist = length(ld);
    ld /= lDist;
    
    
    //t += hash31(ro + ld)*.005;
    
    for(int i=0; i<24; i++){
        
        dt = m(ro + ld*t);
        
        shadow = min(shadow, 16.*dt/t);
         
         t += clamp(dt, .01, .25);
        if(dt<0. || t>lDist){ break; } 
    }

    return max(shadow, 0.);
    
}

// Ambient occlusion, for that self shadowed look.
// Based on the original by IQ.
float cao(in vec3 p, in vec3 n)
{
    float sca = 1., occ = 0.0;
    for( int i=1; i<6; i++ ){
    
        float hr = float(i)*.25/5.;        
        float dd = m(p + hr*n);
        occ += (hr - dd)*sca;
        sca *= .7;
    }
    return clamp(1. - occ, 0., 1.);   
    
}

/*
// Standard normal function.
vec3 nr(in vec3 p) {
    const vec2 e = vec2(0.001, 0);
    return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),    m(p + e.yyx) - m(p - e.yyx)));
}
*/

// Normal calculation, with some edging and curvature bundled in.
vec3 nr(vec3 p, inout float edge, inout float crv, float t) { 
    
    // It's worth looking into using a fixed epsilon versus using an epsilon value that
    // varies with resolution. Each affects the look in different ways. Here, I'm using
    // a mixture. I want the lines to be thicker at larger resolutions, but not too thick.
    // As for accounting for PPI; There's not a lot I can do about that.
    vec2 e = vec2(3./mix(450., min(850., resolution.y), .35), 0);//*(1. + t*t*.7);

    float d1 = m(p + e.xyy), d2 = m(p - e.xyy);
    float d3 = m(p + e.yxy), d4 = m(p - e.yxy);
    float d5 = m(p + e.yyx), d6 = m(p - e.yyx);
    float d = m(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
/*    
    // Wider sample spread for the curvature.
    e = vec2(12./450., 0);
    d1 = m(p + e.xyy), d2 = m(p - e.xyy);
    d3 = m(p + e.yxy), d4 = m(p - e.yxy);
    d5 = m(p + e.yyx), d6 = m(p - e.yyx);
    crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);
*/
    
    e = vec2(.001, 0); //resolution.y - Depending how you want different resolutions to look.
    d1 = m(p + e.xyy), d2 = m(p - e.xyy);
    d3 = m(p + e.yxy), d4 = m(p - e.yxy);
    d5 = m(p + e.yyx), d6 = m(p - e.yyx);
    
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// More concise, self contained version of IQ's original 3D noise function.
float noise3D(in vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
    const vec3 s = vec3(113, 157, 1);
    
    vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
    p -= ip; // Cell's fractional component.
    
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    float n = mix(h.x, h.y, p.z); // Range: [0, 1].
    
    return n; //abs(n - .5)*2.;
}

void main(void) { //WARNING - variables void (out vec4 c, in vec2 u){ need changing to glFragColor and gl_FragCoord
    vec2 u = gl_FragCoord.xy;
    vec4 c = glFragColor;

    // Camera and ray setup -- Note the one-line unit direction ray setup. Coyote
    // noticed that. The front light is there too.
    vec3 r = normalize(vec3(u - resolution.xy*.5, resolution.y)), 
         o = vec3( time*.5, time*.5/12.*1., 0), l = o + vec3(.5, 2., 0);
    
    // Tilt the scene along the YZ plane, ever so slightly.
    r.yz *= r2(3.14159/24.);

    // Ray marching... I should probalby put all this in its own function.
    float d, t = 0.;
    
    // Glow. A point light is place behind the scene, it's attenuation is
    // calculated at each point along the ray and accumulated. Pretty standard
    // stuff. Although, most people just accumulate ray distance or scene distance
    // values, whereas I prefer to accumulate the ray to light distance, just
    // because I think it looks a little nicer. In this case, I'm also taking
    // the more expensive step of smooth 3D noise attenuation to give the scene
    // a fog-like variance.
    float glow = 0.;
    
    // The second light offset. It's arranged to sit a few units back behind
    // the scene.
    vec3 l2Offs = vec3(.5, 1.5, 8);
    // Counter rotating the second light direction to match the scene rotation.
    l2Offs.yz *= r2(-3.14159/24.);
    // The second light.
    vec3 l2 = o + l2Offs;
    
    // Jittering the glow. If your glow is looking too bandy, try this.
    // It doesn't always work, but tends to help in many instances.
    t = hash31(r + fract(time));
    
    for(int i=0; i<80;i++){
        
        vec3 pp = o + r*t;
        d = m(pp);
        
        float aD = abs(d);
        
        // Ray position to point light distance.
        // Point-light-based glow.
        float l2D = length(l2 - pp);
        // Distance based falloff.
        //if(aD<.15) glow += 1.*(.15 - aD)/(.0001 + l2D*l2D);
        // Accumulating the attenuation, whilst applying a little noise.
        // There's a touch of animation as well to give the glow less of
        // a static feel.
        glow += .15/(.0001 + l2D)*noise3D(pp*6. + vec3(time, 0, time*.5));
        
        // The usual break conditions.
        if(abs(d)<0.001 || t>FAR) break;
        t += d;
    }
    
    t = min(t, FAR);

    // Saving the object ID. Not used here.
    //vec2 svObjID = objID;
    
    // Outer or inner box identification.
    float svOID = oID.x < oID.y ? 0. : 1.;
    
    // Scene color initiation.s
    vec3 col = vec3(0);
    
    if(t<FAR){
    
        // Hit point.
        vec3 p = o + r*t;
        //vec3 n = nr(p);
        // Normal, plus edges and curvature. The latter isn't used.
        float edge = 0., crv = 1.;
        vec3 n = nr(p, edge, crv, t);
        
        // Texture scale.
        const float sz0 = 1./1.;
        // No bump mapping -- I didn't think it added value to the scene.
        //n = texBump(iChannel0, p*sz0, n, .005);///(1. + t/FAR)
        
        float sh = shd(p, n, l);
        float ao = cao(p, n);
        sh = min(sh + ao*.2, 1.);
        
        

        l -= p; // Light to surface vector. Ie: Light direction vector.
        d = max(length(l), 0.001); // Light to surface distance.
        l /= d; // Normalizing the light direction vector.
        
        /////
        // The second light behind the scene.
        l2 -= p; // Light to surface vector. Ie: Light direction vector.
        float d2 = max(length(l2), 0.001); // Light to surface distance.
        l2 /= d2; // Normalizing the light direction vector.
        float diff2 = max(dot(l2, n), 0.);
        diff2 = pow(diff2, 4.)*2.;
        float spec2 = pow(max(dot(reflect(l2, n), r), 0.), 32.);
        /////
        
        // Object color. I applied some sporadic blue pathches, for whateverr eason. 
        // I thought the object facades looked a little too grey without it.
        float pat = dot(sin(p*6. + cos(p.yzx*6.)), vec3(.166)) + .5;
        pat = smoothstep(0., .25, pat - .65);
        vec3 oCol = mix(vec3(1), vec3(2, 3, 8), pat);
        
        // Adding a bit of grunge. I thought a grungy facade suited the scene a little
        // better... Plus, it's a good way to hide poor coding inconsitancies. :)
       
        // Some subtle noise. Less grungy, so looks a bit cleaner.
        vec3 tx = mix(vec3(.28), vec3(.18), noise3D(p*64.)*.66 + noise3D(p*128.)*.34);
        if(svOID < .5) tx *= 1.15;
        
        #ifndef NO_GLOw
        if(svOID > .5) oCol *= tx*tx*1.5;
        else oCol *= tx*sqrt(tx)*4.; // Brighten up the outer frames.
        #else 
        if(svOID > .5) oCol *= tx;
        else oCol *= sqrt(tx)*1.5; // Brighten up the outer frames.
        #endif
        
        

        
        float diff = max(dot(l, n), 0.); // Diffuse. 
        diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
        float spec = pow(max(dot(reflect(l, n), r), 0.), 32.); // Specular.
        
        // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a sandstone consistency... It "kind of" works.
        float Schlick = pow(1. - max(dot(r, normalize(r + l)), 0.), 5.);
        float fre2 = mix(.5, 1., Schlick);        
        
        // Scene color for light one.
        col = (oCol*(diff + .25) + vec3(.5, .7, 1)*spec*fre2*2.)*1./(1. + d*.25);
        
        // Scene color for light two. The effects are a little hidden by the overwhelming
        // glow, but the specular highlights accentuate the backlit effect. Uncomment it to
        // see what I mean.
        vec3 sCol = pow(vec3(1, 1, 1)*spec2, vec3(1, 2, 4)*2.);
        col += (oCol*(diff2 + .0) + sCol*4.)*1./(1. + d2*.25);
        
        
        // Applying the edges.
        col *= 1. - edge*.8;
        
        // Applying the ambient occlusion and shadows.
        col *= ao*sh;
        
        
    }
    
    
    #ifndef NO_GLOw    
    // Applying a fiery palatte to the glow
    vec3 glowCol = pow(vec3(1.5, 1, 1)*glow, vec3(1, 2.75, 8));
    // Adding the glow to the scene. Not that it's applied outsite the the object coloring
    // block because we need to add the glow to the empty spaces as well. When I haven't applied
    // glow for a while, I tend to forget this. :)
    col += glowCol*1.5 + glowCol*glowCol*1.5;
    
    // The fiery red is a little overwhelming, so this tones it down a bit.
    col = mix(col, col.zyx, max(-r.y*.25 + .1, 0.));
    #endif
   
    // Subtle vignette.
    u /= resolution.xy;
    col *= pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .0625);
    // Colored variation.
    //col = mix(col.zyx/2., col, pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .125));

    
    // Rough gamma correction: The top 5 things graphics programmers forget to do. You will be 
    // shocked when you see item number 3. :D
    //
    // For anyone doubting the need to gamma correct, create a red to green linear gradient 
    // across the screen horizontal, gamma correct the top half only, then compare.
    c = vec4(sqrt(max(col, 0.)), 1.);
    
    glFragColor = c;    
}
