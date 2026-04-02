#version 420

uniform float time;
uniform vec2 resolution,mouse;
uniform sampler2D backbuffer; 

out vec4 glFragColor;

#define A ch(vec4(.75,-1.32,-1.44,.75),vec4(.77,1.95,-2.28,-.59),vec4(.75,1.05,.32,1.),vec4(-.59,1.82,.78,-1.))
#define B ch(vec4(-1.,.3,-1.66,-.8),vec4(.2,3.3,5.,-1.)*2.,vec4(-1.,.6,2.,-.8),vec4(.2,2.6,-1.6,-1.))
#define C ch(vec4(.8,-.5,-2.1,.94),vec4(.8,1.8,-1.8,-.8),vec4(.7,-.5,-2.1,.94),vec4(.8,1.8,-1.8,-.8))
#define D ch( vec4(.64,-.8,-1.8,.74),vec4(.78,1.9,-1.7,-.86),vec4(.74,1.3,-.63,1.), vec4(-.43,4.8,3.8,0.)*2.)
#define E ch(vec4(-.8,2.8,-.65,-.8),vec4(0.,-.27,2.3,-.1),vec4(-.8,-.82,-.92,1.),vec4(-.1,-.32,-1.2,-1.))
#define F ch(vec4(-.44,2.1,-1.,0.)*2.,vec4(.44,4.4,4.,-2.4)*2.,vec4(0.,.6,-1.24,.62)*2.,vec4(-2.4,1.28,.56,.6)*2.)
#define G ch(vec4(.9,-.4,-2.3,.84),vec4(.34,2.4,-1.8,-.99),vec4(.9,1.,-14.1,-10.),vec4(0.,-4.7,-3.5,-.9)*2.)
#define H ch(vec4(-1.,.9,-1.1,-.75),vec4(.43,4.5,3.4,-.5)*2.,vec4(-.75,-.24,.78,.94),vec4(-1.,3.7,-1.35,-1.))
#define I ch(vec4(0.,-.14,-1.19,.64),vec4(.8,-.48,-1.07,-1.),vec4(-.05,.43,-.34,.07),vec4(2.88,2.71,2.67,2.86))
#define J ch(vec4(0.,-.3,-14.1,-10.),vec4(.5,-6.19,-1.7,-2.5)*2.,vec4(-.05,.43,-.34,.03),vec4(2.88,2.71,2.67,2.96))
#define K ch(vec4(-.94,.58,-1.1,-.94),vec4(.6,4.35,3.6,-.7)*2.,vec4(.4,-2.4,.3,.8),vec4(.8,0.,0.,-1.))
#define L ch(vec4(-.4,1.,.3,-.17),vec4(-.5,1.2,3.8,2.8)*2.,vec4(-.17,-.8,.38,.84),vec4(2.8,1.8,-1.,-.5)*2.)
#define M ch(vec4(-.9,-.9,-.33,0.), vec4(-1.,.912,1.6,-.7),vec4(0.,.33,.9,.9),vec4(-.7,1.6,.912,-1.))
#define N ch(vec4(-1.07,-.64,-.9,-.76),vec4(.35,.93,.85,-1.),vec4(-.75,-.9,.7,.94),vec4(-1.,.85,1.9,-1.))
#define O ch(vec4(0.,-1.1,-1.1,0.),vec4(1.,.82,-.8,-1.),vec4(0.,1.1,1.1,0.),vec4(-1.,-.8,.82,1.))
#define P ch(vec4(-1,-.43,-.58,-1.3),vec4(.43,1.5,-1.9,-3.)*2.,vec4(-.7,.83,1.75,-.7),vec4(.8,1.9,-1.75,-.8))
#define Q ch(vec4(.7,-.83,-1.75,0.),vec4(.8,1.9,-1.75,-.8),vec4(.7,-1.5,-1.74,4.13),vec4(.26,-2.7,-4.76,-2.5)*2.)
#define R ch(vec4(-.88,-.28,-.43,-.5),vec4(.86,1.5,-.67,-1.),vec4(-.5,-.54,.22,.9),vec4(-1.,1.,1.,.8))
#define S ch(vec4(.78,-.7,-1.5,0.),vec4(.88,1.34,.55,0.),vec4(0.,1.5,.67,-.9),vec4(0.,-.55,-1.35,-.8))
#define T ch( vec4(-.55,.35,-1.37,.76),vec4(3.,1.16,-1.1,-1.)*2.,vec4(-1.,-7.7,-1.4,4.5),vec4(2.84,2.4,1.7,2.)*2.)
#define U ch( vec4(-.9,-1.1,1.,.72),vec4(.9,-1.6,-1.7,.9),vec4(.72,.7,1.,1.4),vec4(.9,-1.6,-1.,-.77))
#define V ch( vec4(-1.,-.83,-.236,0.),vec4(.88,1.5,-.73,-1.),vec4(0.,1.55,-.25,1.),vec4(-1.,1.8,.9,.65))
#define W ch( vec4(-.7,-1.2,-.33,0.),vec4(1.,-.912,-1.6,.7),vec4(0.,.33,.9,.9),vec4(.7,-1.6,-.912,1.))
#define X ch( vec4(.83,.25,-.3,-1.),vec4(.95,.6,-.5,-1.),vec4(-.9,.48,-.43,1.),vec4(.87,.35,-.5,-1.))
#define Y ch( vec4(-.9,-.2,.9,.9),vec4(.9,-2.9,0.,.9),vec4(.9,-.37,-14.1,-10.),vec4(.2,-4.7,-3.5,-.9)*2.)
#define Z ch( vec4(-.9,1.1,1.3,0.),vec4(.9,.9,1.5,0.),vec4(0.,-1.3,-1.1,.9),vec4(0.,-1.5,-.9,-.9))
#define LV ch( vec4(0.,-.45,-2.,0.)*2.,vec4(.58,1.4,1.,-1.)*3.,vec4(0.,2.,.45,0.)*2.,vec4(-1.,1.,1.4,.58)*3.)
#define QU ch( vec4(-.66,2.74,-.3,-.05),vec4(2.9,3.35,1.6,.58)*2.,vec4(-.05,.43,-.34,.03),vec4(-.42,-.59,-.63,-.44))

