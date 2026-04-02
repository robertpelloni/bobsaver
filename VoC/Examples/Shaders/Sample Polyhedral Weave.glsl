#version 420

// original https://www.shadertoy.com/view/MttczH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Polyhedral Weave
    ----------------
    
    Every now and again, someone will release a really cool -- not to mention, helpful -- 
    example with little fanfare. One such example is DjinnKahn's "Icosahedron Weave"
    shader.
    
    Producing icosahedral geometry using a brute force vertice and triangle list is
    pretty straight forward. Folding space isn't really my thing, but that's not too
    taxing either. However, I remember trying to weave something using a folding space
    method a while back and getting nowhere, and that was because when folding space
    with the standard algorithm you lose polarity. This became obvious to me... once 
    someone with more brain power put up a polyhedral weave example. :D

    Like I said, I hope I did some justice to the original. Code-wise, I didn't feel it 
    necessary to make many structural changes. DjinnKahn took a nice methodical approach, 
    whereas I made everything up as I went along -- just for something different. :)
    However, I did try to make up for it by explaining a thing or two, so hopefully
    that'll help.

    I also wanted to produce a different capsule line look, which necessitated an
    orthonormal approach. It's probably more expensive, but my fast machine didn't
    seem to notice. Having said that, I'll get in and try to speed things up later.

    Ultimately, I'd like to post some more sophisticated examples, but figured I'd
    better get a polyhedral weave on the board first.

    By the way, the "opIcosahedronWithPolarity" gives you triangle face information that
    is further subdivided into three sections, each with its own X-axis... 60 times 
    icosahedral symmetry, I think. Anyway, uncomment the "SHOW_EDGES" directive, and 
    hopefully, it'll become more clear.
    

    
    // Based on:
    
    // Not the easiest of geometry to wrap one's head around at the best of times, and 
    // from what I understand, DjinKahn (Tom Sirgedas) was learning about shaders and 
    // SDF at the same time. Quite amazing.
    Icosahedron Weave - DjinnKahn
    https://www.shadertoy.com/view/Xty3Dy

    Other examples:

    // Knighty is more comfortable folding space than most. I fold space about 
    // as well as I fold laundry. :)
    Polyhedron again - knighty
    https://www.shadertoy.com/view/XlX3zB

    // Tdhooper has some awesome icosahedral examples.
    Icosahedron twist - tdhooper
    https://www.shadertoy.com/view/Mtc3RX

*/

#define FAR 20.

// Visual guides to show the 3D weave pattern on the individual triangular faces.
//#define SHOW_EDGES
//#define SHOW_VERTICES

// This line emulates no polarity across the triangle face X axis... X axes, but let's
// not confuse ourselves. :) The pattern is still interesting, but there's no weave.
//#define NO_POLARITY

