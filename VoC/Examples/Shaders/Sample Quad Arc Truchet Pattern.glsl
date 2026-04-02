#version 420

// original https://www.shadertoy.com/view/wl2GRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Quad Arc Truchet Pattern
    ------------------------

    BigWIngs posted a really interesting weave pattern the other day that I wanted to
    recreate for my own amusement. I like it because the premise is incredibly simple, 
    but    it leads to visually entertaining results -- In fact, I'm amazed at just how
    much variation it provides. The link to his orginal example is below.

    The idea is very simple: Instead of rendering two sets of arcs connecting the
    midpoints of the grid cell boundaries (like a standard Truchet arc pattern), 
    double the entry\exit points on each edge and connect four arcs between them. 
    The four arcs are to connect random pairs of entry and exit points. 

    BigWIngs rendered some presets and left the overall random pattern rendering as 
    an exercise to the reader, so I gave it a go. I had to think about it for a while, 
    but then realized that all that was needed was to shuffle an array of 8 points, 
    then render the shuffled pairs. It seems to work, but I'm open to suggestion, if 
    there's a better way.

    I also went out of my way to append smooth Bezier curves, which look fine, but my 
    methodology was a bit hacky, so I'm hoping BigWIngs, or someone else, will come up 
    with something more robust.

    I didn't spend a great deal of time prettying this up, so I'm not sure what style
    this is rendered in. Art deco grunge? :) I might bump map it later to make it pop
    out a bit more, or make a 3D version. By the way, if you wanted to produce a 3D 
    extruded version, you'd probably have to replace the Bezier curves with a mixture 
    of arcs and lines, which would be much faster.

    Based On:

    Cube-mapped Double Quad Truchet - BigWIngs
    https://www.shadertoy.com/view/wlSGDD

*/

// The textured version. Without it, the look is cleaner, which makes the pattern
// a little easier to discern. Sometimes, I prefer it.
#define USE_TEXTURE

// Grid outlines, which allows the viewer to see the individual tiles... and spoils
// the illusion. :)
//#define SHOW_GRID

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Standard vec2 to float hash.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(27.917, 57.543)))*43758.5453); }

// vec4 swap.
void swap(inout vec4 a, inout vec4 b){ vec4 tmp = a; a = b; b = tmp; }

// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values.
float n2D(vec2 p) {

    vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
    
    return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// Smooth fract function.
float sFract(float x, float sf){
    
    x = fract(x);
    return min(x, (1. - x)*x*sf);
    
}

// The grungey texture -- Kind of modelled off of the metallic Shaderto texture,
// but not really. Most of it was made up on the spot, so probably isn't worth 
// commenting. However, for the most part, is just a mixture of colors using 
// noise variables.
vec3 GrungeTex(vec2 p){
    
     // Some fBm noise.
    //float c = n2D(p*4.)*.66 + n2D(p*8.)*.34;
    float c = n2D(p*3.)*.57 + n2D(p*7.)*.28 + n2D(p*15.)*.15;
    
    
    // Noisey bluish red color mix.
    vec3 col = mix(vec3(.35, .5, .65), vec3(.25, .1, .02), c);
    // Running slightly stretched fine noise over the top.
    col *= n2D(p*vec2(150., 350.))*.5 + .5; 
    
    
    // Using a smooth fract formula to provide some splotchiness... Is that a word? :)
    col = mix(col, col*vec3(.75, .95, 1.2), sFract(c*4., 12.));
    col = mix(col, col*vec3(1.2, 1, .8)*.8, sFract(c*5. + .35, 12.)*.5);
    
    // More noise and fract tweaking.
    c = n2D(p*8. + .5)*.7 + n2D(p*18. + .5)*.3;
    c = c*.7 + sFract(c*5., 16.)*.3;
    col = mix(col*.6, col*1.4, c);
    
    // Clamping to a zero to one range.
    return clamp(col, 0., 1.);
    
}

// IQ's signed distance to a quadratic Bezier. Like all of IQ's code, it's
// quick and reliable. :)
//
// Quadratic Bezier - 2D Distance - IQ
// https://www.shadertoy.com/view/MlKcDD
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C)
{  
    // p(t)    = (1-t)^2*p0 + 2(1-t)t*p1 + t^2*p2
    // p'(t)   = 2*t*(p0-2*p1+p2) + 2*(p1-p0)
    // p'(0)   = 2*(p1-p0)
    // p'(1)   = 2*(p2-p1)
    // p'(1/2) = 2*(p2-p0)
    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    float res = 0.0;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );

        // 1 root
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );

        // 3 roots
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);
        
        res = dis;

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        res = min(res,dis);

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        res = min(res,dis);

        res = sqrt( res );
    }
    
    return res;
}

// Rendering the smooth Bezier segment. The idea is to calculate the midpoint
// between "a.xy" and "b.xy," then offset it by the average of the combined normals
// at "a" and "b" multiplied by a factor based on the length between "a" and "b."
// At that stage, render a Bezier from "a" to the midpoint, then from the midpoint
// to "b." I hacked away to come up with this, which means there'd have to be a more
// robust method out there, so if anyone is familiar with one, I'd love to know.
float doSeg(vec2 p, vec4 a, vec4 b, float r){
    
    // Mid way point.
    vec2 mid = (a.xy + b.xy)/2.; // mix(a.xy, b.xy, .5);
    
    // The length between "a.xy" and "b.xy," multiplied by... a number that seemed
    // to work... Worse coding ever. :D
    float l = length(b.xy - a.xy)*(1.4142 - 1.)/1.4142;
    // Segments between edge points need to be refactored. Comment this out to
    // see why it's necessary.
    if(abs(length(b.xy - a.xy) - r*2.)<.01) l = r; 
  
    // Offsetting the midpoint between the exit points "a" and "b"
    // by the average of their normals and the line length factor.
    mid += (a.zw + b.zw)/2.*l;

    // Piece together two quadratic Beziers to from the smooth Bezier arc from the
    // entry and exit points. The only reliable part of this method is the quadratic
    // Bezier function, since IQ wrote it. :D
    float b1 = sdBezier(p, a.xy, a.xy + a.zw*l, mid);
    float b2 = sdBezier(p, mid, b.xy + b.zw*l, b.xy);
    
    // Return the minimum distance to the smooth Bezier arc.
    return min(b1, b2);
}