// ========== User Parameters ================
 #define EVIL         // uncomment to enable Freddy Kruger 
#define NUM_CHARS 14.
#define H_SPACING 1.2
#define DENSITY .5       // density 0 - 1.
#define SIZE .25 
#define X_START 4.
#define COLOR vec3(.1,.99,.75) //vec3(mod(time,1.),mod(time*1.23456,1.01345),mod(time*1.10987,.99334)) //vec3(sin(time),cos(time),1.-sin(time)) //vec3(.93,.4,.5) // vec3(.3,.84,.5)   
#define THICKNESS .95    // .9672   // thickness 0.0 - 1.0
#ifdef EVIL
const float min_ex = -.9, max_ex = 1.9, lbound=-.205, inc=.00125;
#else
const float min_ex = 0., max_ex = 1., lbound=-.05, inc=.00125;
#endif
#define ch(m,n,o,p) else if(t0<++h+1.) {for(float ut=lbound; ut<.1; ut+=inc) spot+= ((ut0=t0-h+ut)>=min_ex&&ut0<=max_ex)? 1.-smoothstep(length(getPos(ut0,m+vxx,(n)*aspect)-v)*THICKNESS,0.00,.012) :0.; } else if(t0<++h+1.) { for(float ut=lbound; ut<.1; ut+=inc) spot+= ((ut0=t0-h+ut)>=min_ex&&ut0<=max_ex)? 1.-smoothstep(length(getPos(ut0,o+vxx-H_SPACING,(p)*aspect)-v)*THICKNESS,0.00,.012) :0.; }

vec2 getPos(float t, vec4 x, vec4 y)
{    
    float t1 = 1.-t; 
    vec4 n = vec4(t1*t1*t1, 3.*t1*t1*t, 3.*t1*t*t, t*t*t);    
    return vec2(dot(x,n), dot(y,n));
}
    
void main( void ){
    vec2 position = gl_FragCoord.xy/resolution.xy, v = (position-.5)/SIZE*10.;    
    float t=time*3., spot=0., h=0.,aspect=resolution.x/resolution.y, ut0, t0=mod(t,NUM_CHARS*2.+1. + 9.), vxx=floor(t0)*H_SPACING/1.1-20.+ X_START;    if(t0<h+1.); 

    // set NUM_CHARS in User Parameters section to the correct number of chars in line below
    F R E D D Y  LV  K R U E G E R
           
    if(t0>.51) glFragColor = vec4(-spot*DENSITY*COLOR,1.) + texture2D(backbuffer,position);
    else       glFragColor = vec4(1.);
}
