#version 420

// original https://www.shadertoy.com/view/flj3Wm

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Synchronized Line Animation
    ---------------------------    
    
    Rendering repeat line sequences within triangle cells to create a synchronized 
    line animation.
    
    This particular sequence is a rough recreation of an animation that I've seen 
    in various reincarnations before. I'm pretty sure the original was conceived by 
    a visual artist known as Admiral Potato, who has an awesome body of work... and 
    a Shadertoy account, from what I can see. The link to his work is below.
    
    It's based on a very simple idea: Partition space into some kind of grid, then
    use the vertex, midpoint, etc, geometry to render node based line animations. 
    I've done similar things before with a simple square grid, but hadn't tried it 
    with a more interesting tiling arrangement.
    
    Aesthetically, I adhered to the spirit of the original, but rendered it in a way
    that was more condusive to realtime constraints. Anyway, this was just a simple
    but rushed geometric animation example, so don't worry about the code itself too 
    much. It was a spur of the moment thing, which meant it was hacked together with 
    old routines of mine and without a lot of forethought. Hopefully, Admiral Potato 
    himself will one day convert his original to pixel shader form and post it on 
    Shadertoy. 

    Reference link:
    
    // Admiral Potato's Tumblr page. If you're interested in graphics, then 
    // you've probably seen versions of his work floating around the net.
    http://admiralpotato.tumblr.com/
    
    // The link to the original animation.
    Hex Doctor - Admiral Potato
    http://nuclearpixel.com/motion/hex-doctor/
    
 

*/

// Color palette: Pink\Green: 0, Copper\Gold: 1, Silver: 2
#define PALETTE 0

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

// IQ's signed distance to a 2D triangle.
float sdTri(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2){
 
    vec2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;

    vec2 v0 = p - p0, v1 = p - p1, v2 = p - p2;

    vec2 pq0 = v0 - e0*clamp( dot(v0, e0)/dot(e0, e0), 0., 1.);
    vec2 pq1 = v1 - e1*clamp( dot(v1, e1)/dot(e1, e1), 0., 1.);
    vec2 pq2 = v2 - e2*clamp( dot(v2, e2)/dot(e2, e2), 0., 1.);
    
    float s = sign( e0.x*e2.y - e0.y*e2.x);
    vec2 d = min( min( vec2(dot(pq0, pq0), s*(v0.x*e0.y - v0.y*e0.x)),
                       vec2(dot(pq1, pq1), s*(v1.x*e1.y - v1.y*e1.x))),
                       vec2(dot(pq2, pq2), s*(v2.x*e2.y - v2.y*e2.x)));

    return -sqrt(d.x)*sign(d.y);
}

// Triangle's incenter and radius.
vec3 inCentRad(vec2 p0, vec2 p1, vec2 p2){
    
    // Side lengths.
    float bc = length(p1 - p2), ac = length(p0 - p2), ab = length(p0 - p1);
    vec2 inCir = (bc*p0 + ac*p1 + ab*p2)/(bc + ac + ab);   
    
    // Area.
    float p = (bc + ac + ab)/2.;
    float area = sqrt(p*(p - bc)*(p - ac)*(p - ab));
    
    return vec3(inCir, area/p);
}

// IQ's line distace formula. 
float sdLine( in vec2 p, in vec2 a, in vec2 b ){

    p -= a, b -= a;
    return length(p - b*clamp(dot(p, b)/dot(b, b), 0., 1.));
}

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){
    
    return mat2(1, -s.y, -s.x, 1)*p;
}

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){
    
    //float idm = 1. - s.x*s.y;
    //if(idm == 0.) idm += 1e-6;
    //mat2 inM = 1./(idm)*mat2(1, s.y, s.x, 1);
    //return inM*p;
    return inverse(mat2(1, -s.y, -s.x, 1))*p;
}

/*
// Exponential easing function.
float exponentialOut(float t) {
  return t == 1. ? t : 1. - pow(2., -8.*t);
}

// Quad easing function. 
float easeOutQuad(float t) {
    return -t*(t - 2.);
}
*/ 

// Global distance values for the two colored lines and end points.
// This was hacked in at the last minutes... I'll incorporate it
// into the structure below at some stage.
float line = 1e5;
float line2 = 1e5;
float circle = 1e5;
float circle2 = 1e5;
 

// Global vertices, local coordinates, etc, of the triangle cell.
struct triS{
    
    vec2[3] v; // Outer vertices.
    vec2 p; // Local coordinate.
    vec2 id; // Position based ID.
    float dist; // Distance field value.
    float triID; // Triangle ID.
};

// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.

