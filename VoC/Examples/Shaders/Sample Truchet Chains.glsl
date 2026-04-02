#version 420

// original https://www.shadertoy.com/view/wtGyDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Animated Circular Truchet Tiles
    @pjkarlik | 1/26/20201

*/

#define PI2            6.28318530718
#define PI            3.14159265358

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }
float hash11(in float n){ return fract(sin(n)*43758.5453123);}
float noise(in vec2 x){
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    float res = mix(mix( hash11(n+  0.0), hash11(n+  1.0),f.x),
                    mix( hash11(n+ 57.0), hash11(n+ 58.0),f.x),f.y);
    return res;
}

vec3 hue(float t){ 
    t*=.615;
    vec3 c = vec3(.95, .87, .98),
         d = vec3(0.216,0.604,0.643),
         a = vec3(.675),
         b = vec3(.45);
    return a + b*cos((1.35+ PI)*t*(c*d) ); 
}
//@iq sdf circle/line segment
float circle(vec2 pt, vec2 center, float r, float lw, float ed) {
  float len = length(pt - center),
        hlw = lw / 2.,
        edge = ed;
  return smoothstep(r-hlw-edge,r-hlw, len)-smoothstep(r+hlw,r+hlw+edge, len);
}
float line( in vec2 p, in vec2 a, in vec2 b, in float r ){
    vec2 ba = b-a, pa = p-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    float d = length(pa-h*ba);
    return d-r;
}

vec4 getCheck(vec2 p){
    vec2 marbleAxis = normalize(vec2(1,-4));     
    vec2 mfp = (p + dot(p,marbleAxis)*marbleAxis*2.0)*2.0;
    float marble = 0.;
    marble += abs(noise(mfp)-.5);
    marble += abs(noise(mfp*4.)-.5)/2.;
    marble += abs(noise(mfp*8.)-.5)/4.;
    marble += abs(noise(mfp*12.)-.5)/8.;
    marble /= 1.0-1.0/8.0;
    marble = pow(1.0-clamp(marble,0.0,1.0),15.0); // curve to thin the veins
    return vec4(mix( vec3(.1), vec3(.7), marble ), marble);
}

// set scale here
const float truchetScale = 4.25;
void main(void) {

    // Normalized pixel coordinates (from -1 to 1)
    vec2 U = (2.*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    vec2 uv = gl_FragCoord.xy/max(resolution.x,resolution.y);

    vec3 color = vec3(1);
    uv.xy += vec2(time*.025,time*.05);
    // multiplier
    uv *= truchetScale;
    
    // section off screen into grid
    // set id for each tile
    vec2 grid_uv = fract(uv)-.5;
    vec2 grid_id = floor(uv);
    
    // get every other tile in a checker board
    float checker = mod(grid_id.y + grid_id.x,2.) * 2. - 1.;
    // get hash for tile from id
    float n = hash21(grid_id);
    
    color =mix(color,vec3(.09),(checker>0.) ? getCheck(uv*2.).rgb : 1.-getCheck(uv*2.).rgb)*.5;

    // if hash lower than - flip tile
    if(n <.5) grid_uv.x *= -1.;

    // arc
    vec2 arc = grid_uv-sign(grid_uv.x+grid_uv.y+.001)*.5;
    float angle = atan(arc.x, arc.y);
    float d = length(arc);

    float width = .25;

    // circle new pos
    float trackspeed = 1.15;
    float x = fract(3.*checker*angle/1.57+time*trackspeed);
    
    // i dont know how to prevent space from
    // distorting - but pushing y*2 and then
    // compensating .5 - not the best but ok.
    float y = (d-(.5-width))/(2.*width)*2.;y-=.5;
    
    // id's for circles
    vec2 cid = vec2(
        floor(d-(.5-width))/(2.*width),
        floor(3.*checker*angle/1.57+time*trackspeed)
    );
    // id's for center links
    vec2 lid = vec2(
        floor(d-(.5-width))/(2.*width),
        floor((3.*checker*(angle)/1.57+time*trackspeed)+.5)
    );
    
    // force the id's to be 1 to 6 - for colors
    cid = mod(cid,6.);
    lid = mod(lid,6.);
    
    // ^^ exclusive or operation
    if(n<.5 ^^ checker>0.) y=1.-y;
    vec2 tuv = vec2(x,y);

    vec3 hue1 = hue(hash21(cid)*2.);
    vec3 hue1a= hue(hash21(cid+5.)*2.);
    //circle stripe coloring
    float a2 = atan(tuv.x-.5, tuv.y-.5);
    hue1 = mix(hue1, hue1a, smoothstep(.1,.15,sin(14.05*a2/1.57+time*10.)) );
    // shadow1
    float ck = circle(tuv,vec2(.5),.35,.2,.01);
    float shadow1 = circle(tuv+vec2(0.,.125),vec2(.5),.35,.12,.15);
    
    // color shadow then circle overtop
    color = mix(color,vec3(-1.*shadow1),shadow1*.15);
    color = mix(color,hue1,ck);

    vec3 hue2 = hue(hash21(lid+vec2(2.))*2.);
    float lnk = min(line(tuv+vec2(.5,0),vec2(.2,.5),vec2(.8,.5),.01),
        line(tuv-vec2(.5,0),vec2(.2,.5),vec2(.8,.5),.01));   
    // shadow 2    
    float shadow2 = min(line(tuv+vec2(.5,.09),vec2(.2,.5),vec2(.8,.5),.01),
        line(tuv-vec2(.5,-.09),vec2(.2,.5),vec2(.8,.5),.01));

    // color shadow then circle overtop
    color = mix(color,vec3(0),(1.- smoothstep(.1,.2,shadow2))*.4);
    float linkmask = 1.- smoothstep(.1,.12,lnk); 
    color = mix(color,hue2,linkmask);

    // Output to screen
    glFragColor = vec4(color,1.0);
}
