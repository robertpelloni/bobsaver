#version 420

// original https://www.shadertoy.com/view/wtByzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Heptagon-Pentagon Tiling
    ------------------------

    You can learn a lot from looking a stock images on the internet.
    This particular aesthetic is my own, but it encompasses a few
    common geometric vector graphics cliches -- Colorful highlights, 
    vector borders and weird canvas coordinate manipulation. All are 
    very simple to produce.

    This is a heptagon and pentagon tiling arrangement that you may
    have seen around. I have a nice neat example somewhere, but I 
    couldn't find it, so I've hacked in a function from an extruded
    3D tiling I made a while back that needs a bit of a tidy up. By
    the way, I'll post that too at some stage.

    The tiling method I've used is OK, but there are better ways to 
    produce a heptagon pentagon tiling, so I wouldn't pay too much
    attention to it. Having said that, it works, and will work in    
    an extruded 3D setting as well.

    I've used a standard circle inversion based transformation to mix
    things up a bit and give some extra perspective. It was tempting
    to apply some post processing, like hatching or something along
    the lines of Flockaroo's pencil sketch algorithm, but I figured
    I should keep things simple.

*/

// Show the individual tile boundaries.
//#define SHOW_GRID

// Perform a coordinate transform. Commenting this out will show the regular pattern.
#define TRANSFORM

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// Signed distance to a regular pentagon -- Based on IQ's pentagon function.
float sdHeptagon( in vec2 p, in float r){
    
    const vec3 k = vec3( .9009688679, .43388373911, .4815746188); // pi/5: cos, sin, tan
    p.y = -p.y;
    p.x = abs(p.x);
    p -= 2.*min(dot(vec2(-k.x, k.y), p), 0.)*vec2(-k.x, k.y);
    p -= 2.*min(dot(vec2(k.x, k.y), p), 0.)*vec2(k.x, k.y);
    p -= 2.*min(dot(vec2(-k.x, k.y), p), 0.)*vec2(-k.x, k.y);
    p -= vec2(clamp(p.x, -r*k.z, r*k.z), r);    
    return length(p)*sign(p.y);
    
}

// Convex pentagon routine -- Adapted from IQ's triangle routine. 
float sdPent(in vec2 p, in vec2[5] v){
    
    vec2[5] e;
    for(int i = 0; i<4; i++) e[i] = v[i + 1] - v[i];
    e[4] = v[0] - v[4];
   
    float s = sign( e[0].x*e[4].y - e[0].y*e[4].x );
    vec2 d = vec2(1e5);
    
    for(int i = 0; i<5; i++){
        v[i] = p - v[i];
        vec2 pi = v[i] - e[i]*clamp( dot(v[i], e[i])/dot(e[i], e[i]), 0., 1.);
        d = min(d, vec2(dot(pi, pi), s*(v[i].x*e[i].y - v[i].y*e[i].x)));
    }

    return -sqrt(d.x)*sign(d.y);
}

// Some constants that help determine the geometry. This is a messy function. I have a 
// cleaner one somewhere, so I'll drop that in at some stage. These are just heptagon
// and pentagon heights, widths and apothems (center to mid edge point).
const float PI = 3.14159;
const float rad7 = .5;
const float apothem7 = (rad7*cos(PI/7.));
const float side7 = rad7*sin(PI/7.)*2.;
const float width7s = side7*cos(2.*PI/7.);
const float width7 = (side7*cos(PI/7.) + side7/2.);
const float yDiff = (2.*apothem7*sin(.5*PI/7.));
const float h = sqrt(apothem7*apothem7*4. - (width7 + width7s)*(width7 + width7s));

const vec2 s = vec2(width7*2. + width7s*2., (apothem7 + apothem7 + h));
const vec2 s2 = s*vec2(1, 2);
const float yh = s.y - apothem7 - rad7;

// Extra variables hacked in at the last miniute. I needed the local coordinates and
// needed to calculate the pentagon dots seperately... I'll tidy these up later.
vec2 pL;
float pDots;

