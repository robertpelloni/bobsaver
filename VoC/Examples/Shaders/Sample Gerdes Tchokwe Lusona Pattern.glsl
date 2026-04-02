#version 420

// original https://www.shadertoy.com/view/WlfBzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Gerdes Tchokwe Sand Pattern
    ---------------------------

    This is a very basic African influenced Lusona pattern rendered in a 
    pseudo 3D isometric fashion in the style of oldschool scrollers.
    Fabrice Neyret often posts interesting snippets of code with visually
    satisfying results. In fact, some are a little too interesting, because 
    one minute I'll be working on something I'm supposed to be doing, then
    the next minute I'm coding up a basic Angolan Tchokwe Lusona pattern. :D

    This particular pattern represents a very small subsection of a larger 
    body of work by mathematician and author Paulus Gerdes. In case it needs 
    to be said, African inspired mathematics as it pertains to Sona sand 
    drawings is not my area of expertise. :)

    Algorithmically, the base pattern here is pretty simple to make: Create 
    a square or diamond grid, then randomly render crosses or opposite sided 
    arcs on each shared edge or vertex. From my perspective, the basic design 
    is just a standard two tiled Truchet pattern with some edge constraints. 
    In particular, you force any arc tile to have either a horizontal or 
    vertical orientation on an alternate checkered basis. Use the SHOW_GRID
    define to show the individual tiles that make up the pattern.

    Since Fabrice has already covered the algorithmic side of things, I 
    decided to focus on the rendering. I've mentioned before that I sometimes 
    enjoy producing pseudo 3D effects more than real ones, since faux 3D 
    effects often requires finesse and inventiveness. This is just simple 
    layering effects that most Photoshop artists take for granted -- Drop 
    shadows, bevels, highlights, etc. For the cross tiles (a line on top of 
    another line), I went to the trouble to render Bezier curves to put a 
    little kink at the cross-over points to enhance the illusion. It's a 
    subtle difference that added a chunk of code, but I think it makes all 
    the difference.

    As mentioned, this is the most basic of patterns. There are a wide range 
    of others out there. Fabrice has created a few extentions that are worth 
    looking at. In addition, a proper 3D version of this would be relatively 
    simple, as too would a Wang tile variation. I'm not positive, but I'm 
    pretty sure it'd be possible to create a multiscale version as well. With 
    restrictions on the line lengths, animation flow might be possible, but 
    I'll save variations for another time. :)

    Links:

    // Based on the imagery from the following.
    P.Gerdes & Tchokwe sand drawing - FabriceNeyret2
    https://www.shadertoy.com/view/wtsfWM

    // A nice variation.
    P.Gerdes & Tchokwe sand drawing5 - FabriceNeyret2
    https://www.shadertoy.com/view/3llfRS

    Inspiration from Angolan traditional designs - Paulus Gerdes
    https://plus.maths.org/content/new-designs-africa

    Lusona - Wikipedia
    https://en.wikipedia.org/wiki/Lusona

*/

// Display the individual cell tiles. Note that in this particular case,
// the entire coordinate system has been rotated by 45 degrees to look
// like a diamond grid, but this still a square grid.
//#define SHOW_GRID

// Makes for a neater pattern, but looks less convincing.
//#define STRAIGHT_LINES

// This takes out the edge constrainst, which results in a standard
// two-tiled random Truchet pattern.
//#define RANDOM_TRUCHET

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(57.609, 27.483)))*43758.5453); }

// IQ's signed distance to a quadratic Bezier. Like all of IQ's code, it's
// quick and reliable. :)
//
// Quadratic Bezier - 2D Distance - IQ
// https://www.shadertoy.com/view/MlKcDD
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C){
  
    // p(t)    = (1 - t)^2*p0 + 2(1 - t)t*p1 + t^2*p2
    // p'(t)   = 2*t*(p0 - 2*p1 + p2) + 2*(p1 - p0)
    // p'(0)   = 2*(p1 - p0)
    // p'(1)   = 2*(p2 - p1)
    // p'(1/2) = 2*(p2 - p0)
    
    vec2 a = B - A;
    vec2 b = A - 2.*B + C;
    vec2 c = a * 2.;
    vec2 d = A - pos;

    // If I were to make one change to IQ's function, it'd be to cap off the value 
    // below, since I've noticed that the function will fail with straight lines.
    float kk = 1./max(dot(b, b), 1e-6); // 1./dot(b,b);
    float kx = kk * dot(a, b);
    float ky = kk * (2.*dot(a, a) + dot(d, b))/3.;
    float kz = kk * dot(d, a);      

    float res = 0.0;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.*kx*kx - 3.*ky) + kz;
    float h = q*q + 4.*p3;

    if(h >= 0.) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q)/2.;
        vec2 uv = sign(x)*pow(abs(x), vec2(1./3.));
        float t = uv.x + uv.y - kx;
        t = clamp(t, 0., 1.);

        // 1 root.
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos(q/(p*z*2.))/3.;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m)*z - kx;
        t = clamp(t, 0., 1.);

        // 3 roots.
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos, qos);
        
        res = dis;

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos, qos);
        res = min(res, dis);

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos, qos);
        res = min(res, dis);

        res = sqrt(res);
    }
    
    return res;
}

