#version 420

// original https://www.shadertoy.com/view/WlBczG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Hyperbolic Poincare Tiling
    --------------------------

    This is a simpler hyperbolic polygonal tiling of the Poincare disc that
    I've put together to accompany the more involved example I posted earlier.

    In regard to the Poincare disc side of things, it was helpful to reference
    MLA, SL2C and STB's examples -- All authors have really nice work on here,
    which is well worth the look. STB provided me with the link that he used
    for his "Hyperbolic Poincaré transformed" example which enabled me to 
    streamline the setup code quite a bit. In fact, I'd imagine that once 
    someone like Fabrice Neyret gets a hold of it, you'll see a two tweet
    Poincare tiling. :)

    Anyway, the code is very basic, but I've put in a reasonably thorough
    explanation, along with some useful links, so hopefully that'll be enough
    to give people a start.

    By the way, the default setting is the standard triangle configuration
    you'll see around. However, I've colored the triangle segments to match
    ajoining ones, and put lines from the triangle center to the vertices to 
    produce the cube look. This is one of countless arrangements and patterns 
    that you may have seen around. I'm hoping others will put up a few more on 
    Shadertoy at some stage.

    Poincare disc examples:

    // The hyperbolic transformation itself is based on STB's example here,
    // which I'm assuming was in turn based on a slide presentation by
    // Vladimir Bulatov: http://www.bulatov.org/math/1001/index.html
    //
    Hyperbolic Poincaré transformed - stb
    https://www.shadertoy.com/view/3lscDf

    // Like everyone else, I love the following example. However, be warned that 
    // it involves complex geometry. :)  Seriously though, Mattz can come up with 
    // solutions to problems in a few minutes that have utterly confounded me for 
    // weeks.
    //
    Hyperbolic Wythoff explorer - mattz 
    https://www.shadertoy.com/view/wtj3Ry

    // The shader that this particular one accompanies.
    Hyperbolic Poincare Weave - Shane
    https://www.shadertoy.com/view/tljyRR

*/

// Here's a more Earth tone-looking palette for people who require something
// less cheery looking... OK, that would be me. :D
//#define EARTH_TONES

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// P represents the number of polygon vertices, and Q is the number of 
// adjacent polygons to each vertex within the Poincare disc.
//
// For tilings to work, the following must be true: (P − 2)*(Q − 2)>4.
//
// For instance, 3 and 7 will work, but 4 and 4 will not.
//
// 3-7, 3-8, 4-5 , 5-4, 6-4, 7-3.
//
const int N        = 3;    // Polygon vertices.
const int Q        = 8;    // Polygons meeting at a vertex.

#define PI        3.14159265
#define TAU        6.28318531

// Calculating the initial circular domain according to number of polygon
// sides (N) and the number of adjacent polygons (P): STB was clever enough to  
// use repeat polar space to position the rest. Anyway, the idea is to put two 
// points on the initial circle perimeter, z1 and z2, then use a mixture of 
// standard Euclidean and hyperbolic geometry to calculate the required values,
// which are described below.
// 
vec3 initDomain(){
    
    // There are quite a few ways to calculate the initial circular domain 
    // values, simply because there are several solutions to the same geometric 
    // problems, which is all this is. In fact, as geometric situations go,
    // this is not a particularly difficult one to solve.
    
    // Essentially, you're going to be reflecting points about polygonal edges, 
    // so you'll need the distance from your initial circle center to that of 
    // the center of the circle that runs adjacent to the current domain edges in
    // order to perform a hyperbolic reflection. You'll need the radius of that 
    // circle as well. The distance and radius will depend directly upon how
    // how many edges your polygon has and how many adjacent polygons (the
    // number that meet at a vertex point) there are.

    // The following is some highschool level circle and triangle geometry to 
    // get the values we're after. Of course, none of this will mean much without 
    // some imagery to refer to. Shadertoy user, SLB, provided me with a link
    // to a setup image that made life much easier. Without too much trouble
    // it's possible to use whatever trigonometric identities you want to 
    // arrive at the following. In fact, with more effort, I'm pretty sure it'd
    // be possible to do better. Here's the link.
    //
    // The Hyperbolic Chamber - Jos Leys
    // http://www.josleys.com/article_show.php?id=83
    //
    // I also find the imagery on the following page helpful as well:
    // http://www.malinc.se/noneuclidean/en/poincaretiling.php
   
    float a = sin(PI/float(N)), b = cos(PI/float(Q));
    float d2 = cos(PI/float(N) + PI/float(Q))/a;
    float r2 = 1./(b*b/a/a - 1.);
    // Distance between adjacent polygon centers, the adjacent polygon radius,
    // and the current polygon radius. We're assuming no negatives, but I'm 
    // capping things above zero, just in case.
    return sqrt(max(vec3(1. + r2, r2, d2*d2*r2), 0.));  
   

}