// 2D rotation formula.
mat2 rot2(float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// I paid hommage to the original and kept the same rotation... OK, I'm lazy. :D
vec3 rotObj(vec3 p){
    
    p.yz *= rot2(time*.2);
    p.zx *= rot2(time*.5);
    return p;    
}

// There's a neat way to construct an icosohedron using three mutually perpendicular rectangular 
// planes. If you reference something along the lines of icosahedron golden rectangle, you'll 
// get a pretty good idea. There's a standard image here:
// https://math.stackexchange.com/questions/2538184/proof-of-golden-rectangle-inside-an-icosahedron
//
// Anyway, even a cursory glance will give you a fair idea where the figures below originate. In 
// a vertex\indice list environment, you could produce an icosahedron without too much trouble at 
// all. However, in a realtime raymarching situation, you need to get to the triangle face 
// information in as few operations as possible. That's achieved via a bit of space folding using 
// the same information in a different way.
//
// If weaving wasn't necessary, you could use the concise "opIcosahedron" function and be done
// with it. Unfortunately, the "abs" calls throw out the triangular polarity information, which
// you need to distinguish one side of the triangle from the other -- I wasted a lot of time not
// realizing this until Djinn Kahn posted his example. He rewrote the folding function with an
// additional variable to track polarity (signs) during each iteration.
//
// With this function, you can obtain the triangle face information, and distinguish between
// the left and right X axis. From there, you can do whatever you wish. 

// Vertices: vec3(0, A, B), vec3(B, 0, A), vec3(-B, 0, A).
// Face center: (vec3(0, A, B) + vec3(0, 0, A)*2.)/3..
// Edges: (vec3(0, A, B) + vec3(B, 0, A))/2.,  etc.

// The following have come from DjinnKahn's "Icosahedron Weave" example, here:
// https://www.shadertoy.com/view/Xty3Dy
//
// It works fine, just the way it is, so I only made trivial changes. I'd like to cut down the
// number of operations in the "opIcosahedronWithPolarity" function, but so far, I can't see
// a way to do that.

const float PHI = (1. + sqrt(5.))/2.;
const float A = PHI/sqrt(1. + PHI*PHI);
const float B = 1./sqrt( 1. + PHI*PHI);
const float J = (PHI - 1.)/2.; // .309016994375;
const float K = PHI/2.;        //J + .5;
const mat3 R0 = mat3(.5,  -K,   J   ,K ,  J, -.5   ,J , .5,  K);
const mat3 R1 = mat3( K,   J, -.5   ,J , .5,   K   ,.5 ,-K,  J);
const mat3 R2 = mat3(-J, -.5,   K  ,.5 , -K,  -J   ,K ,  J, .5);

// I wanted all vertices hardcoded. The size factor effectively increases the size
// of the weave object.
#define size 1.25
const vec3 v0 = vec3(0, A, B)*size;
const vec3 v1 = vec3(B, 0, A)*size;
const vec3 v2 = vec3(-B, 0, A)*size;
const vec3 cent = (v0 + v1 + v2)/3.;

// Same as opIcosahedron, except without mirroring symmetry, so X-coordinate may be negative.
// (note: when this is used as a distance function, it's possible that the nearest object is
// on the opposite polarity, potentially causing a glitch).
vec3 opIcosahedronWithPolarity(in vec3 p){
   
    vec3 pol = sign(p);
    p = R0*abs(p);
    pol *= sign(p);
    p = R1*abs(p);
    pol *= sign(p);
    p = R2*abs(p);
    pol *= sign(p);
    vec3 ret = abs(p);
    return ret * vec3(pol.x*pol.y*pol.z, 1, 1);
}   

/*
// The original function -- sans polarity information -- is neat and concise.
vec3 opIcosahedron(vec3 p){ 
  
    p = R0*abs(p);
    p = R1*abs(p);
    p = R2*abs(p);
    return abs(p);  
} 
*/

// A cheap orthonormal basis vector function - Taken from Nimitz's "Cheap Orthonormal Basis" example, then 
// modified slightly.
//
//Cheap orthonormal basis by nimitz
//http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
//via: http://psgraphics.blogspot.pt/2014/11/making-orthonormal-basis-from-unit.html
mat3 basis(in vec3 n){
    
    float a = 1./(1. + n.z);
    float b = -n.x*n.y*a;
    return mat3(1. - n.x*n.x*a, b, n.x, b, 1. - n.y*n.y*a, n.y, -n.x, -n.y, n.z);
                
}
 
// A line segment formula that orients via an orthanormal basis. It'd be faster to use
// IQ's 3D line segment formula, but this one allows for more interesting cross sections,
// like hexagons and so forth.
float sdCapsule( vec3 p, vec3 a, vec3 b, float r, float lf){ // Length factor on the end.

    b -= a;
    float l = length(b);
    
    p = basis(normalize(b))*(p - a - b*.5);
    
    p = abs(p);
    //p.x = abs(p.x - .035);
    //return = max(length(p.xy) - r, p.z - l*lf);
    //return max((p.x + p.y)*.7071 - r, p.z - l*lf);
    //return max(max(p.x, p.y) - r, p.z - l*lf);
    //return max(max(max(p.x, p.y), (p.y + p.x)*.7071) - r, p.z - l*lf);
    return max(max(p.x*.866025 + p.y*.5, p.y) - r, p.z - l*lf);
}

/*
// IQ's 3D line segment formula. Simpler and cheaper, but doesn't orient carved cross-sections.
float sdCapsule(vec3 p, vec3 a, vec3 b){

    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    pa = abs(pa - ba*h);
    return length( pa );
}
*/
    
vec4 objID;

float dist(vec3 p, float r){
    
    return length(p) - r;
    //p = abs(p);
    //return max(length(p.yz) - r, p.x - r);
    //return max(max(p.x, p.y), p.z) - r;
    
}

float map(in vec3 p){
   
    
    // Back plane. Six units behind the center of the weaved object.
    float pln = -p.z + 6.;
    
    
    // Rotate the object.
    p = rotObj(p);
    
    // DjinnKahn's icosahedral distance function that produces a triangular face
    // and allows you to determine between the negative and positive X axis.
    //
    // Weaves are simple: Connect lines from one edge to another and arrange for
    // them to cross over one another inbetween. For instance, lines from the left
    // should meet at a join that sits lower than the join connecting lines from
    // the other direction... With that stand icosaheron function, you can't 
    // determine which side of the face you're one, so it's not possible. 
    // Thankfully, the following contains positive and negative X values.
    p = opIcosahedronWithPolarity(p);
    
    
    #ifdef NO_POLARITY
    // This line emulates no polarity across the triangle face X axis. The pattern is 
    // still interesting, but the weave is gone. Not accounting for X polarity was the 
    // reason my original weaving attempts using a space folding formula didn't work --
    // It's a bit hard to use negative values when there aren't any... Thankfully, 
    // DjinnKahn was learned up much more gooderer than me. :D
    p.x = abs(p.x);
    #endif

 
    // Some constant variables.  
    const vec3 flip = vec3(-1, 1, 1); // Quick way to swap from one side to the other.
    const float lw = .02; // Capsule line thickness.
    float lf = .45; // Capsule line length factor.
    
    // Height difference factor. The Z coordinate pushes things in or out. To create 
    // the weave, the mid point of the lines from one direction has to be higher or 
    // lower than those coming from the other. A lower number gives a tigher -- and
    // probably nicer looking -- weave, but I wanted the object to look like it was
    // hacked together... Kind of like this code. :D
    const vec3 hd = vec3(0, 0, .08); 
    
    
    // Three distance field values. They're distinguishable for object identification
    // purposes.
    float d = 1e5, d2 = 1e5, d3 = 1e5;
    
    
    #ifdef SHOW_EDGES
    // Note the "abs(p)." That's just a quick way to make the coordinates non-polar, which
    // allow you to render just one point, side, etc, and have all three show up. Space
    // folding can do your head in sometimes. :)
    //
    // Showing the icosahedral frame -- for those like myself who require a visual understanding 
    // of what's happening... or for those who enjoy spoiling the illusion for themselves. :)
    d = min(d, sdCapsule(abs(p), v0, v1, .0125, .5)); // Edges.
    #endif
    
    #ifdef SHOW_VERTICES
    d2 = min(d2, length(v0 - p) - .04); // Vertices.
    #endif
    //d2 = min(d2, length(cent - p) - .05); // Central face markers.
    
   
    
    // The weave pattern: The best way to see how this works is to uncomment the 
    // "SHOW_EDGES" and "SHOW_VERTICES" directives at the top of the page.
    // In essence, we're using the prefolded coordinate symmetry and X polarity 
    // to render three woven crosses. By the way, the easiest what to see what 
    // something does is to comment it out.
    
    // A point 25% of the way from v0 along the v0-v1 edge. This is a standard
    // way to obtain a linear position between two points.
    vec3 a = mix(v0, v1, .25);
    // Half way between the middle of edge v0-v2 and the triangular face center.
    vec3 b = (mix(mix(v0, v2, .5), cent, .5));
    vec3 mid = (mix(a, b, .5)); // Half way between points "a" and "b".
    
    // Render the first cross. Note that the mid point dips at the midpoint on one
    // stoke and raises on the other.
    d = min(d, sdCapsule(p, a, mid - hd, lw, lf));
    d = min(d, sdCapsule(p, mid - hd, b, lw, lf));
    d = min(d, sdCapsule(p, flip*a, mid + hd, lw, lf));
    d = min(d, sdCapsule(p, mid + hd, flip*b, lw, lf));

    // There are two rails in all. This is another rendered next to the first.
    // The result is double rails.
    vec3 a2 = (mix(v0, v1, .2));
    vec3 b2 = (mix(mix(v0, v2, .5), cent, .3));
    vec3 mid2 = (mix(a2, b2, .35));
    
    d = min(d, sdCapsule(p, a2, mid2 - hd, lw, lf));
    d = min(d, sdCapsule(p, mid2 - hd, b2, lw, lf));
    d = min(d, sdCapsule(p, flip*a2, mid2 + hd, lw, lf));
    d = min(d, sdCapsule(p, mid2 + hd, flip*b2, lw, lf)); 
    
    const float lw2 = .035; // Thicker joiner capsule lines.
    lf = 1.1; // Longer joiner capsule lines.
    
    // The gold joiner capsules connecting one rail to the other.
    d2 = min(d2, sdCapsule(abs(p), a, a2, lw2, lf));
    d2 = min(d2, sdCapsule(abs(p), flip*b, flip*b2, lw2, lf));
    
    
    // The ball bearing joiners at the mid points.
    const float jw = .02;
    d3 = min(d3, dist(mid - hd - p, jw));
    d3 = min(d3, dist(mid2 - hd - p, jw));    
    d3 = min(d3, dist(mid + hd - p, jw));    
    d3 = min(d3, dist(mid2 + hd - p, jw));  

    
    // Store the individual object values for sorting later. Sorting multiple objects
    // inside a raymarching loop probably isn't the best idea. :)
    objID = vec4(d, d2, d3, pln);
    
    return min(min(d, d2), min(d3, pln));
}

/*
// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ. In instances where there's no descernible 
// aesthetic difference between it and the six tap version, it's worth using.
vec3 calcNormal(in vec3 p){

    // Note the slightly increased sampling distance, to alleviate artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.0025, -0.0025); 
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}
*/

// Standard normal function. 6 taps.
vec3 calcNormal(in vec3 p) {
    const vec2 e = vec2(0.002, 0);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),    map(p + e.yyx) - map(p - e.yyx)));
}