// The heptagon-pentagon distance field: By the way, I poached this from a 3D extruded 
// tiling example I did a while back, so you can actually render this in a more efficient 
// manner in 2D.
//
// Off the top of my head, the easier 2D way involves rendering two sets of repeat heptagons 
// on a tile of dimensions that involve the figures above, and the remaining space will be 
// that of the slightly irregular pentagon. There's some alternate tile flipping involved, 
// but that's about it. 
//
// I might produce the simpler form at some stage and post it. As mentioned, the benefit
// of the following procedure is that it'll work in an extruded setting. Plus, you have
// access to vertex information, etc. For more advanced imagery, you need the vertex 
// information, and so forth.
//
vec4 distField(vec2 p){
    
    
    // Shape distance field holder. There are six in all. Four heptagons and two pentagons.
    float[6] pl;
    // Centers of the six individual polygons that represent a single tile. Use the show
    // grid borders option to see more clearly.
    vec2[6] pCntr = vec2[6](vec2(0, 0), vec2(width7s + width7, yDiff), 
                            vec2(0, -apothem7*2.), vec2(width7s + width7, apothem7*2. + yDiff),
                            vec2(0, yDiff/2.), vec2(0, yDiff/2.));
    
    // Shape IDs and local coordinates.
    vec2[6] ip;
    vec2[6] pLoc;
    
    // Using the information above to produce four heptagons.
    vec2 oP = p - pCntr[0];
    ip[0] = floor(p/s2);
    p = mod(p, s2) - s2/2.;
    pLoc[0] = p;
    pl[0] = sdHeptagon(p, apothem7);
   
    p = oP - pCntr[1];
    ip[1] = floor((p)/s2);
    p = mod(p, s2) - s2/2.;
    pLoc[1] = p;
    pl[1] = sdHeptagon((p)*vec2(1, -1), apothem7); 
    
    p = oP - pCntr[2];
    ip[2] = floor((p)/s2);
    p = mod(p, s2) - s2/2.;
    pLoc[2] = p;
    pl[2] = sdHeptagon((p)*vec2(1, -1), apothem7); 
    
    p = oP - pCntr[3];
    ip[3] = floor((p)/s2);
    p = mod(p, s2) - s2/2.;
    pLoc[3] = p;
    pl[3] = sdHeptagon(p, apothem7); 

    // Producing the two pentagons, plus some outer vertex dots.
    p = oP - pCntr[4];
    ip[4] = floor((p)/s);
    
    
    if(mod(ip[4].y, 2.)<.5){
       p.x -= s.x/2.;
       ip[4] = floor((p)/s);
    }

    p = mod(p, s) - s/2.;
    
    ip[5] = ip[4];
   
    // Pentagon vertices.
    vec2[5] v;
    v[0] = vec2(-s.x/2. + side7/2., 0);
    v[1] =  v[0] + rot2(-PI*2./7.)*vec2(side7, 0);
    v[2] = vec2(0, yh);
    v[3] = vec2(0, -yh);
    v[4] =  v[0] + rot2(PI*2./7.)*vec2(side7, 0);
    
    // Pentagon one.
    pl[4] = sdPent(p, vec2[5]( v[0], v[1], v[2], v[3], v[4]));
    
    pCntr[4] = (v[0] + v[1] + v[2] + v[3] + v[4])/5.;
    
    // The pentagon outer dots.
    pDots = 1e5;
    for(int i = 0; i<5; i++){
      pDots = min(pDots, length(p - v[i]));
    }
    
    pLoc[4] = p - pCntr[4];
  
    // Pentagon two. Same vertices, but with the local coordinates mirrored
    // acress the X-axis.
    pl[5] = sdPent(p*vec2(-1, 1), vec2[5]( v[0], v[1], v[2], v[3], v[4]));
    pLoc[5] = p;
    pCntr[5] = (v[0] + v[1] + v[2] + v[3] + v[4])*vec2(-1, 1)/5.;
    pLoc[5] = p - pCntr[5];
    
    // Other pentagon outer dots.
    for(int i = 0; i<5; i++){
      pDots = min(pDots, length(p*vec2(-1, 1) - v[i]));
    }    
    
    // Iterate through each of the six polygons, then return the minimum
    // distance, local coordinates, ID, etc.
    float minD = 1e5;
    vec2 pID = vec2(0);
    vec2 si = s2;
    
    int cID; 
    for(int i = 0; i<6; i++){
        
        if(i>3) si = s;
        if(pl[i]<minD){
            
             minD = pl[i];
             pID = ip[i]*si + pCntr[i];
             cID = i;
             pL = pLoc[i];
           
        }
        
    } 
    
    // Retrun the minimum distance, shape center ID, and shape number.
    return vec4(minD, pID, cID);
}

// The tile grid borders. Alternate rows are offset by
// half a grid cell.
float gridField(vec2 p){
    
    vec2 ip = floor(p/s);
    if(mod(ip.y, 2.)<.5) p.x += s.x/2.;
    ip = floor(p/s);
    p = abs(mod(p, s) - s/2.);
    return abs(max(p.x - .5*s.x, p.y - .5*s.y)) - .01;
}