// Gloable polygon value. Not used here, but normally, it'd be the focus.
//float gPoly;

// Count variable, which is seful for all kinds of things. It's a measure
// of how many iterations were required to get to the current polygon.
// The center polygon would have a count of one, and should increase as we 
// radiate outwards.
float count;

// Hyperbolically reflecting the polygon across each of it's edges
// via an inverse Mobius transform.
vec2 transform(vec2 p, vec3 circ) {
    
    
    // The following is standard polar repeat operation. It works
    // the same in hyperbolic space as it does in Euclidian space.
    // If you didn't do this, you'd reflect across just the one
    // edge. Set "ia" to ".5/float(N)" to see what I mean.
     
    float ia = (floor(atan(p.x, p.y)/TAU*float(N)) + .5)/float(N);
    vec2 vert = rot2(ia*TAU)*vec2(0, circ.x);
   
    float rSq = circ.y*circ.y;
    
    // Circle inversion, which relates back to an inverse Mobius
    // transformation. There are a lot of topics on just this alone, but 
    // the bottom line is, if you perform this operation on a point within
    // the Poincare disk, it will be reflected. It's similar to the
    // "p /= dot(p, p)" move that some may have used before.
    vec2 pc = p - vert;
    float lSq = dot(pc, pc);
    
    // If the distance (we're squaring for speed) from the current point to
    // any vertex point is within the circle limits, hyperbolically reflect it.
    if(lSq<rSq){
         
        p = pc*rSq/lSq + vert;
        //p = rot2(TAU/float(N))*p; // Experimenting with rotation.
        
        // Maintaining chirality. I can thank MLA for this bit. If you 
        // don't do this, the coordinates will lose their polarity...
        // I originally didn't do this. :D
        //p.x = -p.x;
        
        // If we have a hit, increase the counter. This value can be useful
        // for coloring, and other things.
        count++;
         
    }
   
    /* 
    // If you're after a CSG polygon to work with, the following should work.
    // I've lazily set it to a global, but there'd be cleaner ways to work 
    // the calculations in.
    float poly = (length(p) - circ.z);
    poly = max(poly, -(length(pc) - circ.y));
    gPoly = min(gPoly, poly);
    */
    return p;
}

// Very handy. I should write my own, but this works. I
// rearranged it a bit, but it's the same function.
//
// Smooth Floor - Anastadunbar 
// https://www.shadertoy.com/view/lljSRV
float floorSm(float x, float c) {
    
    float ix = floor(x); x -= ix;
    return (pow(x, c) - pow(1.- x, c))/2. + ix;
}

// IQ's standard box function.
float sBox(in vec2 p, in vec2 b){
   
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// This will draw a box (no caps) of width "ew" from point "a "to "b". I hacked
// it together pretty quickly. It seems to work, but I'm pretty sure it could be
// improved on. In fact, if anyone would like to do that, I'd be grateful. :)
float lBox(vec2 p, vec2 a, vec2 b, float ew){
    
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));

    vec2 l = vec2(length(b - a), ew);
    return sBox(p, (l + ew)/2.) ;
}

// Mouse pointer inversion.
vec2 mouseInversion(vec2 p){
    
    // Mouse coordinates.
    vec2 m = vec2((2.*mouse*resolution.xy.xy - resolution.xy)/resolution.y);
    // Hack for the zero case instance. If someone has a better way,
    // feel free to let me know.
    if(length(m) < 1e-3) m += 1e-3; 
    // A hack to stop some craziness occurring on the border.
    if(abs(m.x)>.98*.7071 || abs(m.y)>.98*.7071) m *= .98;
    
    // Taking the mouse point and inverting it into the circle domain.
    // Feel free to check some figures, but all will get mapped to 
    // values that lie within circle radius.
    float k = 1./dot(m, m);
    vec2 invCtr = k*m; 
    float t = (k - 1.)/dot(p -invCtr, p - invCtr);
    p = t*p + (1. - t)*invCtr;
    p.x = -p.x; // Keep chirality. MLA does this. 
    
    return p;
    
}

