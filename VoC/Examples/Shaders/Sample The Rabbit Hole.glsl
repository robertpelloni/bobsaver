#version 420

// original https://www.shadertoy.com/view/Md3yRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: Rigel rui@gil.com
// licence: https://creativecommons.org/licenses/by/4.0/
// link: https://www.shadertoy.com/view/Md3yRf

/*
This was inpired by Escher painting "Print Gallery" and this lecture
https://youtu.be/clQA6WhwCeA?t=7m50s

I wanted to do something with the Escher Droste effect, but then I 
discovered this blog post by user https://www.shadertoy.com/user/roywig
http://roy.red/droste-.html#droste

And his post about KIFS (Kaleidoscopic Iterated Function Systems)
http://roy.red/folding-the-koch-snowflake-.html#folding-the-koch-snowflake

An this sended me along a rabbit hole of folding space, 
and constructing kifs with escher like spiral zooms :) 

There are plenty of Escher/Droste effect on shadertoy, but this one by reinder
is like total magic. https://www.shadertoy.com/view/Mdf3zM

*/

// utility functions
// conversion from cartesian to polar
vec2 toPolar(vec2 uv) { return vec2(length(uv),atan(uv.y,uv.x)); }
// conversion from polar to cartesian
vec2 toCarte(vec2 z) { return z.x*vec2(cos(z.y),sin(z.y)); }
// complex division in polar form z = vec2(radius,angle)
vec2 zdiv(vec2 z1, vec2 z2) { return vec2(z1.x/z2.x,z1.y-z2.y); }
// complex log in polar form z = vec2(radius,angle)
vec2 zlog(vec2 z) { return toPolar(vec2(log(z.x),z.y)); }
// complex exp in polar form z = vec2(radius,angle)
vec2 zexp(vec2 z) { z = toCarte(z); return vec2(exp(z.x),z.y); }
// smoothstep antialias with fwidth
float ssaa(float v) { return smoothstep(-1.,1.,v/fwidth(v)); }
// stroke an sdf 'd', with a width 'w', and a fill 'f' 
float stroke(float d, float w, bool f) {  return abs(ssaa(abs(d)-w*.5) - float(f)); }
// fills an sdf 'd', and a fill 'f'. false for the fill means inverse 
float fill(float d, bool f) { return abs(ssaa(d) - float(f)); }
// a signed distance function for a rectangle 's' is size
float sdfRect(vec2 uv, vec2 s) { vec2 auv = abs(uv); return max(auv.x-s.x,auv.y-s.y); }
// a signed distance function for a circle, 'r' is radius
float sdfCircle(vec2 uv, float r) { return length(uv)-r; }
// a signed distance function for a hexagon
float sdfHex(vec2 uv) { vec2 auv = abs(uv); return max(auv.x * .866 + auv.y * .5, auv.y)-.5; }
// a signed distance function for a equilateral triangle
float sdfTri(vec2 uv) { return max(abs(uv.x) * .866 + uv.y * .5, -uv.y)-.577; }
// a 'fold' is a kind of generic abs(). 
// it reflects half of the plane in the other half
// the variable 'a' represents the angle of an axis going through the origin
// so in normalized coordinates uv [-1,1] 
// fold(uv,radians(0.)) == abs(uv.y) and fold(uv,radians(90.)) == abs(uv.x) 
vec2 fold(vec2 uv, float a) { a -= 1.57; vec2 axis = vec2(cos(a),sin(a)); return uv-(2.*min(dot(uv,axis),.0)*axis); }
// 2d rotation matrix
mat2 uvRotate(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

// this functions 'folds' space with the symmetries of the Koch Snowflake
// https://en.wikipedia.org/wiki/Koch_snowflake
// it returns a coordinate system uv, where you can draw whatever you like
// 'n' is the number of iterations
vec2 uvKochSnowflake(vec2 uv, int n) {
    uv = fold(vec2(-abs(uv.x),uv.y),radians(150.))-vec2(.0,.44);
    for (int i=0; i<n; i++) 
        uv = fold(vec2(abs(uv.x),uv.y)*3.-vec2(.75,.0),radians(60.))-vec2(.75,.0);
    return uv;
}

// this functions 'folds' space with the symmetries of the Sierpinski Carpet
//https://en.wikipedia.org/wiki/Sierpinski_carpet
// it's like the 2d equivalent of the menger sponge
// it returns a coordinate system uv, where you can draw whatever you like
// 'n' is the number of iterations
vec2 uvSierpinskiCarpet(vec2 uv, int n) {
    for (int i=0; i<n; i++) {
        uv = fold(abs(uv*3.),radians(45.))-vec2(2.0,1.0);
        uv = vec2(uv.x,abs(uv.y)-1.);
    }
    return uv;    
}

// the scene
vec3 TheRabbitHole(vec2 uv) {

    // a flag for the scene
    float sc = 1.;
    // save current uv for the rabbit
    vec2 uvr = uv;

    // if mouse clicked apply the Escher/Droste transform
    //if (mouse*resolution.xy.w >.0) {
        float scale = log(4.);
        float angle = atan(scale/6.283);
        // this is an infinite zoom
        uv /= exp(mod(time*.8,6.283/angle));
        // this line is the Escher Deformation with a scale and rotation 
        uv = toCarte(zexp(zdiv(zlog(toPolar(uv)),vec2(cos(angle),angle))));
        // this line is the Droste Effect for the size of the frame
        uv /= exp(scale*floor(log(sdfRect(uv*vec2(.8,.66),vec2(0.)))/scale));
        sc = -1.;
    //}

    // the frame
    float frame = min(
        stroke(sdfRect(uv,vec2(1.5,1.75)),.5,true),
        // drawing a simple rectangle in the sierpinsi carpet coordinate system
        fill(sdfRect(uvSierpinskiCarpet(mod((uv-vec2(.25,.0))*6.,3.)-1.5,2),vec2(1.)),false));

    // the canvas behind the rabbit
    float canvas = fill(sdfRect(uv,vec2(1.4,1.6)),true)*(1.-sdfRect(uv,vec2(.4,.6)));
    
    // uv for the rabbit
    uvr = sc == 1. ? uvr*.2+vec2(0.,.15) : uvr*.5*uvRotate(time*4.);
    // uv for the rabbit ears
    vec2 uvears = vec2(abs(uvr.x),uvr.y)*uvRotate(radians(-20.)); 
    float ears = stroke(sdfCircle(vec2(-abs(uvears.x),uvears.y)-vec2(.16,.3),.2),.04,true); 
    // uv for the rabbit eyes
    vec2 uveyes = vec2(abs(uvr.x),uvr.y)*uvRotate(radians(-40.)); 
    float eyes = fill(sdfCircle(vec2(-abs(uveyes.x),uveyes.y)-vec2(.05,.1),.07),false); 
    // nose ant teeth
    float nose = fill(sdfCircle(vec2(abs(uvr.x),uvr.y)-vec2(.008,.0),.02),false);
    float teeth = fill(sdfRect(vec2(abs(uvr.x),uvr.y)-vec2(.007,-.045),vec2(.005,.015)),false);

    // the face is just a bunch of circles
    float face = max(max(
        fill(sdfCircle(uvr-vec2(.0,.0),.07),true),
        fill(sdfCircle(vec2(abs(uvr.x),uvr.y)-vec2(.078,.05),.07),true)),
        fill(sdfCircle(uvr-vec2(.0,.1),.12),true));
    
    // compose the rabbit
    float rabbit = min(min(min(eyes,nose),teeth),max(ears,face));

    // a coodinate system uv for the Koch Snowflake KIFS
    vec2 uvka = uvKochSnowflake(vec2(abs(uv.x),uv.y)*.7-vec2(2.3,.0),2);
    vec2 uvkb = vec2(uvka.x,mod(uvka.y+time,.8)-.4);
    // drawing a pattern with this uv
    float kifs = max(max(max(min(
        fill(sdfCircle(uvkb,.4),false),
        fill(sdfRect(uvka-vec2(.0,-1.5),vec2(.6,6.)),true)),
        stroke(sdfRect(uvka,vec2(1.,.2)),.3,true)),
        fill(sdfHex(uvka-vec2(cos(time),sin(time)*2.)),true)), 
        fill(sdfRect(uvkb,vec2(.2)),true));

    // the small clock on the left
    vec2 uvc = (uv+vec2(3.3,.0))*1.2;
    vec2 uvch = sc==1. ? uvc : uvc*uvRotate(radians(time*60.));
    float chronos = min(min(
        fill(sdfHex(uvc),true),
        stroke(sdfCircle(uvc,.4),.1,false)+
        stroke(mod(atan(uvc.y,uvc.x)+radians(15.),radians(30.))-radians(15.),.15,false)),
        fill(sdfRect(uvch-vec2(.0,.15),vec2(.03,.15)),false));
    
    // the small card figure on the right    
    vec2 uvh = (uv-vec2(3.3,.0))*1.2;
    float card = max(max(stroke(sdfHex(uvh),.1,true),
    fill(sdfCircle(vec2(uvh.x,-sc*uvh.y-pow(abs(uvh.x)*.25,.5)+.15)*1.2,.3),true)),
    fill(sdfTri(uvh*7.+vec2(.0,2.2)),true)*sc);

    // background
    vec3 c = vec3(.9)* (sc == 1. ? 1. : 1.2-length(uv)*.15);
    // mixing all compoents together
    c = mix(c,vec3(.1),canvas);
    c = mix(c,vec3(.6)-sc*vec3(.3),kifs);
    c = mix(c,vec3(.3)-sc*vec3(.3,.0,.0),chronos);
    c = mix(c,vec3(.3)-sc*vec3(.3,.0,.0),card);
    c = mix(c,vec3(.2),frame);
    c = mix(c,vec3(sc),rabbit);
    return c;
}

void main(void) {
    vec2 uv = ( gl_FragCoord.xy - resolution.xy * .5) / resolution.y;

    glFragColor = vec4( TheRabbitHole(uv*6.), 1.0 );
}
