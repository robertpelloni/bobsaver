#version 420

// original https://www.shadertoy.com/view/stt3Dr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    MultiScale Truchet [learning]
    11/6/21 @byt3_m3chanic

    https://christophercarlson.com/portfolio/multi-scale-truchet-patterns/
    
    My original attempt at this >> https://www.shadertoy.com/view/fl33zn 

    I had some gaps I couldn't figure out so I turned to @Shane's example 
    to understand how to create layered trickery required for this. 
    
    @Shane >> Quadtree Truchet ::  https://www.shadertoy.com/view/4t3BW4

    As the pattern scales down the colors alternate, add in that each 
    tile can have "wings" that overlap to create the solid positive
    and negative spaces around the scaling neighbors.
    
    I added an extra depth dimension to the quadtree and figured out
    how to layer that in (i think?). I kept the patterns mostly simple
    just to figure things out.

    You should also look at this to get an idea of quadtrees in general.
    @Shane >> Random Quadtree  ::  https://www.shadertoy.com/view/llcBD7

*/

#define R          resolution
#define M          mouse*resolution.xy
#define T          time
#define PI         3.14159265359
#define PI2        6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }

// @Shane 2/2 hash.
vec2 hash22(vec2 p) { 
    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(57, 27)));
    return fract(vec2(262144, 32768)*n);
}

float bkptrn(vec2 p, float res) {
    p *= res/10.;
    vec2 id = floor(p*.5)-.5;
    float hatch = clamp(sin((p.x - p.y)*PI*3.)*3. + 0.25, 0., 1.);
    return clamp(hatch,.3,.7);
}

void main(void) {

    vec2 uv = (2.*gl_FragCoord.xy.xy-R.xy)/max(R.x,R.y);
    vec2 suv = uv;

    uv += T*.040; 

    // change scale if window is bigger?
    // for pattern things you can get a
    // better - detailed view
    vec2 vuv= R.x>1000.?uv*4.:R.x>800.?uv*6.:uv*2.;
  
    float px = fwidth(vuv.x*2.);

    // threshold values
    const vec2 rndX[4]=vec2[4]( vec2(.5, .25), vec2(.5, .25), vec2(.5, .75), vec2(.5, 1));
    // Distance field values.
    vec4 d=vec4(1e5), d2=vec4(1e5), d3=vec4(1e5);
    float level=1.;
         
    // Main loop and neighbor checking from @Shane's shader.
    // Comments are reduced to the main points I wanted to
    // remember - please see his shader for full comments and
    // explanations https://www.shadertoy.com/view/4t3BW4
        
    for(int k=0; k<4; k++){
    
        vec2 id = floor(vuv*level);

        for(int j=-1; j<=1; j++){
            for(int i=-1; i<=1; i++){

                // neighboring cell ID.
                vec2 neighbors = vec2(i,j);
                vec2 rnd = hash22(id+neighbors);
                
                // tiles need to be laid down from largest to smallest. 
                // If a large tile has taken up the space, you need to
                // check on the next iterations and skip.
                
                vec2 rnd2 = hash22(floor((id+neighbors)/2.));
                vec2 rnd4 = hash22(floor((id+neighbors)/4.));
                vec2 rnd8 = hash22(floor((id+neighbors)/8.));
                
                // If the previous large tile has been rendered, continue.
                if(k==1 && rnd2.y<rndX[0].y) continue;
                // If any of the two previous larger tiles have been rendered, continue.
                if(k==2 && (rnd2.y<rndX[1].y || rnd4.y<rndX[0].y)) continue;
                // If any of the three previous larger tiles have been rendered, continue.
                if(k==3 && (rnd2.y<rndX[2].y || rnd4.y<rndX[1].y  || rnd8.y<rndX[0].y )) continue;

                // threshold
                if(rnd.y<rndX[k].y) {

                    vec2 p = vuv -(id+.5+neighbors)/level;
                   
                    // square to mask off tiles.
                    float square = max(abs(p.x), abs(p.y)) - .5/level;

                    // TILE COLOR ONE.
                    // Standard Truchet rotation and flipping.
                    if(rnd.x<rndX[k].x) p.xy = p.yx;
                    if(fract(rnd.x*57.5 + .35)<rndX[k].x) p.x = -p.x;
                    
                    // Four circles on the midway points of the grid boundary
                    vec2 p2 = abs(vec2(p.y - p.x, p.x + p.y)*.7071) - vec2(.5, .5)*.7071/level;
                    float c3 = length(p2) - .5/3./level;
  
                    // Truchet arc one.
                    float c = abs(length(p - vec2(-.5, .5)/level) - .5/level) - .5/3./level;
                    float c2 = abs(length(p - vec2(.5, -.5)/level) - .5/level) - .5/3./level;
          
                    // Line variant @Shane
                    if(fract(rnd.x*113.467 + .51)<.15) c = abs(p.x) - .5/3./level;
                    if(fract(rnd.x*123.853 + .49)<.15) c2 = abs(p.y) - .5/3./level;

                    float truchet = min(c, c2);

                    c = min(c3, max(square, truchet));
                    // Tile color one.
                    d[k] = min(d[k], c);
                    // for extra decoration
                    d3[k] = min(d3[k], c);

                    // TILE COLOR TWO.
                    p = abs(p) - .5/level;
                    float l = length(p);
                    
                    // Four circles at the grid vertices and the square.
                    c = min(l - 1./3./level, square);
                    //c = max(c, -truchet);
                    //c = max(c, -c3);
                    
                    // Tile color two.
                    d2[k] = min(d2[k], c); 

                }
            }
        }    
        
        level*=2.;
    }
    
    // layerd mixdown as each iteration is stored in xyzw
    d.x = max(d2.x, -d.x);

    float dz = abs(abs(abs(min(d3.w,d3.z))-.05)-.02)-.01;
    d.x = min(max(d.x, -d2.y),  d.y);
    d.x = max(min(d.x,  d2.z), -d.z);
    d.x = min(max(d.x, -d2.w),  d.w);
    // reuse of d.w - making border
    d.w=abs(d.x)-.0025;

    float dm = smoothstep(px, -px,d.x);
    float dn = smoothstep(-px, px,d.x);
    dz = smoothstep(px, -px, abs(dz)-.0025);

    float ptrn = max(dn,bkptrn(vuv,125.));
    vec3 C = mix(vec3(.045),vec3(.6),clamp((suv.y+.25)*.5,0.,1.))*ptrn;
    
    // color gradient 
    vec3 clrA = mix(vec3(0.902,0.380,0.098),vec3(0.137,0.580,0.804),clamp((suv.y+.45)*1.25,0.,1.));
    vec3 clrB = vec3(0.706,0.659,0.941);
    vec3 clrC = vec3(0.031,0.541,0.608);

    // extra decoration
    C = mix(C, clrA, clamp(dz-dm,0.,1.));
    C = mix(C, clrC, smoothstep(px, -px, abs(d.y+.075)-.002));
    // background
    C = mix(C, C*clrA, smoothstep(.05+px, -px, d.x));
    // outlines
    C = mix(C, clrB, smoothstep(px, -px, d.w));

    // Gamma and output
    C = pow(C, vec3(.4545));        
    glFragColor = vec4(C,1.0);
}