void main(void) {
    
    
    // Aspect correct coordinates: Actually, gl_FragCoord.xy is already in 
    // aspect correct form, so shifting and scaling is all that is
    // required in this particular pixel shader environment.
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
  
    // Contracting things just a touch to fit the Poincare domain on 
    // the canvas.
    uv *= 1.05;
     
    // Hyperbolic the hyperbolic... I made that up, but it spherizes things 
    // a bit, which looks interesting.
    //uv *= (1. + dot(uv, uv))/2.;
   
    
    // Poincare coordinates.
    vec2 p = uv;
   

    // A bit of mouse inversion and rotation to begin with. You'll
    // see this a lot in various hyperbolic examples, and others.
    p = mouseInversion(p);
        
    // Perform some free rotation.
    p = rot2(time/16.)*p;
    
   
    // Inversion count. It's used for all kinds of things, like 
    // random number production, etc.
    count = 0.;
    
    // Globale polygon value. Not used here, but I'll use it when I make
    // an extruded raymarched version.
    //gPoly = 1e5;
    
    // Filling in the domain origin information: From left to right, it 
    // returns the distance between adjacent polygon centers, the adjacent 
    // polygon radius, and the current polygon radius. These values remain
    // the same for all polygons throughout the hyperbolic plane, so this 
    // is all that's required to tile the disc.
    vec3 domInfo = initDomain();    
    
    // Handling the imagery outside the Poincare circle domain by inverting or
    // mirroring it back into the circle so that it shows up... or something
    // to that effect... It's been a while. Either way, this is what you do
    // if you want to see the outside pattern. :)
    //
    // By the way, if you want to get more of an intuitive feel for circle 
    // inversion, I recommend Numberphile's "Epic Circles" video, here:
    // https://www.youtube.com/watch?v=sG_6nlMZ8f4
    if(length(p)> 1.) p /= dot(p, p); 
  
    
    // Performing multiple reflective inversions to fill out the disk. Due 
    // to the nature of the hyperbolic transform, the polygon tiles get 
    // smaller as you approach the outer disk, and never reach the edge. 
    // There are a bunch of proofs in complex analysis that illustrate
    // this, but nothing shows it as well as a computer program. :)
    // Drop the number of iterations and you'll see the process unfold.
    for(int i=0; i<24; i++){
        p = transform(p, domInfo);
    }
    
    
    // From here on in, it's just rendering code. None of it is difficult, or
    // particularly interesting. Once you have the local cell coordinates,
    // you can render whatever you want. In this case, I've produced some
    // colors according to whatever polygon segment where in, some dark 
    // center to polygon vertex point lines, and some shading lines with a
    // dark box -- The last two are based on the center to edge mid point 
    // lines. All very simple.
  
   
    // Vertex lines and edge mid point lines, and points.
    float ln = 1e5, ln2 = 1e5, pnt = 1e5;
    
    // Initial point set to the boundary of whatever circle we're in.
    vec2 v0 = vec2(0, domInfo.z), m0;
    
    // I'm being lazy and looping around the polygon vertices and mid
    // points to produce the line information. I could just as easily
    // do the repeat polar thing. I also believe it's easier to read for
    // those trying to decipher this.
    for(int i = 0; i<N; i++){

        // Mid edge points. Note that interpolating from one edge vertex
        // to the other won't give the correct results due to the
        // hyperbolic nature of the local space, so we're rotating between
        // vertex points and setting the distance do the correct distance
        // measured out in the initialization function.
        m0 = (rot2(PI/float(N))*v0)*(domInfo.x - domInfo.y)/domInfo.z;
         
        // Center to vertex distances. 
        ln = min(ln, lBox(p, vec2(0), v0, .007));
        // Center to edge mid point distances. 
        ln2 = min(ln2, lBox(p, vec2(0), m0, .007));
        
        // Vertex points.
        pnt = min(pnt, length(p - v0));
 
        // Rotating to the next vertex point.
        v0 = rot2(TAU/float(N))*v0;
    }
    
 
    // Setting a ring distance field, then using that to add more to the 
    // smoothing factor to alleviate aliasing around the borders. It's 
    // hacky, and no substitute for super sampling, but it works well 
    // enough here.
    float ssf = (2. - smoothstep(0., .25, abs(length(uv) - 1.) - .25));
    float sf = 2./resolution.y*ssf;//(count*count + 1.);//fwidth(shape);// 

 
    
    // Setting the color, according to the polygon segment angle. It works
    // well for this configuration, and others where the adjacent polyongs,
    // Q are even, but breaks with odd Q, in which case you have to render in
    // other lines.
    float angl = mod(atan(p.x, p.y), TAU)*float(N)/TAU;
    float triSeg = floorSm(angl, .15);  // Note the smooth floor function.
    triSeg = (triSeg + .5)/float(N);

    // IQ's versatile palette routine. It's one of my favorites.
    #ifdef EARTH_TONES
    vec3 oCol = .55 + .45*cos(triSeg*TAU/3.5 + vec3(0, 1, 2)/1.1);
    #else
    vec3 oCol = .55 + .45*cos(triSeg*TAU + vec3(0, 1, 2)).yxz;
    #endif
    
    // Line pattern.
    //float pat = clamp(sin(ln2*TAU*40.)*2. + 1., 0., 1.)*.4 + .8;
    float pat = smoothstep(0., .25, abs(fract(ln2*43. - .25) - .5)*2. -.25);
    
    // Some subtle polygon segment (cube face) shading.
    float sh = clamp(.65 + ln/domInfo.z*4., 0., 1.);
    
    // The background color. It looks interesting enough like this, but the lines
    // give it additional depth.
    vec3 col = min(oCol*(pat*.4 + .8)*sh, 1.);

    // Rendering the lines.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, ln));
    // The dark boxes on the inside of the ring only.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, -(ln - .085)));

    
    // Polygon vertex points and central point.
    pnt -= .032;
    pnt = min(pnt, length(p) - .032);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, pnt));
    col = mix(col, vec3(1, .8, .3), 1. - smoothstep(0., sf, pnt + .02));
    
    
    // A quick background image... Definitely needs more effort. :)
    
    #ifdef EARTH_TONES
    vec3 bg = vec3(.85, .4, .3);//.55 + .45*cos(TAU/6. + vec3(0, 1, 2)/1.2);
    #else
    vec3 bg = vec3(.4, .2, 1);
    #endif
    bg *= .3*(dot(col, vec3(.299, .587, .114))*.5 + .5);
    pat = smoothstep(0., .25, abs(fract((uv.x - uv.y)*43. - .25) - .5)*2. -.5);
    bg *= max(1. - length(uv)*.5, 0.)*(pat*.4 + .8);
   
    // Putting in the outer ring. I did this in a hurry, so you could do it in
    // fewer steps for sure. Think of it as a lesson on what not to do. :D
    float cir = length(uv);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*10., abs(cir - 1.) - .05))*.7);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., abs(cir - 1.) - .05)));
    col = mix(col, vec3(.9) + bg, (1. - smoothstep(0., sf, abs(cir - 1.) - .03)));
    col = mix(col, col*max(1. - length(uv)*.5, 0.), (1. - smoothstep(0., sf, -cir + 1.05)));
    col = mix(col, bg, (1. - smoothstep(0., sf, -cir + 1.05)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, abs(cir - 1.035) - .03))*.8);
  
    // Toning things down ever so slightly. "1. - exp(col*a)" is used as a toning
    // device... I'm toning things down a little bit. I prefer not to post process
    // too much, but sometimes, it can help tie things together when the
    // background tones don't match the foreground, and so forth. Sometimes, 
    // multiplying everything by a single subtle sepia color, or whatever can help
    // tie things together overall. Anyway, comment the line out, and you'll see
    // that it tones down the highlights just a little.    
    col = mix(col, 1. - exp(-col), .35);
    
    // Rough gamma correction, then present to the screen.
    glFragColor = vec4(sqrt(max(col, 0.)), 1.);
}
