#version 420

// original https://www.shadertoy.com/view/ldscWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Smooth Noise Contours
    ---------------------

    Using a cheap - but effective - hack to produce antialiased-looking contour lines without the 
    need for supersampling. I had Airtight's elegant "Cartoon Fire" shader in mind when making this, 
    and have provided a link to it below. 

    I've always liked the abstract look of functional contour segments, lines, etc. There's a couple 
    of ways to produce them, depending on the look you're going for. One method involves combining
    your function value (noise, Voronoi, etc) with the "fract" function and the other involves 
    stepping the function values with the "floor" function.

    Each looks all right, except for the aliasing. You could take care of that with supersampling,
    but it's a lot of work for the GPU, so I figured there might be a way to combine the "smoothstep" 
    and "fwidth" functions to produce a smooth "fract" function. Since "x - fract(x)" is "floor(x)," 
    you'd get the "floor" function too.

    After playing around for a while, I came up with something that seems to work. As you can see,
    the partitioned contours look relatively jaggy free, even after the application of border lines 
    and highlighting.

    Anyway, the smooth fract "sFract" and complimentary smooth floor "sFloor" functions are below.
    They haven't undergone extensive testing, so I'd use them cautiously. :)

    The rest is just coloring and highlighting. I went for a simplistic cardboard cutout, vector-graphic
    style.

    Similar examples:

    Cartoon Fire - airtight
    https://www.shadertoy.com/view/lsscWr

    // More sophisticated smoothing method, but I might switch to this one in future.
    Smooth Voronoi Contours - Shane
    https://www.shadertoy.com/view/4sdXDX

*/

// Variable to a keep a copy of the noise value prior to palettization. Used to run a soft gradient 
// over the surface, just to break things up a little.
float ns;

float sFract(float x, float sm){ float fx = fract(x); return fx - smoothstep(fwidth(x)*sm, 0., 1. - fx); }
float sFloor(float x){ return x - sFract(x, 1.); }

// Standard hue rotation formula with a bit of streamlining. 
vec3 rotHue(vec3 p, float a){

    vec2 cs = sin(vec2(1.570796, 0) + a);

    mat3 hr = mat3(0.299,  0.587,  0.114,  0.299,  0.587,  0.114,  0.299,  0.587,  0.114) +
              mat3(0.701, -0.587, -0.114, -0.299,  0.413, -0.114, -0.300, -0.588,  0.886) * cs.x +
              mat3(0.168,  0.330, -0.497, -0.328,  0.035,  0.292,  1.250, -1.050, -0.203) * cs.y;
                             
    return clamp(p*hr, 0., 1.);
}

/*
// Fabrices concise, 2D rotation formula.
mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// Dave's hash function. More reliable with large values, but will still eventually break down.
//
// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash33(vec3 p){

    p = fract(p * vec3(.1031, .1030, .0973));
    p += dot(p, p.yxz + 19.19);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
    
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    //mat2  m = r2(mod(time*2., 6.2831853));    
    //p.xy = m * p.xy;//rotate gradient vector
    //p.yz = m * p.yz;//rotate gradient vector
    //p.xz = m * p.xz;//rotate gradient vector
    
    //mat3 m = r3(mod(time*2., 6.2831853));    
    //vec3 th = mod(vec3(.31, .53, .97) + time*2., 6.2831853);
    //mat3 m = r3(th.x, th.y, th.z);
    //p *= m;
    return p;

}
*/

// vec3 to vec3 hash algorithm.
vec3 hash33(vec3 p) { 

    // Faster, but doesn't disperse things quite as nicely as the block below it. However, when framerate
    // is an issue, and it often is, this is the one to use. Basically, it's a tweaked amalgamation I put
    // together, based on a couple of other random algorithms I've seen around... so use it with caution,
    // because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; // return fract(vec3(64, 8, 1)*32768.0*n)*2.-1.; 

    // I'll assume the following came from IQ.
    //p = vec3( dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
    //return (fract(sin(p)*43758.5453)*2. - 1.);

}