// This is a standard distance field setup for one, two or more
// Truchet tiles with some minor additions. The tiles used are
// overlapping crossed lines and the common double arc tile.
//
// There are two distance field value holders for line one or
// line two in order to render one over the other, and two for
// each arc, even though one would suffice, since there's no 
// overlap. The only other difference is that we're constructing
// Bezier lines for the wavy line kinks instead of standard 
// straight ones.
//
// There is also a place holder for the central dots that you can
// see and a final position to identify whether we've returned
// a cross tile or a double arced one.
//
vec4 distField(vec2 p){

    
    // Offset field position for the central dots. See below.
    vec2 q = p - .5;
    
   
    // Standard square grid ID and local position.
    vec2 ip = floor(p) + .5;
    p -= ip;
    
    // Vertice and edge postions... Probably overkill for such a simple example,
    // but it's a good habit to get into when dealing with more complex setups.
    const vec2[4] v = vec2[4](vec2(-.5, .5), vec2(.5),  vec2(.5, -.5),  vec2(-.5));
    const vec2[4] e = vec2[4](vec2(0, .5), vec2(.5, 0),  vec2(0, -.5),  vec2(-.5, 0));
    
    
    
    // Distance field place holder.
    vec4 d = vec4(1e5);
  
    // Edge width.
    float ew = .12;
    
   
    // Using the cell ID for some unique random numbers.
    float rnd = hash21(ip);
    float rnd2 = hash21(ip + .37);
    #ifdef RANDOM_TRUCHET
    float rnd3 = hash21(ip + .73);
    #endif
    
    // Checkered arrangement: The black and white chessboard arrangement comes up
    // in so many different situations that it's worth committing to memory. In this
    // case we are aligning all double arc tiles either horizontally or vertically,
    // depending upon which checker we're on.
    float check = mod(ip.x + ip.y, 2.);
    
    
    // Render overlapping lined crosses on half the tiles. You could change the
    // percentage, if you wanted.
    if(rnd<.5){
        
        // X and Y nudge factors to produce the Bezier kinks.
        #ifdef STRAIGHT_LINES
        // No kind for the straight lines.
        const vec2 ndgX = vec2(0);
        vec2 ndgY = vec2(0);
        #else
        // Kink the horizontal lines up and the vertical lines
        // to the left. If the tiles get rotated, they will switch
        // to down and right, which makes sense.
        const vec2 ndgX = vec2(-.075, 0);
        vec2 ndgY = vec2(0, .075);
        #endif
        
        // Randomly rotate some of the tiles: This has the effect of putting
        // the top line on the bottom. The nudge factor has to be reversed
        // to keep the line kinks pointing in the right direction.
        if(rnd2<.5) {
            p = rot2(3.14159/2.)*p;
            ndgY *= -1.;
        }  
        
         
        // Rendering the Bezier lines, which aren't much different to normal lines, except there's
        // an additional anchor point to give it a curved appearance. IQ wrote the Bezier algorithm
        // itself, which wouldn't have been easy.
        //
        // Bottome line.... All of these join together at their end points.
        d.x = min(d.x, sdBezier(p, e[2]*1., e[2] + vec2(0, .1), e[2] + vec2(0, .25) + ndgX/3.) - ew);
        d.x = min(d.x, sdBezier(p, e[0] - vec2(0, .25) + ndgX/3., e[0] - vec2(0, .1), e[0]*1.) - ew);
        d.x = min(d.x, sdBezier(p, e[0] - vec2(0, .25) + ndgX/3., ndgY, e[2] + vec2(0, .25) + ndgX/3.) - ew);
        
        // Top line.
        d.y = min(d.y, sdBezier(p, e[3]*1., e[3] + vec2(.1, 0), e[3] + vec2(.25, 0) + ndgY/3.) - ew);
        d.y = min(d.y, sdBezier(p, e[1] - vec2(.25, 0) + ndgY/3., e[1] - vec2(.1, 0), e[1]*1.) - ew);
        d.y = min(d.y, sdBezier(p, e[1] - vec2(.25, 0) + ndgY/3., ndgY, e[3] + vec2(.25, 0) + ndgY/3.) - ew);
        
        // Tile ID: Zero for a cross.
        d.w = 0.;
    }
    else {
        
        // The line here is the only difference between Paulus Gerdes's Tchokew inspired sand pattern
        // arrangement and a regular double tiled Truchet pattern... If you look at the comments on
        // Fabrice Neyret's original Shadertoy pattern you'll see that I'm kind of convinced of that,
        // but I'm not positive... Either way, it's a pretty pattern, so whatever. :D
        //
        // As you can see, I've provided an option to randomly rotate tiles as well, which will 
        // produce the common double tiled pattern that you've probably seen all over the place.
        //
        #ifdef RANDOM_TRUCHET
        if(rnd3<.5) p = rot2(3.14159/2.)*p; // Random rotation.
        #else
        if(check<.5) p = rot2(3.14159/2.)*p; // Checker pattern constained rotation.
        #endif 
        
        // The two quarter arcs: Since the arc tiles are nonoverlapping, you could put each
        // arc in one holding space (d.x or d.y), but this is fine too.
        d.x = abs(length(p - v[0]) - .5) - ew;
        d.y = abs(length(p - v[2]) - .5) - ew;
        
        // Tile ID: One for regular double arcs.
        d.w = 1.; 
        
    }
    

    // The distance field for the central black dots.
    vec2 ip2 = floor(q) + .5;
    q -= ip2;
    if(mod(ip2.x + ip2.y, 2.)<.5){
        d.z = min(d.z, length(q));
        d.z -= ew*.8;
    }

    
    // Return the tile one and two, the central dots and ID.
    return d;
}

