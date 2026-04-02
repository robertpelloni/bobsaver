#version 420

// original https://www.shadertoy.com/view/fsfXD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Lady Bugs for Spring
    daily shader practice
    @byt3_m3chanic 04/23/21

*/

#define R   resolution
#define M   mouse*resolution.xy
#define T   time
#define PI  3.14159265359
#define PI2 6.28318530718
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

vec3 hue(float t){ 
    t*=.615;
    vec3 c = vec3(.95, .87, .98),
         d = vec3(0.294,0.925,0.620),
         a = vec3(.55),
         b = vec3(.45);
    return a + b*cos((1.35+ PI)*t*(c*d) ); 
}
float line( in vec2 p, in vec2 a, in vec2 b, in float r ){
    vec2 ba = b-a, pa = p-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    float d = length(pa-h*ba);
    return d-r;
}

// set scale here
const float truchetScale = 8.;
void main(void) {
    vec2 F=gl_FragCoord.xy;

    vec2 U = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec2 uv = F.xy/max(R.x,R.y);
    
    vec3 color = vec3(0.941,0.922,0.820);
    
    float px = fwidth(uv.x)*PI;
    
    uv.xy += vec2(T*.05,0);
    uv *= truchetScale;

    vec2 grid_uv = fract(uv)-.5;
    vec2 grid_id = floor(uv);

    vec2 vu =rot(.45)*U;
    float sd = mod(floor(vu.y * 142.), 2.);
    vec3 stripe = (sd<1.) ? vec3(.9) : vec3(.8);
    
    float check = mod(grid_id.y + grid_id.x,2.) * 2. - 1.;
    float rnd = hash21(grid_id);

    if(rnd <.5) grid_uv.x *= -1.;

    vec2 arc = grid_uv-sign(grid_uv.x+grid_uv.y+.001)*.5;
    float angle = atan(arc.x, arc.y);
    float d = length(arc);

    vec2 d2 = vec2(length(grid_uv-.5), length(grid_uv+.5));
    vec2 gx = d2.x<d2.y? vec2(grid_uv-.5) : vec2(grid_uv+.5);

    float cir = length(gx)-.5;
    cir=abs(cir)-.21;
    
    float ufade = ((U.x+.25)*.115);
    float path =smoothstep(.01-px,px,cir);
    cir=abs(cir)-ufade;
    cir=smoothstep(.02-px,px,cir);
    
    float shadow2 = length(gx-vec2(.0015))-.5;
    shadow2=abs(shadow2)-.21;
    shadow2=abs(shadow2)-ufade;
    shadow2=smoothstep(.04,-px,shadow2);
    
    float width = .265;
    float trackspeed = 1.15;
    
    float amt = 6.;
    float hlf = amt*.5;
    float pathMotion = hlf*check*angle/1.57+T*trackspeed;
    float x = fract(pathMotion);
    float y = (d-(.5-width))/(width);y-=.5;

    vec2 cid = vec2(
        floor(d-(.5-width))/(2.*width),
        floor(pathMotion)
    );

    // force the id's to be 0 to amt
    cid = mod(cid,amt);
    
     // ^^ exclusive or operation
    if(rnd<.5 ^^ check>0.) y=1.-y;
    vec2 tuv = vec2(x,y);
    vec2 zuv = tuv-vec2(.25,.5);

    float nx = floor(length(cid))-.5;
    float ft = hash21(cid);
    float ws = mod(nx,amt);

    float ck = length(tuv-vec2(.5))-.3;
    float hgt = ck*-1.;
    float ckt = length(tuv-vec2(.425,.5))-.28;
    
    float cck = length(zuv)-.2;
    
    float shadow1 =length(tuv-vec2(.45))-.3;
    float tk=abs(ck)-.015;
    // all the smoothsteps.
    tk=smoothstep(px,-px,tk);
    ck=smoothstep(px,-px,ck);
    ckt=smoothstep(px,-px,ckt);
    cck=smoothstep(px,-px,cck);
    shadow1=smoothstep(.2,-px,shadow1);
    //lady bugs
    vec3 hue1 = hue(hash21(cid)*1.66);
    vec3 hue2 = hue(hash21(cid+1.)*1.62);
    float top = line(tuv,vec2(.35,.5),vec2(.775,.5),.025);
    
    top = min(line(tuv,vec2(.01,.25),vec2(.2,.35),.025),top);
    top = min(line(tuv,vec2(.01,.75),vec2(.2,.65),.025),top);
    
    zuv.y=abs(zuv.y)-.02;
    float specks = length(zuv-vec2(.12,.15))-.08;
    top=min(smoothstep(-px,px,specks),top);
    top=smoothstep(px,-px,top);

    
    float cix = length(abs(grid_uv.xy)-vec2(.5))-((U.x+.85)*.1);
    cix=abs(abs(cix)-.05)-.015;
    cix=smoothstep(.02-px,px,cix);

    //all the mixdowns
    color = mix(color,vec3(.9),path);
    color = mix(color,vec3(-1.*shadow2),shadow2*.25);
    color = mix(color,stripe*vec3(0.749,0.910,0.780),cir);
    if(mod(ws,2.)<1.){
        color = mix(color,vec3(-1.*shadow1),shadow1*.15);

        color = mix(color,vec3(0),cck);
        color = mix(color,hue2,ckt);
        color = mix(color,hue1+hgt,ck);
        color = mix(color,vec3(0),top);
        color = mix(color,vec3(.1),tk);
    } 
    
    glFragColor = vec4(color,1.0);
}