triS blocks(vec2 q){
    

    const float tf = 2./sqrt(3.);
    // Scale.
    const vec2 scale = vec2(tf, 1)*vec2(1./2.);

    // Brick dimension: Length to height ratio with additional scaling.
    const vec2 dim = vec2(scale);
    // A helper vector, but basically, it's the size of the repeat cell.
    const vec2 s = dim*2.;
    
     // Skewing half way along X, and not skewing in the Y direction.
    const vec2 sk = vec2(tf/2., 0);
    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual block ID and block center.
    vec2 idi, cntr;
    
    // Four block corner postions.
    const vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5), vec2(.5, -.5), vec2(-.5)); 
    
    // Unskewed block corner postions.
    vec2[4] vert = vec2[4](vec2(-.5, .5), vec2(.5), vec2(.5, -.5), vec2(-.5)); 
    // Unskewing to enable rendering back in normal space.
    vert[0] = unskewXY(vert[0]*dim, sk);
    vert[1] = unskewXY(vert[1]*dim, sk);
    vert[2] = unskewXY(vert[2]*dim, sk);
    vert[3] = unskewXY(vert[3]*dim, sk); 
    
    // Skewed local coordinates.
    vec2 skqxy = skewXY(q.xy, sk);
    
    
    float triID = 0.; // Triangle ID. Not used in this example, but helpful.
 
    // Initializing the global vertices and local coordinates of the triangle cell.
    triS gT, tri1, tri2;
    
    // Initialize the various distance field values to a maximum.
    line = 1e5;
    line2 = 1e5;
    circle = 1e5;
    circle2 = 1e5;
    

    // End point width and line width values.
    const float cw = .02;
    const float lw = .007;
    
    // Fractional time for the four nodes. 
    const int ttm = 4;
    float tm = 2. - time;
    float modtm = mod(tm, float(ttm));
    int index = int(modtm);
    // Another animation thread.
    float tm2 = time;
    float modtm2 = mod(tm2, float(ttm));
    int index2 = int(modtm2);
 

    // Iterate through four neighboring grid squares -- Each square is skewed
    // and subdivided diagonally to determine the nearest triangle. Yeah, it's
    // annoying work, but the lines are rendered outside the confines of each
    // triangle cell, which means neighboring cells need to be accounted for.
    for(int i = min(0, frames); i<4; i++){    
        
        // Block center.
        cntr = ps4[i]/2.;

        // Skewed local coordinates.
        p = skqxy;
        //ip = floor(p/s - cntr) + .5 + cntr; // Local tile ID.
        // Correct positional individual tile ID.
        idi = (floor(p/s - cntr) + .5 + cntr)*s;
        p -= idi; // New local position.
        // Unskew the local coordinates.
        p = unskewXY(p, sk);       
         
        // Unskewing the rectangular cell ID.
        idi = unskewXY(idi, sk);  

        
        // Partioning the rectangle into two triangles.
        for(int triJ = min(0, frames); triJ<2; triJ++){
        
            // Vertices for triangle one or two.
            if(triJ==0) tri1.v = vec2[3](vert[0], vert[1], vert[2]); 
            else tri1.v = vec2[3](vert[0], vert[2], vert[3]);
            
            tri1.id = idi + inCentRad(tri1.v[0], tri1.v[1], tri1.v[2]).xy; // Position Id.
            tri1.triID = float(i + triJ*4); // Triangle ID. Not used here.
            tri1.dist = sdTri(p, tri1.v[0], tri1.v[1], tri1.v[2]); // Field distance.
            tri1.p = p; // 2D coordinates.

            // Mid edge points.
            vec2[3] mid = vec2[3](mix(tri1.v[0], tri1.v[1], .5), mix(tri1.v[1], tri1.v[2], .5), mix(tri1.v[2], tri1.v[0], .5));

            // Animating three edge lines and three vertex based lines.
            for(int j = min(0, frames); j<3; j++){

                 
                // Three edge lines. Each map out a rhomboid path between four nodes.
                //
                // Rhombic nodal points -- These are hand picked.
                vec2[4] pnt = vec2[4](mix(tri1.v[(0 + j)%3], mid[(2 + j)%3], .5), mix(mid[(2 + j)%3], mid[(0 + j)%3], .5), 
                                mix(mid[(2 + j)%3], mid[(1 + j)%3], .5), mid[(2 + j)%3]);
                vec4 vAng = vec4(6.2831/3., 6.2831/6., 6.2831/3., 6.2831/6.); // Sweep angle.
                vec2 p0 = p - pnt[(index + 1)%4]; // Pivot point.
                float ang = mix(0., vAng[index], (fract(tm))); // Angular position.
                p0 *= rot2(-ang); // Angular pivot.
                vec2 p1 = (pnt[index] - pnt[(index + 1)%4]); // Anchor point.

                // Line and circular end points for this edge.
                float ln = sdLine(p0, vec2(0), p1);
                float cir = min(length(p0), length(p0 - p1));  

                // Add the line and end points for this edge to the total.
                circle = min(circle, cir - cw);
                line = min(line, ln - lw); 

                // Three vertex-based lines. Each map out a rhomboid path between four nodes.
                //
                // Do the same as above.
                pnt = vec2[4](tri1.v[(0 + j)%3], mix(tri1.v[(0 + j)%3], tri1.v[(1 + j)%3], .25), 
                              mix(tri1.v[(0 + j)%3], tri1.v[(2 + j)%3], .25), vec2(0));
                vec2 refDir = mix(pnt[0], pnt[2], .5) - pnt[1];
                pnt[3] = pnt[1] + length(refDir)*normalize(refDir)*2.;

                p0 = p - pnt[(index2 + 1)%4];
                vAng = vAng.wzyx;
                ang = mix(0., vAng[index2], (fract(tm2)));
                p0 *= rot2(-ang);
                p1 = (pnt[index2] - pnt[(index2 + 1)%4]);
                ln = sdLine(p0, vec2(0), p1);

                cir = min(length(p0), length(p0 - p1));  
              
                circle2 = min(circle2, cir - cw);
                line2 = min(line2, ln - lw); 
                
                
                // If applicable, update the overall minimum distance value,
                // then return the correct triangle information.
                if(tri1.dist<d){
                    d = tri1.dist;
                    gT = tri1;
                    //gT.id = idi + inCentRad(gT.v[0], gT.v[1], gT.v[2]).xy;
                }
                
                
            } 
        }
        
        if(line>1e6) break; // Fake break to help the compiler.
    
        
    }
    
    // Return the distance, position-based ID and triangle ID.
    return gT;
}

