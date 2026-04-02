#version 420

// original https://www.shadertoy.com/view/3scSRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Double Simplex Truchet Weave
    ----------------------------

    All too often, I'll be in the middle of coding something, then someone on 
    Shadertoy will post some interesting concept that sends me off on a tangent. 
    BigWIngs puts up a lot of examples along those lines.

    The other day, he posted a double quad Truchet that resulted in a really 
    intense looking weave pattern -- The link is below. The basic premise was to 
    double the usual amount of connecting points per side, then run    random 
    segments between them. It's such a simple idea, but opens up a heap of 
    possibilities.

    Anyway, BigWIngs also sketched up a very basic double sided simplex weave as 
    a proof of concept, so this is just an extension on it.

    I was pleasantly surprised by how quickly it came together. Most of the time,
    things that should take five minutes wind up taking much longer. The process
    was relatively quick because I was able to repurpose my quad version without
    too many incidents.

    In regard to the lighting, I basically hacked away with a few samples to get 
    the look I wanted. There's very little science in there, so I wouldn't take 
    any of it seriously... And I hope you like a monochrome palette -- It's the
    one I choose when I'm too lazy to make colors work. :D Either way, there's a
    "CENTER_STRIPE" define there for anyone who requires a splash of color.

    Like the quad variation, if you wanted to produce a 3D extruded version,
    you'd probably have to replace the Bezier curves with a mixture of arcs and 
    lines, as it would be much faster.

    At some point, I'd like to put together a proper 3D version, but I should 
    probably get back to what I'm supposed to be coding at the moment. :)

    Based On:

    Double Triangle Truchet Doodle- BigWIngs
    https://www.shadertoy.com/view/Ml2yzD

    Cube-mapped Double Quad Truchet - BigWIngs
    https://www.shadertoy.com/view/wlSGDD

    Double Sided Quad Truchet - Shane
    https://www.shadertoy.com/view/wl2GRG

*/

// I was undecided as to whether I wanted color, or not. Perhaps too busy?
// Anyway, I've included it as an option.
//#define CENTER_STRIPE

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Standard vec2 to float hash - Based on IQ's original.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.213, 289.197)))*43758.5453); }

// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 a, vec2 b){
    
     
    b = a - b;
    float h = clamp(dot(a, b)/dot(b, b), 0., 1.);
    return length(a - b*h);
}

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
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

     // If I were to make one change to IQ's function, it'd be to cap off the value 
    // below, since I've noticed that the function will fail with straight lines.
    float kk = 1./max(dot(b,b), 1e-6); // 1./dot(b,b);
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
    // to work... Worst coding ever. :D
    float l = length(b.xy - a.xy)*1.732/6.; // (1.4142 - 1.)/1.4142;
 
    // Points on the same edge each have the same normal, and segments between them
    // require a larger arc. There was no science behind the decision. It's just 
    // something I noticed and hacked a solution for. Comment the line out, and you'll 
    // see why it's necessary. By the way, replacing this with a standard semicircular 
    // arc would be even better, but this is easier.
    if(abs(length(b.zw - a.zw))<.01) l = r; 
  
    // Offsetting the midpoint between the exit points "a" and "b"
    // by the average of their normals and the line length factor.
    mid += (a.zw + b.zw)/2.*l;

    // Piece together two quadratic Beziers to form the smooth Bezier curve from the
    // entry and exit points. The only reliable part of this method is the quadratic
    // Bezier function, since IQ wrote it. :
    float b1 = sdBezier(p, a.xy, a.xy + a.zw*l, mid);
    float b2 = sdBezier(p, mid, b.xy + b.zw*l, b.xy);
    
    // Return the minimum distance to the smooth Bezier arc.
    return min(b1, b2);
}

// vec4 swap.
void swap(inout vec4 a, inout vec4 b){ vec4 tmp = a; a = b; b = tmp; }
 

