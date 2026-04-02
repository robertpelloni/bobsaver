#version 420

// original https://www.shadertoy.com/view/3lc3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Infinite Cube Zoom
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  http://www.iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define PI 3.1415926
#define hash1( n ) fract(sin(n)*43758.5453)
#define hue(v) ( .6 + .6 * cos( 6.3*(v) + vec4(0,23,21,0) ) )

float grad(float a) {
    float  sm = .005;
    float f = 1./3.;
    a = mod(a+1.,2.);
    return mix(
                    mix(.45 //SIDE1
                       ,.65 //SIDE2
                       , smoothstep (sm,-sm,abs(1.+f-a)-f)) 
                    ,.95 // BOTTOM-TOP
                    , smoothstep (f+sm, f-sm, 1.-abs(1.-a))); 
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 r = resolution.xy
        ,st = (g+g-r)/r.y;
    st += st * length(st)*.1;

    float a = atan(st.x,st.y)/PI
        ,T = time;

    float g1  = grad(a)
        ,g2 = grad(a+1.);

    float l = dot(abs(st),normalize(vec2(1.,1.73)));
    l = log2(max(l,abs(st.x)))-T;
    float fl = fract(l);
    
    float sm = fwidth(l)*1.5;

    vec4 c = hue(a+T*.1)
        ,c2 = mix(hue(hash1(floor(l)-1.)),c,.3)
        ,c3 = mix(hue(hash1(floor(l)+1.)),c,.3);
    c = mix(hue(hash1(floor(l))),c,.3);

    if (mod(l,2.)<1.) {
        c *= g1;
        c2 *= g2;
        c = mix(
                mix(c2,c,smoothstep(-sm,sm,fl-.005))
                ,c2*.75
                ,smoothstep (.4, 0., fl)*0.25)
           * (1.-smoothstep(.1,0.,abs(mod(a+1.,2./3.)-1./3.))*.25);}
    else {
        c *= g2;
        c2 *= g1;
        c3 *= g1;
        c = mix(
                mix(c2,c,smoothstep(-sm,sm,fl-.005))
                ,c3*.5
                ,smoothstep (.7, 1., fl)*.2);}

    glFragColor = c;
}