// A simpler triangle routine to help render the background.
float gTri;

vec4 getTri(vec2 p, float sc){
 
    
    // Rectangle stretch.
    vec2 rect = vec2(2./sqrt(3.), 1)*sc; 
    //const vec2 rect = vec2(.85, 1.15)*scale; 
    // Skewing half way along X, and not skewing in the Y direction.
    vec2 sk = vec2(rect.x/2./sc, 0); // 12 x .2
    //p.x += rect.x/2.; 
     
     p = skewXY(p, sk);
    
    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
    vec2 id = floor(p/rect) + .5; 
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
    p -= id*rect; 
    
    
    // Equivalent to: 
    //float tri = p.x/rect.x < -p.y/rect.y? 1. : 0.;
    // Base on the bottom (0.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 0. : 1.;
   
    p = unskewXY(p, sk);
    
    return vec4(p, id);
    
    
}

void main(void) {

    // Resolution and aspect correct screen coordinates.
    float iRes = min(resolution.y, 800.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes; 
    
     
    // Scaling and translation.
    const float gSc = 1.;
    vec2 p = rot2(3.14159/6.)*uv*gSc;// + vec2(0, time/24.);//rot2(3.14159/6.)*
    vec2 oP = p; // Saving a copy for later.
    
    // Resolution and scale based smoothing factor.
    float sf = gSc/resolution.y;
    
    // Sun direction and shadow sample.
    vec2 sDir = rot2(3.14159/6.)*normalize(vec2(-1));
    triS gTSh = blocks(p - sDir*.025);
    
    // Shadow field values.
    float lineSh = line, line2Sh = line2, circleSh = circle, circle2Sh = circle2;
    
    // Take a function sample. 
    triS gT = blocks(p); 
    
 
    // Triangle vertices, local coordinates and position-based ID.
    // With these three things, you can render anything you want.
    vec2[3] svV = gT.v;
    vec2 svP = gT.p;
    vec2 svID = gT.id;

    
    // Initializing the scene to a dark background color.
    vec3 bg = vec3(.07);
    vec3 col = bg;  
  

    // Triangle edge lines.
    float ln = 1e5;
    ln = min(ln, sdLine(svP, svV[0], svV[1]));
    ln = min(ln, sdLine(svP, svV[1], svV[2]));
    ln = min(ln, sdLine(svP, svV[2], svV[0]));
    ln -= .0015; 
     
    // Render the triangle cell edges.
    col = mix(col, col*1.6, (1. - smoothstep(0., sf*4.*iRes/450., ln - .0005)));
    col = mix(col, col*.3, (1. - smoothstep(0., sf*2., ln)));
      
 
    // The triangle background pattern.
    //
    // Sunken holes.
    vec2 q = oP;
    float tSc = 1./2./4.;
    vec2 offs = vec2(sqrt(3.), 1)/3./16.;
    vec4 triSh = getTri(q - sDir*.025*tSc, tSc);
    float dotsSh = length(triSh.xy - offs) - .02;
    if(gTri<.5) dotsSh = length(triSh.xy + offs) - .02;
    
    vec4 tri = getTri(q, tSc); 
    
    float dots = length(tri.xy - offs) - .02;
    if(gTri<.5) dots = length(tri.xy + offs) - .02;
    
    // Render the sunken holes.
    col = mix(col, bg*.55, 1. - smoothstep(0., sf*2., dots - .003));
    col = mix(col, (bg + .03)*(max(dots - dotsSh, 0.)/(.025/8.)*.5 + .5), 1. - smoothstep(0., sf, dots));
 
    // Raised holes.
    q = oP; 
    q += vec2(sqrt(3.), 1)/2.*tSc;
    triSh = getTri(q - sDir*.025*tSc, tSc);
    dotsSh = length(triSh.xy) - .02;
    
    tri = getTri(q, tSc);
    dots = length(tri.xy) - .02;
    
     // Render the raised holes.
    col = mix(col, bg*.55, 1. - smoothstep(0., sf*2., dots - .003));
    col = mix(col, 1.3*(bg + .03)*(max(dotsSh - dots, 0.)/(.025/8.)*.5 + .5), 1. - smoothstep(0., sf, dots));

    // Render the drop shadow over the background.
    float shadow = min(min(lineSh, line2Sh), min(circleSh, circle2Sh));
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*12., shadow - .006))*.5);
 
    // Back texture. Not used.
    //vec3 tx = texture(iChannel0, oP).xyz; tx *= tx;
    //tx = smoothstep(-.1, .5, tx);
    //col *= tx*2.;
    
    // Color palette.
    vec3 col1 = vec3(.75, 1, .3);//vec3(.3, 1, .5);//vec3(1, .75, .3)
    vec3 col2 = vec3(1, .2, .4);//vec3(1, .2, .4);
    #if PALETTE == 1
    col1 = vec3(1, .65, .25);
    col2 = vec3(.75, .35, .15);
    #elif PALETTE == 2
    col1 = vec3(.6);
    col2 = col1;
    #endif
     
    // Render the hexagon line layers -- AO, stroke, color, etc.
    float sh2 = max(.2 - line2/.006, 0.);
    sh2 *= max(line2Sh - line2, 0.)/.025 + .5;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., line2 - .003))*.35);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, line2 - .003));
    col = mix(col, col2*sh2, 1. - smoothstep(0., sf, line2));
    //col = mix(col, col*2., 1. - smoothstep(0., sf, line2 + .007)); // Extra shine.
   
    // Render the triangle line layers with a higher Z value.
    float sh = max(.2 - line/.006, 0.);
    sh *= max(lineSh - line, 0.)/.025 + .5;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., line - .003))*.35);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, line - .003));
    col = mix(col, col1*sh, 1. - smoothstep(0., sf, line));
    //col = mix(col, col*2., 1. - smoothstep(0., sf, line + .007)); // Extra shine.
    
    
    
    // Silver end points.
    col1 = vec3(1); col2 = col1;
    // Gold ends.
    //col1 = vec3(1.2, .95, .5); col2 = col1;
    // Silver fluorescent ends.
    //col1 = mix(col1*3., vec3(1), .65); col2 = mix(col2*4., vec3(1), .65);
    
    // Render the hexagonal end points.
    sf *= 1.5;
    sh2 = max(.7 - circle2/.016, 0.);
    sh2 *= max(circle2Sh - circle2, 0.)/.025*.5 + .5;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., circle2 - .003))*.35);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, circle2 - .003));
    col = mix(col, col2*sh2, 1. - smoothstep(0., sf, circle2));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*1.5, circle2 + .01));
   
    // Render the triangle end points.
    sh = max(.7 - circle/.016, 0.);
    sh *= max(circleSh - circle, 0.)/.025*.5 + .5;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., circle - .003))*.35);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, circle - .003));
    col = mix(col, col1*sh, 1. - smoothstep(0., sf, circle));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*1.5, circle + .01));
    
    
    // Fake overhead lighting to roughly match the shadows.
    col *= max(1.25 - length(uv + sDir*.5)*.5, 0.);
    
    
    // Subtle vignette.
    //uv = gl_FragCoord.xy/resolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625)*1.05;
    
    
    // Rought gamma correction and presentation.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
