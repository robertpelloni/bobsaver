#version 420

// original https://www.shadertoy.com/view/sltGzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    Log Polar Multiscale Truchet [learning]
    11/7/21 @byt3_m3chanic

    https://christophercarlson.com/portfolio/multi-scale-truchet-patterns/
    
    My original multiscale >> https://www.shadertoy.com/view/stt3Dr 

    So now I've reworked how the tiles are split mathematically and by
    loop over random hash value. Also with the help of @mla the hash22
    makes the tiles seamless in the log polar transform.
    
    Mouse down to see the grid lines.
    
    The original truchet work which was based off of
    @Shane >> Quadtree Truchet ::  https://www.shadertoy.com/view/4t3BW4

    Then mla showed me how to make the ends match and put it into a log polar
    @mla   >> Multiscale Truchet + Log Polar :: https://www.shadertoy.com/view/fttGzB

*/

#define R          resolution
#define M          mouse*resolution.xy
#define T          time
#define PI         3.14159265359
#define PI2        6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }

const float N = 4.;
// @Shane 2/2 hash.
vec2 hash22(vec2 p) { 
    p.y = mod(p.y,2.*N);//@mla : shifting the y value from the range [-PI,+PI] to [0,2N]
    float n = sin(dot(p, vec2(57, 27)));
    return fract(vec2(262144, 32768)*n);
}

float bkptrn(vec2 p, float res) {
    p *= res/10.;
    float hatch = clamp(sin((p.x - p.y)*PI*3.)*1. + 1.25, 0., 1.);
    hatch = min(hatch,clamp(sin((p.x + p.y)*PI*3.)*1. + 1.25, 0., 1.));
    return clamp(hatch,.4,.5);
}

//@mla
vec2 clog(vec2 z) {
  float r = length(z);
  return vec2(log(r),atan(z.y,z.x));
}