vec4 triPattern(vec2 p){
    

    // Scaling constant.
    const float gSc = 4.;
    p *= gSc;
    
    // Keeping a copy of the orginal position.
    vec2 oP = p;
    
    // Smoothing factor: This can do my head in, sometimes. If you don't take screen
    // resolution into account, the fullscree image can look too blurry. If you do, the
    // image can look too crisp and lose something in the translation... Then there's PPI
    // to consider... Damned if you do, damned if you don't. :D
    float sf = 4./450.*gSc;
    sf*=.3;
    //float sf = 4./min(750., resolution.y)*gSc;
    
    
     
    // SIMPLEX GRID SETUP
    
    vec2 s = floor(p + (p.x + p.y)*.36602540378); // Skew the current point.
    
    p -= s - (s.x + s.y)*.211324865; // Use it to attain the vector to the base vertex (from p).
    
    // Determine which triangle we're in. Much easier to visualize than the 3D version.
    //float i = p.x < p.y? 1. : 0.; // Apparently, faster than: i = step(p.y, p.x);
    //vec2 ioffs = vec2(1. - i, i);
    
    // Amalgamating to the two lines above into this.
    vec2 ioffs = p.x < p.y? vec2(0, 1) : vec2(1, 0);
    
    
    // Vectors to the other two triangle vertices.
    vec2 ip0 = vec2(0), ip1 = ioffs - .2113248654, ip2 = vec2(.577350269);
    
    // Make the vertices match up by swapping two of the vertices on alternate triangles. 
    // Actually, it's not really necessary here, but if you want to check neighboring
    // properties, etc, it's a habit worth getting into.
    if(ioffs.x<.5) { vec2 tmp = ip0; ip0 = ip2; ip2 = tmp; }
    
    
    // Centralize everything, so that vec2(0) is in the center of the triangle.
    vec2 ctr = (ip0 + ip1 + ip2)/3.; // Centroid.
    //
    ip0 -= ctr; ip1 -= ctr; ip2 -= ctr; p -= ctr;
    
   
    
    
    // Displaying the 2D simplex grid. Basically, we're rendering lines between
    // each of the three triangular cell vertices to show the outline of the 
    // cell edges. There are faster ways to achieve this, but this will do.
    float tri = min(min(distLine(p - ip0, p - ip1), distLine(p - ip1, p - ip2)), 
                  distLine(p - ip2, p - ip0));
    
    // Connecting points around the triangles. Two for each side. I should probably
    // use a bit of trigonometry and hard code these, but I was feeling lazy. :)
    const float offs = .204124; // Approx: length(ip0 - ip1)/4., or 1./sqrt(24.);
    vec2 m01s = mix(ip0, ip1, .5 + offs);
    vec2 m01t = mix(ip0, ip1, .5 - offs);
    vec2 m12s = mix(ip1, ip2, .5 + offs);
    vec2 m12t = mix(ip1, ip2, .5 - offs);
    vec2 m20s = mix(ip2, ip0, .5 + offs);
    vec2 m20t = mix(ip2, ip0, .5 - offs);
    
    // The boundary normals for each point. I should probably hardcode these as well.
    vec2 n01 = -normalize(mix(ip0, ip1, .5));
    vec2 n12 = -normalize(mix(ip1, ip2, .5));
    vec2 n20 = -normalize(mix(ip2, ip0, .5));
    
    // Points, and their respective normals, to pass to the segment function.
    vec4[6] pnt = vec4[6](vec4(m01s, n01), vec4(m01t, n01), 
                          vec4(m12s, n12), vec4(m12t, n12),
                          vec4(m20s, n20), vec4(m20t, n20));
    
    
    
    // Shuffling the 6 array points and normals. I think this is the Fisher–Yates method, 
    // but don't quote me on it. It's been a while since I've used a shuffling algorithm, 
    // so if there are inconsistancies, etc, feel free to let me know.
    //
    // For various combinatorial reasons, some non overlapping tiles will probably be 
    // rendered more often, but generally speaking, the following should suffice.
    //
    for(int i = 5; i>0; i--){
        
        // Using the cell ID and shuffle number to generate a unique random number.
        float fi = float(i);
        
        // Random number for each triangle: The figure "s*3 + ioffs + 1" is unique for
        // each triangle... I can't remember why I felt it necessary to divide by 3,
        // but I'll leave it in there. :)
        float rs = hash21((s*3. + ioffs + 1.)/3. + fi/6.);
        
        // Other array point we're swapping with.
        //int j = int(floor(mod(rs*6e6, fi + 1.)));
        // I think this does something similar to the line above, but if not, let us know.
        int j = int(floor(rs*(fi + .9999)));
        swap(pnt[i], pnt[j]);
        
    }    

    
    vec3 d; // Distances for all three triangle cell segments.
    
    float dPnt = 1e5; // Distance for the edge points.
    
    for(int i = 0; i<3; i++){
        
        // The Bezier segments for each layer.
        d[i] =  doSeg(p,  pnt[i*2], pnt[i*2 + 1], offs);
        
        // The two edge points for each side.
        dPnt = min(dPnt, length(p - pnt[2*i].xy));
        dPnt = min(dPnt, length(p - pnt[2*i + 1].xy));
    }
    
    
    d -= .05; // Giving the segment some width.
    dPnt -= .0125; // Edge point size.
    
  
    // Overall cell color and bump value.
    vec3 col = vec3(1.);
    //float bump = -.5;
    
    // Concentric triangle background pattern.
    float pat = 1.;//clamp(cos(tri*96.)*.5 + .5, 0., 1.);
    
    // Background triangle borders.
    //col = mix(col, col*1.5, 1. - smoothstep(0., sf, tri - .01));
    //col = mix(col, col*.5, 1. - smoothstep(0., sf, tri - .0));
     
    // Extra base shadowing for the bump pass.
    //bump = mix(bump, 0., (1. - smoothstep(0., sf*3., min(min(d.x, d.y), d.z) - .03))*.5);

    
    // Rendering the layers. The bump value is similar to the color value, but differs slightly,
    // in places, so ultimately needs its own variable. Obviously, this means doubling up on 
    // calculations, but thankfully, this is a 2D... ish example.
    for(int i = 0; i<3; i++){
        
        // Shadows, stroke, color, etc.
        //col = mix(col, vec3(.0), (1. - smoothstep(0., sf*3., d[i] - .03))*.85);
        col = mix(col, vec3(.0), 1. - smoothstep(0., sf, d[i] - .02));
        col = mix(col, vec3(1), 1. - smoothstep(0., sf, d[i]));
//        col = mix(col, vec3(.03), 1. - smoothstep(0., sf, d[i] + .01));

        

    }
    
    // Return the color and bump value.
    return vec4(col, 1.);
    
}
 

void main(void)
{
    // Aspect correct pixel coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/min(750., resolution.y);
    
    // Scaling and translation.
    uv = rot2(3.14159/12.)*(uv + vec2(.1, .05)*time);
     
    // Three color samples.
    vec4 col = triPattern(uv);
 
    glFragColor = (max(col, 0.));
    
}
