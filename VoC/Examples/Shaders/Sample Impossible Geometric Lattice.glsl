#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wd3XRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Impossible Geometric  Lattice
    -----------------------------

    Using a triangular grid to construct a randomly connected impossible 
    geometric lattice.

    One of my favorite pastimes is looking at a standard repeat pattern
    on the net, then trying to figure out how to reconstruct it -- We all
    need our hobbies, right? :D Sometimes, I'll get lucky and figure it
    out right away. Other times, I'll try for ages getting nowhere, then 
    have to quit. However, if I'm patient enough, someone on Shadertoy
    will eventually do it. :D

    Thankfully, the trick behind the impossible geometric lattice pattern 
    came to me quickly. On the down side, I'd already produced it on a 
    diamond grid before realizing that a triangle grid version would allow 
    for a much more elegant construction.

    As mentioned above, this is an example of impossible geometry -- The 
    connections you're seeing wouldn't be possible in the real world, which 
    can mess with your sense of perception, but that's half the appeal.

    The imagery was rendered in a psuedo pencil drawing style using 2D 
    techniques. Like the geometry itself, the lighting, shadows, etc,
    are a mixture of real world calculations and ones that don't really
    add up, so as when watching movies, a certain suspension of belief is
    necessary.

    If you just wanted a simple connecting lattice, you could set up a
    triangle grid, then render one cube face and connecting tube at each
    of the three triangle vertex points, and you'd be done. Essentially,
    that's all I've done here. However, I got a little carried away 
    prettying it up, addind settings, etc, so this is a little longer. 
    Having said that, it's still not what I'd describe as a long example.

    Other Impossible Geometry Examples:

    // Fabrice has covered everything at one point or another. :)
    impossible triangle (224 ch) -  FabriceNeyret2
    https://www.shadertoy.com/view/XtyfDc

    // Beatiful example: There are some things you can't really achieve
    // with 2D overlays.
    Penrose Pathtraced - yx
    https://www.shadertoy.com/view/ttXGWr

*/

// A regular equilateral scaling, which is just a special form of isosceles.
#define EQUILATERAL

// Adding in some noise. Comment it out for a smoother, cleaner look.
#define NOISE_TEX

// Turn the hatching on or off. I prefer it, but others might like a 
// cleaner, smoother, look.
#define DO_HATCH

// Flat shading. It looks cleaner, probably looks a little more natural, 
// but I wanted vibrancy, for this particular example.
//#define FLAT_SHADING

// A hacky glass tube effect. Putting in more effect to render glass cubes
// would be cool, but that would require more writing. :D
//#define GLASS    

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.687, 57.583)))*43758.5453); }

// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values.
float n2D(vec2 p) {

    vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
    
    return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }

// A hatch-like algorithm, or a stipple... or some kind of textured pattern.
float doHatch(vec2 p, float res){
    
    
    // The pattern is physically based, so needs to factor in screen resolution.
    p *= res/16.;

    // Random looking diagonal hatch lines.
    float hatch = clamp(sin((p.x - p.y)*3.14159*200.)*2. + .5, 0., 1.); // Diagonal lines.

    // Slight randomization of the diagonal lines, but the trick is to do it with
    // tiny squares instead of pixels.
    float hRnd = hash21(floor(p*6.) + .73);
    if(hRnd>.66) hatch = hRnd;  

    return hatch;
    
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

// Entirely based on IQ's signed distance to a 2D triangle -- Very handy.
// I have a generalized version somewhere that's a little more succinct,
// so I'll track that down and drop it in later.
float quad(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2, in vec2 p3){

    vec2 e0 = p1 - p0;
    vec2 e1 = p2 - p1;
    vec2 e2 = p3 - p2;
    vec2 e3 = p0 - p3;

    vec2 v0 = p - p0;
    vec2 v1 = p - p1;
    vec2 v2 = p - p2;
    vec2 v3 = p - p3;

    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    vec2 pq3 = v3 - e3*clamp( dot(v3,e3)/dot(e3,e3), 0.0, 1.0 );
    
    float s = sign( e0.x*e3.y - e0.y*e3.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
    
    d = min(d, vec2( dot( pq3, pq3 ), s*(v3.x*e3.y-v3.y*e3.x)));

    return -sqrt(d.x)*sign(d.y);
}

// Signed distance to a regular hexagon -- using IQ's more exact method.
float sdHex(in vec2 p, in float r){
    
  const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.

  // X and Y reflection.
  p = abs(p);
  p -= 2.*min(dot(k.xy, p), 0.)*k.xy;
    
  // Polygon side.
  return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r);
    
}

// 
float shade(vec2 p, float shd){
    
    #ifdef FLAT_SHADING
    return shd*shd + .35;
    #else
    
    //float lgt = max(1.3 - length(p), 0.);
    //return pow(lgt, 4.)*shd*shd + .2;
   
    shd *= max(1.3 - length(p), 0.);
    return pow(shd, 4.) + .15;
    #endif
}

float shade2(vec2 p, float shd){
    
    #ifdef FLAT_SHADING
    return pow(shd, 4.) + .35;
    #else
    //float lgt = max(1.35 - length(p), 0.);
    //return pow(lgt, 4.)*shd*shd + .25;
   
    shd *= max(1.35 - length(p), 0.);
    return pow(shd, 4.) + .15;
    #endif
}

// The scaling vector. Basically, it determines the height to width ratio.
//
#ifdef EQUILATERAL
// An equilateral scaling, which is just a special kind of isosceles.
const vec2 s = vec2(1, .8660254); //1./.8660254
#else
// I wanted to show that this example would work with other scales too, even 
// if they don't look particularly great. :)
const vec2 s = vec2(1.3, 1)*.84; 
// One to one scaling -- which would effectively make the scaling redundant.
//const vec2 s = vec2(1); 
#endif

vec4 getTri(vec2 p, inout float itri){
    
    // Scaling the cordinates down, which makes them easier to work with. You scale 
    // them back up, after the calculations are done.
    p /= s;
    
    // Triangles pack a grid nicely, but unfortunately, if you want vertices to 
    // match up, each alternate row needs to be shifted along by half the base 
    // width. The following vector will help effect that.
    float ys = mod(floor(p.y), 2.)*.5;
    vec4 ipY = vec4(ys, 0, ys + .5, 0);
    
    // Two triangles pack into each square cell, and each triangle uses the bottom 
    // left point as it's unique identifier. The two points are stored here.
    vec4 ip4 = floor(p.xyxy + ipY) - ipY + .5; 
    
    // The local coordinates of the two triangles are stored here.
    vec4 p4 = fract(p.xyxy - ipY) - .5;
    
    // Which isoso... I always struggle to spell it... isosceles triangle
    // are we in? Right way up, or upside down. By the way, if you're wondering
    // where the following arises from, "abs(x) + abs(y) - c" partitions 
    // a square and "abs(x) + y - c" partitions a triangle.
    float i = (abs(p4.x)*2. + p4.y<.5)? 1. : -1.;
    
    itri = i;
    
    // Depending on which triangle we're in, return a vector containing the local 
    // coordinates in the first two spots, and the unique position-based identifying 
    // number in the latter two spots. These two positions would be all you'd need
    // to render a colored triangle grid. However, when combined with the triangle 
    // orientation and vertices (above), you can render more interesting things.
    p4 = i>0.? vec4(p4.xy*s, ip4.xy) : vec4(p4.zw*s, ip4.zw);  
    
    return p4;
    
}

vec3 triLattice(vec2 q, float sf, vec2 uv, float iRes){    
 
    // The relative vertice positions. You could hardcode these into the formulae 
    // below, but if you're performing various edge arithmetic, etc, they're handy 
    // to keep around.
    vec2 v0 = vec2(-.5), v1 = vec2(0, .5), v2 = vec2(.5, -.5);
    vec2 v0Sh = v0, v1Sh = v1, v2Sh = v2;

    // Keeping a copy of the original coordinate.
    vec2 oP = q;
    
    // Rotating the entire grid, according to the grid dimensions. Basically, this
    // just orients the camera to an isometric view that's easier on the eyes.
    // // "q *= r(a)"works too, but apparently not all cards like it. Typical. :)
    q = rot2(-atan(s.x/s.y/2.))*q; 

    
    // The shadowed triangle grid, IDs, physical positions, etc.
    float itriSh;
    vec4 p4Sh = getTri(q - vec2(.12, -.12), itriSh);
    vec2 pSh = p4Sh.xy; // Local coordinates.
    vec2 ipSh = p4Sh.zw; // Triangle ID.
    if(itriSh>0.) { vec2 tmp = v0Sh; v0Sh = v2Sh; v2Sh = tmp; }

    vec2[3] vIDSh = vec2[3](v0Sh*itriSh, v1Sh*itriSh, v2Sh*itriSh);
    vec2[3] vVSh = vec2[3](vIDSh[0]*s, vIDSh[1]*s, vIDSh[2]*s);
    vec2[3] eIDSh = vec2[3](mix(vIDSh[0], vIDSh[1], .5), mix(vIDSh[1], vIDSh[2], .5), mix(vIDSh[2], vIDSh[0], .5));
    
    // The main triangle grid, IDs, physical positions, etc. All this is explained in my
    // triangle jigsaw example on this site, if you feel like looking for it.
    float itri;
    vec4 p4 = getTri(q, itri);
     // Making a copy of the triangle's local coordinates and ID. It's not particularly
    // necessary, but saves a bit of extra writing and confusion.
    vec2 p = p4.xy; // Local coordinates.
    vec2 ip = p4.zw; // Triangle ID.
    // Arranging for the vertices of complimentary triangle set to line up.
    if(itri>0.) { vec2 tmp = v0; v0 = v2; v2 = tmp; }
    
    
    // The unscaled triangle vertices, which double as an ID: Note that the vertices of
    // alternate triangles are flipped in a such a way that edge neighboring edge vertices
    // match up.
    vec2[3] vID = vec2[3](v0*itri, v1*itri, v2*itri);
    // Edge IDs, based on the vertex IDs above. The mid points of neighboring triangles
    // occur in the same position, which means both triangles will generate the same
    // unique random number at that position. This is handy for all kinds of things.
    vec2[3] eID = vec2[3](mix(vID[0], vID[1], .5), mix(vID[1], vID[2], .5), mix(vID[2], vID[0], .5));
    // Scaled vertices -- It's not absolutely necessary to have these, but when doing more
    // complicated things, I like to swith between the unscaled IDs and the physical scaled
    // vertices themselves.
    vec2[3] vV = vec2[3](vID[0]*s, vID[1]*s, vID[2]*s);
    // Scaled mid-edge vertices.
    vec2[3] vE = vec2[3](eID[0]*s, eID[1]*s, eID[2]*s);

    
    const float cw = .45; // The cube face dimension. ".5" would be the maximum.
    const float lw = .175; // The connecting tube face dimension.
    float spc = (cw - lw)/1.732; // The diagonal distance to center the tube.
    const float ew = .01; // Edge width.
    
    const float thresh = .57; // Join threshold.
    const float thresh2 = .57; // Threshold for cubes without holes.
    
    
    
    // Individual cube face and connecting tube face shades. These have been tailored
    // to suit the example.
    vec3 sh = vec3(1, .65, .25);
    vec3 sh2 = vec3(.5, .15, 1.2);
   
    // Triangles can be tricky. Alternating triangles need the shades shifted around.
    // I was feeling lazy, so I got these through trial and error. The top cube face
    // needed to be lighter, and so forth.
    if(itri<0.) { sh = sh.yxz; sh2 = sh2.zyx; }
    
    
    // The scene color, initialized to a simple background gradient.
    vec3 col = mix(vec3(.7, .85, 1)/1.25, vec3(1, .7, .4)*.8, -uv.y + .5);

    #ifdef GLASS
    // Darken the background for the glass setting. Yeah, it needs more effort. :)
    col *= .75;
    #endif    
    
    #ifdef NOISE_TEX
    // The subtle noise texture.
    float ns = fbm(oP*32.*max(iRes/450., 1.));
    vec3 tx = mix(vec3(1, .8, .7), vec3(.05, .1, .15), ns);
    tx = smoothstep(-.25, .55, tx);    
    col *= tx;
    #endif
    
    // Render connecting tube links and there shadows, or not.
    vec3 drawLink = vec3(0);
    vec3 drawLinkSh = vec3(0.);

    
    // An impossible geometric lattice with all the links in tact looks interesting,
    // but I don't feel it looks as interesting as the one with random links. Rendering
    // links randomly is simple enough (just compare the random shared edge value 
    // against a threshold), but you wind up with floating cubes. If you're OK with that,
    // then the following isn't necessary. If it bothers you, like it did me, then you
    // have to check for empty neighboring links, and either, omit the cube, or put a
    // link in, which is what is happening here.
  
    for(int i = 0; i<3; i++){
    
        // Random number from the shared edge ID.
        float rndI = hash21(ip + eID[i]);
        // If it's below the threshold, flag the index of the link drawing vector.
        if(rndI<thresh) drawLink[i]++;
      
        // Check for floating cubes:
        //
        // At the end of the final iteration, if no links have been rendered
        // to the cube, add one in. I'm not happy with this logic, but it
        // seems to work, so I'll leave it as is, for now.
        if(i == 2){
            int lCnt2 = 0;
            if(hash21(ip + eID[(i + 0)%3])<thresh) lCnt2++;
            if(hash21(ip + eID[(i + 2)%3])<thresh) lCnt2++;
            if(hash21(ip + eID[(i + 0)%3]*2. + eID[(i + 2)%3])<thresh) lCnt2++;
            if(hash21(ip + eID[(i + 2)%3]*2. + eID[(i + 4)%3])<thresh) lCnt2++;
            if(lCnt2==0) drawLink[i]++;
        }
        
        // Do the same with the shadow links. I'd hoped to use the variables above.
        // Unfortunately, however, shadows need to be calculated seperately.
        rndI = hash21(ipSh + eIDSh[i]);
        if(rndI<thresh){
            drawLinkSh[i]++;
        }
        
        // Check for floating shadow cubes.
        if(i == 2){
            int lCnt2 = 0;
            if(hash21(ipSh + eIDSh[(i + 0)%3])<thresh) lCnt2++;
            if(hash21(ipSh + eIDSh[(i + 2)%3])<thresh) lCnt2++;
            if(hash21(ipSh + eIDSh[(i + 0)%3]*2. + eIDSh[(i + 2)%3])<thresh) lCnt2++;
            if(hash21(ipSh + eIDSh[(i + 2)%3]*2. + eIDSh[(i + 4)%3])<thresh) lCnt2++;
           if(i==2 && lCnt2==0) drawLinkSh[i]++;
        }

    }
   

    // Render the shadows first. Something I get wrong all the time is trying to
    // render the shadows layer upon layer. You have to take the overal minimum then
    // render the entier shadow to the background... or on top of objects that are
    // between the light and the background... And that's why I find it easier just
    // to render things in 3D. :)
    float dSh = 1e5;
    for(int i = 0; i<3; i++){
    
        // Cube shadows. Just hexigons at each vertice. Quadrilateral cube faces
        // would also work, but this does the same thing, and is easier.
        dSh = min(dSh, sdHex(pSh - vVSh[i], cw));
        
        // If applicable, render the link shadow, which is just a box 
        // between vertices.
        if(drawLinkSh[i]>.5){
            dSh = min(dSh, lBox(pSh, vVSh[i], vVSh[(i + 1)%3], lw));
        }
         
    }
    

    // Apply the background shadow.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., dSh + .08))*.7);
    
    
    // With the shadow done, it's time to render the boxes (with or without holes),
    // and the connecting tubes.
     
    for(int i = 0; i<3; i++){

        // Normal vectors. There are used to obtain the vertices of the
        // quadrilateral cube faces.
        vec2 n0 = normalize(vV[(i)%3] - vV[(i + 1)%3]);
        vec2 n1 = normalize(vV[(i + 1)%3] - vV[(i + 2)%3]);
        vec2 n2 = normalize(vV[(i + 2)%3] - vV[(i)%3]);

        // Clockwise.
        vec2 v0 = vV[(i)%3];
        vec2 v1 = v0 + n1*cw;
        vec2 v2 = v1 + n2*cw;
        vec2 v3 = v2 - n1*cw;
        float d = quad(p, v0, v1, v2, v3);

        
        float side2 = length(vV[(i)%3] - vV[(i + 1)%3]);
        v0 = vV[(i)%3] - n0*spc;
        v1 = v0 + n2*lw;
        v2 = v1 - n0*(side2 - spc - cw);
        v3 = v2 - n2*lw;
        float d2 = quad(p, v0, v1, v2, v3);
        
        // The cube hole.
        float dH = max(d2, d);
        
        
        // Make a hole in the cube, or not. You could put holes on
        // all cubes, if you wanted, but I thought this added a bit
        // more visual interest.
        float cbRnd = hash21(ip + vID[i] + .1);
        if(drawLink[i]>.5 || cbRnd<thresh2) {
            // Cube hole, on all link faces, and on
            // random cubes as well.
            v0 = vV[(i)%3] - n0*spc;
            v1 = v0 + n2*lw;
            v2 = v1 + n1*lw;
            v3 = v2 - n2*lw;
            d = max(d, -quad(p, v0, v1, v2, v3));
        }
        
        
        
        // The shading formula. Fake, of course. Basically, we're just manipulating the
        // distance field itself, and hoping it looks kind of right. :) The more correct
        // part of the lighting simply comes from giving the top cube face a light shade,
        // the left a middle range shade, and the right a dark one.
        float vSh = shade(p.xy - (vV[i] + s.yx*vec2(-1, 1)*.05), sh[i]);
        
        
  
        // Using the random vertex ID to give the cubes (which share a common triangle
        // vertex) a random color.
        float rnd = hash21((ip + vID[i])*s);
        // Tweaking IQ's elegant underutilized one line palette formula to produce some subtle 
        // reddish earth tones. By the way, it's worth knowing the formula by heart, because it's
        // so useful. In fact, if there's a cleverer more versatile formula than this, then I'm 
        // yet to see it. A close second would be the following: 
        // c = pow(vec3(a, b, c)*grey, vec3(d, e, f));
        vec3 tCol = .5 + .45*cos(6.2831*mix(0., .3, rnd) + vec3(0, 1, 2)/1.5);
        tCol = mix(vec3(1, .4, .25), tCol, .5);

        #ifdef NOISE_TEX
        tCol *= tx;
        #endif

        vec3 svCol = col;
              
        // If applicable, render an inner box.
        if(drawLink[i]>.5 ||  cbRnd<thresh2){

            float vSh2 = shade(p.xy - (vV[i] + s.yx*vec2(-1, 1)*.05), sh[(i + 2)%3]);
            // Fake AO.
            col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., dH))*.5);
            col = mix(col, vec3(0), (1. - smoothstep(0., sf, dH)));
            col = mix(col, mix((tCol + vec3(.6, .8, 1)*.5)*vSh2*vSh2, svCol, .5), 
                                 (1. - smoothstep(0., sf, dH + ew)));
           
            // Shadow cast on object.
            col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., max(dSh + .08, dH)))*.35);
         }   
               
        
        // Boxes --  We're actually rendering a diamond quadrilateral cube face at 
        // each vertex, but when joined together on a triangle grid, it looks like a 
        // repetitive cubes.
        //
        // Fake AO, border, color and shading.
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., d))*.5);
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, d)));
           col = mix(col, mix(tCol*vSh, svCol, 0.), (1. - smoothstep(0., sf, d + ew)));
        // Shadow cast on the object -- The physics are nonsensical, but no one will check. :)
        col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., max(dSh + .08, d)))*.35);
       
        
        // Connecting tube links.
        
        // Brightening up the left verticle tube link a bit. There's no science behind this --
        // I just thought it looked a little better.
        //if(itri>0.) vSh[0] *= 2.;
        if(itri>0.) sh2[0] = mix(sh2[0], sh2[2], .55);
        
        if(drawLink[i]>.5){
          
            // The science behind the lighting here is pretty simple. Basically, I shifted
            // the position around to various places until it looked like it might be scientifically
            // correct... Then, when I didn't like how that looked, I moved it around until I
            // thought it looked pretty. :D
            //vSh = doShade(p.xy - mix(vE[(i + 1)%3], vV[i], .8), vSh);
            vSh = shade2(p.xy - (mix(vE[(i + 1)%3], vV[i], .25) - s.yx*vec2(-1, 1)*.15), sh2[i]);
            
            vec3 lCol = vec3(.6, .8, 1);
            #ifdef NOISE_TEX
            // Add a little noise to the tubes.
            lCol *= tx*.75 + .25;
            #endif
            
            // The tubes are slightly transparent, to I've saved the background to mix
            // with it. Normally, I wouldn't have to, but the dark edges are just a slightly
            // larger black tube, with the colored tube over the top. I could use the "abs"
            // trick, but sometimes, it doesn't quite work.
            svCol = col;
         
            // Fake AO -- Technically, this encroaches a little onto the sides of the
            // cube, but it's barely noticeable... to most, but there's always one :D
            col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., d2 + ew))*.5); 
            // Edges.
            col = mix(col, vec3(0), (1. - smoothstep(0., sf, d2)));
            #ifdef GLASS
            // Glowing glass tubes.
               col = mix(col, mix(lCol*vSh, svCol, .9)*vec3(1.5, 2.3, 3.4), 
                     (1. - smoothstep(0., sf, d2 + ew)));
            #else
            // Transparent... hard plastic tubes? Either way, they'll do.
               col = mix(col, mix(lCol*vSh, svCol, .5), (1. - smoothstep(0., sf, d2 + ew)));
            #endif
          
            // Shadow object cast. Again, not realistic, but I doubt anyone will care. :)
            col = mix(col, vec3(0), (1. - smoothstep(0., sf*4., max(dSh + .08, d2)))*.35);
            
 
        }
 
    }
    

    return col;
}