// Normal calculation, with some edging and curvature bundled in.
vec3 calcNormal(vec3 p, inout float edge, inout float crv, float t) { 
    
    // It's worth looking into using a fixed epsilon versus using an epsilon value that
    // varies with resolution. Each affects the look in different ways. Here, I'm using
    // a mixture. I want the lines to be thicker at larger resolutions, but not too thick.
    // As for accounting for PPI; There's not a lot I can do about that.
    vec2 e = vec2(2./mix(400., resolution.y, .5), 0);

    float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    float d = map(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
/*    
    // Wider sample spread for the curvature.
    e = vec2(12./450., 0);
    d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);
*/
    
    e = vec2(.001, 0); //resolution.y - Depending how you want different resolutions to look.
    d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// Raymarching: The distance function is a little on the intensive side, so I'm 
// using as fewer iterations as necessary. Even though there's a breat, the compiler
// still has to unroll everything, and larger numbers make a difference.
float trace(in vec3 ro, in vec3 rd){
    
    float t = 0., d;
    
    for(int i = 0; i<64; i++){
    
        d = map(ro + rd*t);
        if(abs(d) < .001*(1. + t*.05) || t > FAR) break;
        t += d;
    }
    
    return min(t, FAR);
}

float hash( float n ){ return fract(cos(n)*45758.5453); }

// Ambient occlusion, for that self shadowed look. Based on the original by XT95. I love this 
// function and have been looking for an excuse to use it. For a better version, and usage, 
// refer to XT95's examples below:
//
// Hemispherical SDF AO - https://www.shadertoy.com/view/4sdGWN
// Alien Cocoons - https://www.shadertoy.com/view/MsdGz2
float calculateAO( in vec3 p, in vec3 n, float maxDist )
{
    float ao = 0.0, l;
    const float nbIte = 6.0;
    //const float falloff = 0.9;
    for( float i=1.; i< nbIte + .5; i++ ){
    
        l = (i + hash(i))*.5/nbIte*maxDist;
        ao += (l - map( p + n*l ))/(1.+ l);// / pow(1.+l, falloff);
    }
    
    return clamp( 1.-ao/nbIte, 0., 1.);
}

// The iterations should be higher for proper accuracy.
float softShadow(in vec3 ro, in vec3 rd, float t, in float end, in float k){

    float shade = 1.0;
    // Increase this and the shadows will be more accurate, but more iterations slow things down.
    const int maxIterationsShad = 24; 

    // The "start" value, or minimum, should be set to something more than the stop-threshold, so as to avoid a collision with 
    // the surface the ray is setting out from. It doesn't matter how many times I write shadow code, I always seem to forget this.
    // If adding shadows seems to make everything look dark, that tends to be the problem.
    float dist = .001*(1. + t*.1);
    float stepDist = end/float(maxIterationsShad);

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){
        // End, or maximum, should be set to the distance from the light to surface point. If you go beyond that
        // you may hit a surface not between the surface and the light.
        float h = map(ro + rd*dist);
        shade = min(shade, k*h/dist);
        //shade = min(shade, smoothstep(0.0, 1.0, k*h/dist));
        
        // What h combination you add to the distance depends on speed, accuracy, etc. To be honest, I find it impossible to find 
        // the perfect balance. Faster GPUs give you more options, because more shadow iterations always produce better results.
        // Anyway, here's some posibilities. Which one you use, depends on the situation:
        // +=max(h, 0.001), +=clamp( h, 0.01, 0.25 ), +=min( h, 0.1 ), +=stepDist, +=min(h, stepDist*2.), etc.
        
        dist += clamp(h, 0.01, 0.25);
        
        // There's some accuracy loss involved, but early exits from accumulative distance function can help.
        if (abs(h)<0.0001 || dist > end) break; 
    }

    // I usually add a bit to the final shade value, which lightens the shadow a bit. It's a preference thing. Really dark shadows 
    // look too brutal to me.
    return min(max(shade, 0.) + 0.1, 1.0); 
}

void main(void)
{
    // Aspect correct screen coordinates.
    vec2 p = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    // Unit direction ray.
    vec3 rd = normalize(vec3(p, 1.));
    
    // Ray origin, doubling as the camera postion.
    vec3 ro = vec3(0.0, 0.0, -3.);
    
    // Light position. Near the camera.
    vec3 lp = ro + vec3(0.25, 2, 0);
    
    // Ray march.
    float t = trace(ro, rd);
    
    // Object identification: Back plane: 3, Golden joins: 2., 
    // Ball joins: 1., Silver pipes:  0.
    float svObjID = objID.x<objID.y && objID.x<objID.z && objID.x<objID.w? 0.: 
    objID.y<objID.z && objID.y<objID.w ? 1. : objID.z<objID.w? 2. : 3.;

    
    // Initiate the scene color zero.
    vec3 col = vec3(0);
    
    // Surface hit. Color it up.
    if(t < FAR){
    
        // Position.
        vec3 pos = ro + rd*t;
        // Normal.
        //vec3 nor = calcNormal(pos);
        // Normal, plus edges and curvature. The latter isn't used.
        float edge = 0., crv = 1.;
        vec3 nor = calcNormal(pos, edge, crv, t);
        
        //vec3 rp = rotObj(pos);
        
        // Light direction vector.
        vec3 li = lp - pos;
        float lDist = max(length(li), .001);
        li /= lDist;
        
        // Light falloff - attenuation.
        float atten = 1.5/(1. + lDist*.05 + lDist*lDist*0.01);
        
        // Soft shadow and occlusion.
        float shd = softShadow(pos + nor*.0015, li, t, lDist, 8.); // Shadows.
        float ao = calculateAO(pos, nor, 4.);
        
        
        float diff = max(dot(li, nor), .0); // Diffuse.
        float spec = pow(max(dot(reflect(-li, nor), -rd), 0.), 16.); // Specular.
        // Ramping up the diffuse. Sometimes, it can make things look more metallic.
        diff = pow(diff, 4.)*2.; 
        
        
        float Schlick = pow( 1. - max(dot(rd, normalize(rd + li)), 0.), 5.0);
        float fre2 = mix(.5, 1., Schlick);  //F0 = .5.
        
        col = vec3(.6); // Silver pipes.
        
        if(svObjID == 1.) { // Golden joins
            col = vec3(1, .55, .2);
            col = mix(col, col.yxz, rd.y*.5);
        }
        //if(svObjID == 2.) col = vec3(1, .55, .2).zyx/1.5; // Ball joins.
        if(svObjID == 3.) { // Back plane.
            
            // Subtle blue gradient with fine lines.
            col = vec3(1, .55, .2).zyx/7.;
            col = mix(col, col.yxz, rd.y*.1 + .1);
            col *= clamp(sin((pos.x - pos.y)*resolution.y/8.)*2. + 1.5, 0., 1.)*.5 + .5;
        }
        
        // Diffuse plus ambient term.
        col *= diff + .25; 
        
        // Specular term.
        if(svObjID == 3.) col += vec3(1, .6, .2).zyx*spec*.25; // Less specular on the back plane.
        else col += vec3(.5, .75, 1.)*spec*2.;
        
        col *= 1. - edge*.7;
        //col = col*.7 + edge*.3;
        
        col *= atten*shd*ao; // Light falloff.
        
         
    }
    
    // Screen color. Rough gamma correction. No fog or postprocessing.
    glFragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.0);
}