// The grid cell borders.
float gridField(vec2 p){
    
    vec2 ip = floor(p) + .5;
    p = abs(p - ip);

    return abs(max(p.x, p.y) - .5) - .015;
   
}

// A hatch-like algorithm, or a stipple... or some kind of textured pattern.
float doHatch(vec2 p, float res){
    
  
    // Random looking diagonal hatch lines.
    float hatch = clamp(sin((p.x - p.y)*3.14159*200.)*2. + .5, 0., 1.); // Diagonal lines.

    // The pattern is resolution based, so needs to factor in screen resolution.
    p *= res/16.;

    // Slight randomization of the diagonal lines, but the trick is to do it with
    // tiny squares instead of pixels.
    float hRnd = hash21(floor(p*6.) + .73);
    if(hRnd>.66) hatch = hRnd; 

    return hatch;
    
}

// Translating the camera about the XY plane.
vec2 getCamTrans(float t){ return vec2(sin(t/8.)/16., t/1.); }

// Rotating the camera about the XY plane.
mat2 getCamRot(float t){
    
    //return rot2(0.);
    return rot2(cos(t/4.)/16.);
}

void main(void) {

    // Aspect correct screen coordinates.
    float iRes = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
    
    
    // Scaling, rotation and translation.
    float gSc = 7.5;
    // Rotating and moving the canvas. A 2D "to" and "from" setup would be better, but this
    // will do for the purpose of the demonstration.
    vec2 cam = getCamTrans(time); // Translation.
    mat2 camRot = getCamRot(time); // Rotation.
    // Extra 45 degred rotation to give a diamond grid appearance.
    vec2 p = rot2(3.14159/4.)*(uv*gSc)*camRot + rot2(3.14159/4.)*cam;    
    
    
    // Transformed coordinate copy.
    vec2 oP = p;

     
    // Four samples for various things. In this case, it's shadows, highlights,
    // a pattern field, and the base distance field.
    vec4 dSh = distField(p - vec2(-2, -1)*.07);
    vec4 dHi = distField(p + vec2(-2, -1)*.04);
    vec4 dp = distField(p*6.);
    vec4 d = distField(p);
    
    
    
    float sf = 1./iRes*gSc;
    
    vec3 col = vec3(1, .9, .95);//vec3(.8, .6, .4);//vec3(1, .9, .95);//

    vec3 lCol = vec3(1, .05, .1);//vec3(1, .05, .1);//vec3(1, .8, .6)/8.;//
    
    
    
    float pat = smoothstep(0., sf*6., min(dp.x, dp.y))*.5 + .5;

    
    #ifdef SHOW_GRID
    // Display the individual cell tiles.
    float grid = gridField(p);
    //col = mix(col, vec3(0), (1. - smoothstep(0., sf, max(grid, -(d.z - .25)))));
    col = mix(col, col*1.5, (1. - smoothstep(0., sf*2., grid - .01)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid)));
    #endif
    
    vec2 iq = floor(p) + .5;
    vec2 q = p - iq;

    vec2 sh = max(.5 - d.xy/.15, 0.);
    vec2 shHi = max(.5 - dHi.xy/.15, 0.);
    
    
    // Thickening the base distance (the extruded walls).
    d -= .03;
  
    // If it's a cross (overlapping line) tile, darken the shadow on the
    // bottom and add high a highlight to the top line at the crossover point.
    // It's a subtle effect, but it helps create the illusion.
    if(d.w < .001){
        sh.y *= max(1.5 - dot(q, q)*1.5, 1.);
        shHi.y *= max(1.5 - dot(q, q)*1.5, 1.);
        
        sh.x *= min(.35 + dot(q, q)*4., 1.);
        shHi.x *= min(.35 + dot(q, q)*4., 1.);
    }
      
    
    // Subtle effect to give the ground some shadowy perturbation.
    col = mix(col, vec3(.3, .1, .2), (1. - smoothstep(0., sf*15., min(dSh.x, dSh.y) - .03))*.25);
    
    // Applying the bottom layer of the cell tile. In order is a shadow, fake AO, dark
    // edge, extruded base layer, top dark edge, and upper hilighted layer. There's a few
    // layers here, but it's still extremely cheap compared to raymarching.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., min(dSh.x, dSh.y) - .03*iRes/450.))*.55);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., min(d.x, d.y) - .03))*.5);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.x - .03)));
    col = mix(col, lCol*sh.x, (1. - smoothstep(0., sf, d.x)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, dHi.x - .015))*.95);
    col = mix(col, lCol*shHi.x*5.*pat, (1. - smoothstep(0., sf, dHi.x + .015)));

    // A cheap environmental glaze.
    col = mix(col, col.xzy*pat*1.5, (1. - smoothstep(0., sf*3., dHi.x + .12)));
  
    // Applying the intividual top layers of the cell tile.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., max(max(d.x, d.y - .15), dSh.y)))*.55);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*5., max(d.x - .03, d.y - .03*iRes/450.)))*.5);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.y - .03)));
    col = mix(col, lCol*sh.y, (1. - smoothstep(0., sf, d.y)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, dHi.y - .015))*.95);
    col = mix(col, lCol*shHi.y*5.*pat, (1. - smoothstep(0., sf, dHi.y + .015)));
    
    // A cheap environmental glaze.
    col = mix(col, col.xzy*pat*1.5, (1. - smoothstep(0., sf*3., dHi.y + .12)));
    
    
    // Putting some hacky patches on the center of the cell edges to account
    // for some rendering overlay issues. It's one of the downsides to rendering
    // layers on a grid. :)
    q = oP;
    iq = floor(q) + .5;
    q -= iq;
    q = abs(q) - .5;
    float sq = max(abs(q.x + .5), abs(q.y));
    sq = min(sq, max(abs(q.x), abs(q.y + .5))) - .25;
    //col = mix(col, vec3(0), (1. - smoothstep(0., sf, max(sq, min(dHi.x, dHi.x)) - .015)));
    col = mix(col, lCol*shHi.x*5.*pat, (1. - smoothstep(0., sf, max(sq, min(dHi.x, dHi.x)) + .015)));
   
 
    // The dark central circles.
    col = mix(col, col*1.4, (1. - smoothstep(0., sf*8., dHi.z - .03)));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.z)));
    
         
    // Post processing.
    //col = mix(col, col.xzy, dot(col, vec3(.299, .587, .114))/8.);
    col *= vec3(.8, .75, .6);
 

    
    // Cheap hatch overlay to give it a very cheap hand drawn look.
    float hatch = doHatch(rot2(-3.14159/4.)*oP/gSc, resolution.y);
    col *= hatch*.4 + .75;
     
    
    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
