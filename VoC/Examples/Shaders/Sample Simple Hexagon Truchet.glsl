#version 420

// original https://www.shadertoy.com/view/wllBzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Hexagon Truchet Tiles
    Just playing around to experiment
    with tiles and drawing / mixing
    elements in 2D shaders.

*/

#define PI          3.1415926
#define PI2         6.2831853
#define T             time*.35
#define S            smoothstep
#define R            resolution
#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))
#define hash(a,b) fract(sin(dot(vec2(a,b), vec2(127.47, 57.85)))*43758.5453)

//https://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 get_hue(in float r){
    vec3 hueShift = vec3(2, 1., 0.5);
     return .5 + .45*cos(r + hueShift)*.75;
}

void main(void)
{
    // Aspect correct screen coordinates.
    vec2 uv = gl_FragCoord.xy/R.y;
    vec2 fv = uv;
    float wdf = .2*fv.y;
    
    // Scene scaling and transalation.
    uv -= vec2(.5-T*.1,1.);
    uv *= 7.;
   // uv *=r2(T*.5);
    const vec2 s = vec2(sqrt(3.), 1.);
    
    // Hex IDs.
    vec2 i0 = vec2(floor(uv/s));
    vec2 i1 = vec2(floor(uv/s + .5));
    
    vec2 c0 = (vec2(i0) + .5) * s;
    vec2 c1 = (vec2(i1) + .0) * s;
    
    vec2 p, id;
    
    // Nearest hexagon local coordinates and ID.
    if (length(c0 - uv) < length(c1 - uv)){
        p = (c0 - uv);
        id = i0;
    } else {
        p = (c1 - uv);
        id = i1 + .5;
    }
    
    vec3 C = vec3(0.);
    
    // Using the local hexagon cell coordinates to render cell borders.
    float h = abs(max(abs(p.x)*.8660254 + abs(p.y)*.5, abs(p.y)) - .5) - .1;
    h = abs(h)-.04;
    
    float rnd = hash(id.x,id.y);
    float dnr = hash(id.y,id.x);
    vec3 hue = get_hue(2.283*rnd+dnr+3.);
    vec3 fhue = get_hue(10.*wdf+12. ); 
    // Smoothing factor.
    float sf = 5.*2./resolution.y;

    // circles
    // Using the local coordinates to render three arcs, and the cell ID
    // to randomly rotate the local coordinates by factors of PI/3.
    rnd = floor(rnd*8.999);
    // for over/under effect
    float rnx = floor(dnr*6.399);
    
    // Random rotation and flow direction..
    float dir = mod(rnd, 2.)*2. - 1.;
    float ood = mod(rnx, 2.)*2. - 1.;
        
    
    float ang = rnd*3.14159/3.;
    p = mat2(cos(ang), sin(ang), -sin(ang), cos(ang))*p; // Random rotate.
  
    // Three arcs points..
    // I should have studied geometry better
    vec3 d3, a3;
    vec2 p0 = p - vec2(-.5/1.732, .5);
    vec2 p1 = p - vec2(.8660254*2./3., 0);
    vec2 p2 = p - vec2(-.5/1.732, -.5);

    // Distances - Circles.
    d3 = vec3(length(p0), length(p1), length(p2));
    // Arcs.
    d3 = abs(d3 - 1.732/6.) - wdf;

    a3.x = atan(p0.x, p0.y);
    a3.y = atan(p1.x, p1.y);
    a3.z = atan(p2.x, p2.y);
    
    // Distance and angles -- Obtaining the closest.
    vec2 da = d3.x<d3.y && d3.x<d3.z ? 
        vec2(d3.x, a3.x) : d3.y<d3.z ?
            vec2(d3.y, a3.y) : vec2(d3.z, a3.z);

    // Distance and angle.
    float d = da.x;

    
    // Folding the angle over...
    float a = abs(fract(da.y/PI*6. + (T*.75)*dir) - .5)*2. - .5;
    
    // Moving rectangles.
    a = max(d + .07, a/PI2);   
    a = abs(abs(a) - .01) - .015;
    
    float vt = sin((3.*rnd)+T*1.75)*.075+.1;
    h=abs(abs(h)-.03-vt)-.001;
    h = abs(abs(h) - .02) - .02;
    h = abs(abs(h) - .02) - .01;

    float line = 1.-S(0., sf, h);
    float bline = min(S(0., sf, a),line);
    float fline = max(0.,(-ood*line));
    float cr = 1.-S(.02,.03,length(p)-.05);

    // bottom / under hex patterns
    C = mix(C, hue, ood*bline);
    // blackout line for truchet arcs
    C = mix(fhue,C, S(0., sf, d));
    
    // animated patterns
    C = mix(C, vec3(0), 1.-S(0., sf, a));
    
    // color dots
    C = mix(C, get_hue(dnr*3.34), cr);
    // top / over hex patterns
    C = mix(C, hue, fline);
    
    // Output to screen
    glFragColor = vec4(C,1.0);
}