void main(void) {

    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
   
   
    // For all intents and purposes, this is just a fancy coordinate transformation.  For 
    // instance, "uv = vec2(log(length(uv)), atan(uv.y, uv.x)/PI/2.*(width7 + width7s)*2.5)" 
    // will polar transform things, and something like "uv.y += sin(uv.x*a)*b" will make
    // things look wavy. This particular one is a cool circle inversion formula that people 
    // like MLA, S2C, Mattz, etc, use when they're putting together hyperbolic geometry and 
    // so forth. On a side note, I'll be putting a couple of those up pretty soon. 
    #ifdef TRANSFORM
    // I can't remember who uses this particular style (MLA?), but many use it, and it's the 
    // one I prefer.
    //vec2 m = vec2((2.*mouse*resolution.xy.xy - resolution.xy)/resolution.y);
    vec2 m = vec2(cos(time/8.), -sin(time/4.))*.5;
    float k = 1./dot(m, m);
    vec2 c = k*m; // Circle inversion.
    float tk = (k - 1.)/dot(uv - c, uv - c);
    uv = tk*uv + (1. - tk)*c;
    uv.x = -uv.x; // Maintain chirality.
    uv = rot2(-time/8.)*uv;
    #endif
    
    
    // Scaling and translation.
    float gSc = 4.;
    vec2 p = uv*gSc - vec2(-1, -.5)*time/2.;
    // Smoothing factor.
     float sf = 1./resolution.y*gSc;
    
    // The pentagon and heptagon tiling.
    vec4 d = distField(p);
    // The individual shape ID.
    float cID = d.w;
    
     
    // Set the background color to white.
    vec3 col = vec3(1);
    
     
    // Use the pixel angle within each individual shape to produce some angular
    // colors, which gives the effect of light bouncing offs of cones.

    // Using the shape ID to set the vertice number.
    float n = cID<3.5? 7. : 5.;
    // Rotate each shape, depending on its ID.
    float oN = 0.;
    if(cID == 1. || cID == 2.) oN = .5;
    if(cID == 4.) oN = .25;
    if(cID == 5.) oN = .75;
    
    // Rotate the shape's local coordinates.
    vec2 q = pL;
    q *= rot2(-oN/n*PI*2.);
    
    // Get the pixel angle.
    float ang = mod(atan(q.x, q.y), 6.2831);
    // Snapping the angle to one of five or seven palette colors.
    float iang = floor(ang*n/(PI*2.))/n;
    // The pentagons aren't nice symmetrical reqular pentagons, so the colored wedges
    // aren't evenly spread out. This is just a quick hack to move a couple of lines.
    if(cID == 5. && n==5. && abs(iang - 4./5.)<.01) iang = floor((ang - .2)*n/(PI*2.))/n;
    if(cID == 5. && n==5. && abs(iang - 4./5.)<.01) iang = floor((ang + .2)*n/(PI*2.))/n;
    if(cID == 4. && n==5. && abs(iang - 1./5.)<.01) iang = floor((ang - .2)*n/(PI*2.))/n;
    if(cID == 4. && n==5. && abs(iang - 1./5.)<.01) iang = floor((ang + .2)*n/(PI*2.))/n;
    
    
    // Utilizing IQ's versatile palette formula to produce some angular colors. If
    // I were only allowed to use one simple palette formula, this would be it.
    vec3 lCol = .55 + .45*cos(iang*6.2831 + vec3(0, 1, 2));
    // Flat shading override.
    //lCol = vec3(1);
    //float rnd = hash21(d.yz);
    //lCol = .5 + .45*cos(rnd*6.28 + vec3(1, 2, 3));
    
    
 
    // Producing some dots at the heptagonal vertices, then joining them with
    // the pentagon dots. As an aside, the pentagon vertices where produced 
    // seperatly in the distance function, which is hacky, but it was the best
    // way I could think of at the time.
    float hDots = 1e5;
    vec2 v0 = rot2(-oN/n*PI*2.)*vec2(0, .5);
    for(int i = 0; i<7; i++){
        if(n == 5.) break;
        hDots = min(hDots, length(pL - v0));
        v0 = rot2(PI*2./float(n))*v0;
    }
    // Combining with the pentagon dots. 
    hDots = min(hDots, pDots);
    
     
    // Outer shape borders with some white dots over the top for dotted lines.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, abs(d.x) - .01)));
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, hDots - .15)));

 
    // Rendering the outer borders.
    //col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.x + .09 - .035))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, d.x + .09)));
    col = mix(col, lCol, (1. - smoothstep(0., sf, d.x + .09 + .05)));
  
    // Rendering the outer dots.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, hDots - .04));
    // Rings.
    //col = mix(col, vec3(0), 1. - smoothstep(0., sf, abs(hDots - .04) - .02));
   
     
    #ifdef SHOW_GRID
    // Grid to show individual tiles.
    float grid = gridField(p);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid - .025))*.9);
    col = mix(col, vec3(1), (1. - smoothstep(0., sf, grid)));
    #endif

    // Output to screen
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
