#version 420

// original https://www.shadertoy.com/view/sdGyDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Through the hive

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

//Inigo Quiles article "Simple color palettes" 
//https://iquilezles.org/articles/palettes/
#define pal(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) )

// Hash from "Hash without Sine" by Dave_Hoskins (https://www.shadertoy.com/view/4djSRW)
float hash11(in float x) {
    x = fract(x * 0.1031);
    x *= x + 33.33;
    x *= x + x;
    return fract(x);
}

vec2 hash22(vec2 p)
{
  vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
////////////////////////////////////////////

////////////////// HEXAGONAL VORONOI///////////////
//  This code, with minor modifications, is taken from Shane's 
//  "Round Voronoi Border Refinement". 
//  https://www.shadertoy.com/view/4sdcDN
//
//  Be sure to check out his excellent shader.
//  Shane is much better at explaining how his code works 
//  than I am, so I limited my comments to just my changes.
// 

/*

float smin2(float a, float b, float r)
{
   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}

vec2 pixToHex(vec2 p)
{
    return floor(vec2(p.x + .57735*p.y, 1.1547*p.y) + 1./3.);
}

vec2 hexPt(vec2 p, float T, float layer) 
{
    vec2 t = vec2(floor(T/5.)); // every five seconds the centers of the cells change their position,
                                // T is the phase offset from the global timer for a particular layer
    
    return mix (vec2(p.x - p.y*.5, .866025*p.y) + (hash22(p+t+layer) - .5)*.866025/2.  //current position
                ,vec2(p.x - p.y*.5, .866025*p.y) + (hash22(p+t+layer+1.) - .5)*.866025/2.  //next position
                ,smoothstep (0.,1.,mod(T,5.)));    //сhange positions in 1 seconds
}

float Voronoi(vec2 p, float min_fct, float T, float layer) 
{   
    vec2 pH = pixToHex(p);
    const vec2 hp[7] = vec2[7](vec2(-1), vec2(0, -1), vec2(-1, 0), vec2(0), vec2(1), vec2(1, 0), vec2(0, 1)); 
    vec2 minCellID = vec2(0);
    vec2 mo, o;
    
    float md = 8., lMd = 8., lMd2 = 8., lnDist, d;
    for (int i=0; i<7; i++)
    {
        vec2 h = hexPt(pH + hp[i], T, layer) - p;
        d = dot(h, h);
        if( d<md )
        {
            md = d;
            mo = h; 
            minCellID = hp[i];
        }
    }

    for (int i=0; i<7; i++)
    {
        vec2 h = hexPt(pH + hp[i] + minCellID, T, layer) - p - mo; 
        if(dot(h, h)>.01)
        {
            lnDist = dot(mo + h*.5, normalize(h));
            lMd = smin2(lMd, lnDist, min_fct);
        }
    }
    return lMd;
}
*/

// Code from Fabrice (thanks a lot)
// Smaller, faster and doesn't cause a weird bug that wasn't present on my main computer

#define H2(p)       fract( sin((p+9.)*mat2(127.1,311.7, 269.5,183.3)) *4e4 )
#define H1(p)       H2(vec2(p)).x

vec2 hexPt(vec2 p, float T, float l)  {
    vec2 t = p + floor(T/5.) + l;
    return p * mat2(1,-.5,0, .866)
           + ( mix( H2(t),  H2(t+1.),  smoothstep (0.,1.,mod(T,5.)) )
                -.5  ) * .433; 
}

float Voronoi(vec2 p, float M, float T, float l)  // --- Voronoi
{   
    vec2 pH = floor( p * mat2(1,.6,0,1) ), // pixToHex(p)
         mo, o, C, c,h;
    
    float m = 8., md = m, d, f;
    for (int i=0; i<9; i++)
        c = vec2(i%3,i/3)-1.,
        h = hexPt(pH + c, T, l) - p,
        d = dot(h, h),
        d < md ? md = d, mo = h, C = c : C;

    for (int i=0; i<9; i++)
        h = hexPt(pH + vec2(i%3,i/3)-1. + C, T, l) - p - mo,
        d = dot(mo + h*.5, normalize(h)),
        f = max(0., 1. - abs(d-m)/M )/2., // smin2
        m = min(m, d) - M*f*f;

    return m;
}

////////////////// HEXAGONAL VORONOI///////////////

void main(void)
{
	vec2 g = gl_FragCoord.xy;
    vec2 r = resolution.xy
        ,uv = (g+g-r)/r.y/2.
        ,xy;

    float   lcl = sin(time*.2) // zoom speed changing cycle
            ,tm = fract (time)     //  1-second timer between cycles
            ,cicle = time-tm       //  cycle number
            ,speed = 1.5+lcl*.25    //  zoom speed
            ,LAYERS =11.;            // num of layers 
    
    uv *= (1. - length(uv)*lcl*.5)  //  camera distortion
            /exp(tm*log(speed))     // camera zoom
            *(.3+lcl*.1);
    
    vec4 O = vec4(0.);

    float T, v, m, s;
    for (float i=LAYERS; i >= 0.; i--) //draw layers from the far side to the near side
    {
        T = time+hash11(cicle+i)*5.; //phase offset from the global timer for a particular layer
        xy = uv*pow(speed,i+1.) + vec2(sin(time),cos(time*2.))*.07; //local coordinates of the layer with a zoom and a small shift

        s = max(smoothstep(5.,0.,i-tm)*.01              // blur the closest layers
                    +(1. + sin(T*20.+xy.x*10.-xy.y*10.))     // and changing layers (with a shaking effect)
                    *(smoothstep (1.5,0.,mod(T,5.)))*.02   // in 1.5 seconds
                 , fwidth(xy.x));               // AA for far small layers

        v = Voronoi (xy+vec2(-.01,.01), .2, T, cicle+i); //voronoi with an offset to draw the highlighted edge
        m = 1. + smoothstep (.04-s,.05+s, v);                     //highlighted edge mask
        vec4 col =  pal((time*2.+i-tm)*.10,vec4(.5),vec4(.4),vec4(1.),vec4(.1,.2,.3,1)) //layer color
                    * smoothstep(LAYERS,3.,i-tm)        // darken the farthest layers
                    * m;      

        v = Voronoi (xy, .2, T, cicle+i); //   voronoi for current layer
        m = smoothstep (.3,.07+sin(T*5.)*.05, v) // layer shadow mask
            *(1. - tm*step(i,0.));                  // make the closest layer shadow transparent at the end of the cycle
        O *= 1. - m*.7;    //draw layer shadow

        m = smoothstep (.05+s,.04-s, v)   //  layer mask
            *(1. - tm*step(i,0.));          //  make the closest layer shadow transparent too 
        O = mix (O,col,m); //draw layer
    }
	glFragColor=O;
}