// Cheap, streamlined 3D Simplex noise... of sorts. I cut a few corners, so it's not perfect, but it's
// artifact free and does the job. I gave it a different name, so that it wouldn't be mistaken for
// the real thing.
// 
// Credits: Ken Perlin, the inventor of Simplex noise, of course. Stefan Gustavson's paper - 
// "Simplex Noise Demystified," IQ, other "ShaderToy.com" people, etc.
float tetraNoise(in vec3 p)
{
    // Skewing the cubic grid, then determining the first vertice and fractional position.
    vec3 i = floor(p + dot(p, vec3(0.333333)) );  p -= i - dot(i, vec3(0.166666)) ;
    
    // Breaking the skewed cube into tetrahedra with partitioning planes, then determining which side of the 
    // intersecting planes the skewed point is on. Ie: Determining which tetrahedron the point is in.
    vec3 i1 = step(p.yzx, p), i2 = max(i1, 1.0-i1.zxy); i1 = min(i1, 1.0-i1.zxy);    
    
    // Using the above to calculate the other three vertices. Now we have all four tetrahedral vertices.
    vec3 p1 = p - i1 + 0.166666, p2 = p - i2 + 0.333333, p3 = p - 0.5;
  

    // 3D simplex falloff.
    vec4 v = max(0.5 - vec4(dot(p,p), dot(p1,p1), dot(p2,p2), dot(p3,p3)), 0.0);
    
    // Dotting the fractional position with a random vector generated for each corner -in order to determine 
    // the weighted contribution distribution... Kind of. Just for the record, you can do a non-gradient, value 
    // version that works almost as well.
    vec4 d = vec4(dot(p, hash33(i)), dot(p1, hash33(i + i1)), dot(p2, hash33(i + i2)), dot(p3, hash33(i + 1.)));
    
     
    // Simplex noise... Not really, but close enough. :)
    return clamp(dot(d, v*v*v*8.)*1.732 + .5, 0., 1.); // Not sure if clamping is necessary. Might be overkill.

}

// The function value. In this case, slightly-tapered, quantized Simplex noise.
float func(vec2 p){
    
    // The noise value.
    float n = tetraNoise(vec3(p.x*4., p.y*4., 0) - vec3(0, .25, .5)*time);
    
    // A tapering function, similar in principle to a smooth combine. Used to mutate or shape 
    // the value above. This one tapers it off into an oval shape and punches in a few extra holes.
    // Airtight uses a more interesting triangular version in his "Cartoon Fire" shader.
    float taper = .1 + dot(p, p*vec2(.35, 1));
    n = max(n - taper, 0.)/max(1. - taper, .0001);
    
    // Saving the noise value prior to palettization. Used for a bit of gradient highlighting.
    ns = n; 
    
    // I remember reasoning to myself that the following would take a continuous function ranging
    // from zero to one, then palettize it over "palNum" discreet values between zero and one
    // inclusive. It seems to work, but if my logic is lacking (and it often is), feel free to 
    // let me know. :)
    const float palNum = 9.; 
    //return sFloor(d*(palNum - .001))/(palNum - 1.);
    return n*.25 + sFloor(n*(palNum - .001))/(palNum - 1.)*.75;
    
}

void main(void) {

    // Screen coordinates.
    vec2 u = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    // Function value.
    float f = func(u);
    float ssd = ns; // Saving the unpalettized noise value to add a little gradient to the color, etc.
    
    // Four sample values around the original. Used for edging and highlighting.
    vec2 e = vec2(1.5/resolution.y, 0);
    float fxl = func(u + e.xy);
    float fxr = func(u - e.xy);
    float fyt = func(u + e.yx);
    float fyb = func(u - e.yx);
    
    // Colorizing the the function value, and applying some hue rotation based on position.
    // Most of it was made up.
    vec3 col = pow(min(vec3(1.5, 1, 1)*(f*.7 + ssd*.35), 1.), vec3(1, 2., 10)*2.) + .01;
    col = rotHue(col, -.25+.4*length(u));

    // Applying the dark edges.
    col *= max(1. - (abs(fxl - fxr) + abs(fyt - fyb))*3., 0.);
  
    // Resampling with a slightly larger spread to provide some highlighting.
    fxl = func(u + e.xy*1.5);
    fyt = func(u + e.yx*1.5);
    col += vec3(.5, .7, 1)*(max(f - fyt, 0.) + max(f - fxl, 0.))*ssd*3.;
     
    // Rough gamma correction.
    glFragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
    
}