vec4 QuadTruchetPattern(vec2 p){
    
    vec2 ip = floor(p); // Cell ID.
    p -= ip + .5; // Cell's local position. Range [vec2(-.5), vec2(.5)].
    
    
    
    // Positioning the exit points around the square grid cell. "r" is an offset
    // from the mid point, which controls the tightness of the pattern. The value
    // ".25" gives the most even spread, whereas something like ".175" will give
    // a tighter looking loop pattern.
    //
    // The first two entries of the vec4 represent the postions, and the remaining
    // two are their edge normals, which, by the way, would be easy enough to 
    // calculate, but I thought hardcoding them in would be easier.
    //
    // Only range values between .175 and .33 will work with this configuration.
    float r = .25; 
    vec4[8] pnt = vec4[8](vec4(-r, .5, 0, -1), vec4(r, .5, 0, -1), vec4(.5, r, -1, 0), vec4(.5, -r, -1, 0),
                         vec4(r, -.5, 0, 1), vec4(-r, -.5, 0, 1), vec4(-.5, -r, 1, 0), vec4(-.5, r, 1, 0));
    
     
    // Shuffling the 8 array points and normals. Afterward, the four array pairs should
    // be rendered randomly. This also means the rendering order should be randomized,
    // which is an added bonus. I think this is the Fisher–Yates method, but it's been 
    // a while since I've used a shuffling algorithm, so if there are inconsistancies, 
    // etc, let us know.
    for(int i = 7; i>0; i--){
        // Using the cell ID and shuffle number to generate a unique random number.
        float fi = float(i);
        float rs = hash21(ip + fi/8.); // Random number.
        int j = int(floor(mod(rs*8e5, fi + 1.)));
        swap(pnt[i], pnt[j]);
         
    }
    
    // Render all four connecting arc segments.
    vec4 d;
    
    d.x = doSeg(p, pnt[0], pnt[1], r);
    d.y = doSeg(p, pnt[2], pnt[3], r);
    d.z = doSeg(p, pnt[4], pnt[5], r);
    d.w = doSeg(p, pnt[6], pnt[7], r);
    
    return d; // The Truchet tile distance field value.
    
}

void main(void) {
    

    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/min(resolution.y, 800.);
    
    // Scaling and translation.
    const float gSc = 8.;
    
    // Smoothing factor.
    float sf = 2./resolution.y*gSc;
    
    // Scaling and translation.
    vec2 p = uv*gSc + vec2(1, 0)*time;
 
    // Grid fields: Square and diamond.
    vec2 grid;
    vec2 p2 = abs(fract(p) - .5);
    grid.x = abs(max(abs(p2.x), abs(p2.y)) - .5); // Square grid.
    grid.y = abs((abs(p2.x) +  abs(p2.y)) - .5*.7071); // Diamond background.
    
    
    // The pattern itself.
    vec4 d = QuadTruchetPattern(p);
    d -= .155; // Give the pattern some width.
 
    // Background, line and edge colors. 
    vec3 col = vec3(1, .8, .6);
    vec3 lCol = vec3(1, .95, .9);
    vec3 eCol = vec3(1, .8, .6);
    
    // Subtle coloring, based on pixel height. 
    lCol = mix(lCol, lCol.yxz, -uv.y*.35 + .35);
    eCol = mix(eCol, eCol.yxz, -uv.y*.2 + .2); 
    col = mix(col, col.yxz, -uv.y*.35 + .35);    
    
    // Concentric diamond background pattern.
    float pat = clamp(cos(grid.y*6.2831*8.), 0., 1.);
    col *= 1. -  pat*.9;
    
    #ifdef USE_TEXTURE
        
        // Applying the pattern to the line element.
        lCol *= vec3(.3, .45, .55) +  pat;
        
        // Home made texture algorithm... Sufficient for this example,
        // but not my best work. :)
        vec3 tx = GrungeTex(p/gSc);
        vec3 tx2 = GrungeTex(p/gSc + 6.5);

        // Apply the texture.
        col *= min(tx2*4., 1.);
        lCol *= min(tx*1.5, 1.);
        eCol *= min(tx2*6., 1.);

        float sAlpha = .75; // Darker texture shadowing.
    #else
 
        float sAlpha = .5; // Lighter shadowing when not using a texture.
    #endif
    

    // Render the four arcs. Layers include shadowing, strokes, inner strokes,
    // coloring, etc.
    for(int i = 0; i<4; i++){
       
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., d[i] - .01))*sAlpha);
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, d[i]))*.9);
        col = mix(col, eCol, 1. - smoothstep(0., sf, d[i] + .03));
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, d[i] + .09))*.9);
        col = mix(col, lCol, 1. - smoothstep(0., sf, d[i] + .12));
    }
    
    
    // Displaying the grid.
    #ifdef SHOW_GRID
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., grid.x - .025))*.5);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid.x - .025))*.9);
    col = mix(col, vec3(1, .9, .8)*1.2, (1. - smoothstep(0., sf, grid.x - .005))*.9);
    #endif
    
    
    // Subtle vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625);
    // Colored variation.
    //col = mix(col.xzy, col, pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625));
  
    
    // Rough gamma correction.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);

}