void main(void) {

    vec2 uv = (2.*gl_FragCoord.xy.xy-R.xy)/max(R.x,R.y);
    vec2 suv = uv;
    suv*=rot(.3);
    vec2 vuv = uv-vec2(.3535,0);
    if(uv.x>-.3) {
        vuv = clog(vuv);
        vuv /= 3.14159;
        vuv *= N;
        vuv.x -= 0.3*T;
    }else{
        vuv *= N;
        vuv.x += 0.3*T;
    }
    
    
    float px = fwidth(vuv.x);

    // Distance field values.
    vec4 d=vec4(1e5), d2=vec4(1e5), d3=vec4(1e5), d4=vec4(1e5), grid = vec4(1e5);
    float level=1.;
         
    // Main loop and neighbor checking from @Shane's shader.
    // Ssee his shader for full comments and explanations.
    // https://www.shadertoy.com/view/4t3BW4
        
    for(int k=0; k<4; k++){
    
        vec2 id = floor(vuv*level);

        for(int j=-1; j<=1; j++){
            for(int i=-1; i<=1; i++){

                // neighboring cell ID.
                vec2 neighbors = vec2(i,j);
                vec2 home = id+neighbors;
                vec2 rnd = hash22(home);

                // So we're using a checkered function based on
                // the floor size much in the same way @Shane
                // was using the hash22 to split areas - this is
                // more calculated than hash random.
                vec2 hmd2 = (floor(home/2.));
                vec2 hmd4 = (floor(home/4.));
                vec2 hmd8 = (floor(home/8.));
                
                float chk  = mod(home.y+home.x,2.)*2.-1.;
                float chk2 = mod(hmd2.y+hmd2.x,2.)*2.-1.;
                float chk4 = mod(hmd4.y+hmd4.x,2.)*2.-1.;
                float chk8 = mod(hmd8.y+hmd8.x,2.)*2.-1.;

                if(k>0 && chk2<.5) continue;
                // threshold
                if(k==0||k==1&&chk2>.5||k==2&&chk4>.5&&chk2>.5||k==3&&chk4>.5&&chk8>.5) {

                    vec2 p = vuv -(id+.5+neighbors)/level;
                   
                    // square to mask off tiles.
                    float square = max(abs(p.x), abs(p.y)) - .5/level;

                    // The grid lines.
                    grid.x = min(grid.x, abs(square)-.0025/2.);

                    // TILE COLOR ONE.
                    // Standard Truchet rotation and flipping.
                    if(rnd.x<.5) p.xy = p.yx;
                    if(fract(rnd.x*57.5 + .35)<.5) p.x = -p.x;

                    // Four circles on the midway points of the grid boundary
                    vec2 p2 = abs(vec2(p.y - p.x, p.x + p.y)*.7071) - vec2(.5, .5)*.7071/level;
                    float c3 = length(p2) - .5/3./level;
  
                    // Truchet arc one.
                    float c = abs(length(p - vec2(-.5, .5)/level) - .5/level) - .5/3./level;
 
                    // Truchet arc two.
                    float c2;
                    if(fract(rnd.x*157.763 + .49)>.15){
                        c2 = abs(length(p - vec2(.5, -.5)/level) - .5/level) - .5/3./level;
                    }
                    else{  
                        c2 = length(p -  vec2(.5, 0)/level) - .5/3./level;
                        c2 = min(c2, length(p -  vec2(0, -.5)/level) - .5/3./level);
                    }
                    
                    // Line variant @Shane
                    if(fract(rnd.x*113.467 + .51)<.15) c = abs(p.x) - .5/3./level;
                    if(fract(rnd.x*123.853 + .49)<.15) c2 = abs(p.y) - .5/3./level;

                    float truchet = min(c, c2);

                    c = min(c3, max(square, truchet));
                    // Tile color one.
                    d[k] = min(d[k], c);

                    // TILE COLOR TWO.
                    p = abs(p) - .5/level;
                    float l = length(p);
                    
                    // Four circles at the grid vertices and the square.
                    c = min(l - 1./3./level, square);
                    if(chk>.5) d3[k] = min(d3[k], l - 1./3./level); 
                    c = max(c, -truchet);
                    c = max(c, -c3);
                    
                    // Tile color two.
                    d2[k] = min(d2[k], c); 

                }
            }
        }    
        
        level*=2.;
    }
    
    // layerd mixdown as each iteration is stored in xyzw
    d.x = max(d2.x, -d.x);
    d.x = min(max(d.x, -d2.y),  d.y);
    d.x = max(min(d.x,  d2.z), -d.z);
    d.x = min(max(d.x, -d2.w),  d.w);

    //d3.x = max(d2.x, -d.x);
    d3.x = min(d3.x, d3.y);
    d3.x = max(d3.x, -d3.z);
    d3.x = min(d3.x, d3.w);
    
    float dm = smoothstep(px, -px,d.x);
    float dn = smoothstep(-px, px,d.x);
    float ptrn = max(dm,bkptrn(vuv,128.));
    vec3 C = mix(vec3(.075),vec3(.2),clamp((suv.y+.25)*.5,0.,1.))*ptrn;
    
    // color gradient 
    vec3 clrA = mix(vec3(0.918,0.769,0.565),vec3(0.886,0.408,0.012),clamp(abs(suv.y*2.),0.,1.));

    vec3 clrB = vec3(0.106,0.102,0.075);

    C = mix(C, C*clrB, smoothstep(.05+px, -px, d.x));    
    //C = mix(C, clamp(C+texture(iChannel1,vuv*2.).rrr*.05,vec3(0),vec3(1)),dn);
    C = mix(C, C*clrB, smoothstep(px, -px, abs(abs(abs(d3.x)-.03)-.015)-.0015 ));
    //C = mix(C, texture(iChannel0,vuv).rgb*vec3(0.733,0.447,0.047),clamp(dm,0.,1.));
  
    C = mix(C, clrA, smoothstep(px, -px, abs(d.x)-.0015));
    
    //if(mouse*resolution.xy.z>0.){
    //    C = mix(C, clrB, 1. - smoothstep(-px, px, grid.x - .001));
    //    C = mix(C, vec3(.9), 1. - smoothstep(-px, px, grid.x));
    //}
    
    if(uv.x<-.3&&uv.x>-.305) C = vec3(.05);
 
    // Gamma and output
    C = pow(C, vec3(.4545));        
    glFragColor = vec4(C,1.0);
}