void main(void) {
    

    // Restricting the fullscreen resolution.
    float iRes = min(resolution.y, 800.);
    // Aspect correct screen coordinates.
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/iRes;
    
    
    // Scaling and translation.
    float gSc = 4.5;
    // Depending on perspective; Moving the scene toward the bottom left, 
    // or the camera in the north east (top right) direction. 
    //
    // Warped version.
    //vec2 p = uv*(.95 + length(uv*vec2(resolution.y/resolution.x, 1))*.05)*gSc - vec2(-1, -.5)*time;
    vec2 p = (uv*gSc - vec2(-1, -.5)*time);
    
    // A nonwarped copy, for postprocessing purposes.
    vec2 oP = uv*gSc - vec2(-1, -.5)*time;
    
    
    // The smoothing factor.
    float sf = gSc/iRes;
    
    
    // The isosceles grid lattice object.
    vec3 col = triLattice(p, sf, uv, iRes);
    //vec3 col = triLattice(rot2(-3.14159/6.)*p, sf, uv, iRes);
     

    #ifdef DO_HATCH
    // A cheap hatch-like pattern, just to give it that extra oldschool look.
    float hatch = doHatch(oP/gSc, iRes);
    col *= hatch*.45 + .75;
    #endif
  
    
    // Spotlight color mixing.
    //col = mix(col, col.xzy, pow(dot(uv, uv), 1.5)*.35);
 
  
    
    // Applying a subtle silhouette, for art's sake.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./16.)*1.05; 
    
    // Rough gamma correction, then output to the screen.
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
