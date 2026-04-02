#version 420

// original https://www.shadertoy.com/view/ssX3W2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Did you know that a bee has 5 eyes ?
// The three ocelli are simple eyes that discern light intensity, 
// while each of the two large compound eyes contains about 6,900 facets 
// and is well suited for detecting movement.

#define T time
#define S smoothstep
#define sat(x) clamp(x,0.0,1.0)
#define AA(d,r,pix) smoothstep( .75, -.75, (d)/(pix)-(r))   // antialiased draw. r >= 1.

// Many code "replicated" from Shane
// Hexagonal Maze Flow by Shane               https://www.shadertoy.com/view/llSyDh
// Fork of "Minimal Hexagonal Grid" by Shane. https://shadertoy.com/view/Xljczw

// Standard vec2 to float hash - Based on IQ's original.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.173, 289.927)))*43758.5453); }

float remap01 (float a,float b, float t) {
    return sat((t-a)/(b-a));
}

float remap(float a, float b, float c, float d, float t) {
    return sat((t-a)/(b-a)) * (d-c) + c;
}

mat2 rot(float a) {
    float s=sin(a),
          c=cos(a);
    return mat2(c,s,-s,c);
}

float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r*r-d*d);
    return ((p.y-b)*d>p.x*b) ? length(p-vec2(0.0,b))
                             : length(p-vec2(-d,0.0))-r;
}

// Half of a Vesica, circle on the top
// In fact, no need of Egg shape SDF if you add some rounding
// My suggestion is to remove sdEgg from THE catalog, may be replace by this one 
float sdHalfVesica(vec2 p, float r, float d, float rnd)
{
    p.x = abs(p.x);
    float b = sqrt(r*r-d*d);
    float dist =  p.y < 0.0 ? length(p)-(r-d) :
           ((p.y-b)*d>p.x*b) ? length(p-vec2(0.0,b))
                             : length(p-vec2(-d,0.0))-r;
    return dist-rnd;
}

// half of Vesica again, circle on the right (need rouning to avoid sharp edges)
float sdHalfVesica2(vec2 p, float r, float d, float rnd)
{
    float b = sqrt(r*r-d*d);
    float dist =  p.x > 0.0 ? length(p)-b :
           ((abs(p.y)-b)*d>abs(p.x)*b) ? length(abs(p)-vec2(0.0,b))
                             : length(abs(p)-vec2(-d,0.0))-r;
    return dist-rnd;
}

// Fabrice https://www.shadertoy.com/view/llySRh
vec4 blendOver (vec4 A, vec4 B) {
        return (A + (1.-A.a)*B); // 
}

// Inspired by The Art of Code : https://www.youtube.com/watch?v=ZlNnrpM0TRg

vec4 Abdomen(vec2 uv,float pix) {
    float d = sdHalfVesica((uv-vec2(0.0,clamp(uv.y,-0.05,0.0)))*vec2(1.0,-1.0),.4,.33,.03); 
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.8,0.0,1.0);
    // black bands
    float tri = uv.y < -0.05 ? abs(fract(uv.y*10.0-.1+cos(6.*uv.x))-0.5)*4.0 : 0.0;
    vec4 band = S(0.6,1.0,tri)*vec4(0.1,0.05,0.05,1.0)*col.a;
    col = blendOver(band,col);
    // shading
    float edgeShade = remap01(0.0,0.09,-d);       
    col.rgb*=edgeShade;
    return col;
}

vec4 Wings1(vec2 uv,float pix,float a,float time) {
    a*=1.8;
    uv.x=abs(uv.x)-.07;
    uv.y-=.20;
    uv*=rot(a+.1*(1.0+sin(a*2.8+time*20.)));
    uv.y-=-.24;    
    float d = sdVesica(uv,0.365,0.3)-.03;        
    // borders
    float t = S(0.02,0.01,abs(d));
    float band = max(0.0,cos((uv.x-uv.y)*50.0));
    t = max(t,band);
    // blend
    vec4 col = AA(d,0.0,pix)*vec4(vec3(0.2,0.1,0.03)*remap01(0.03,0.0,abs(d)),1.0)*t;
    return col;
}

vec4 Wings2(vec2 uv,float pix,float a, float time) {
    a*=.8;
    uv.x=abs(uv.x)-.07;
    uv.y-=.20;
    uv*=rot(a+.1*(1.0+sin(time*20.)));
    uv.y-=-.18;    
    float d = sdVesica(uv,0.300,0.26)-.03;        
    // borders
    float t = S(0.02,0.01,abs(d));
    float band = max(0.0,cos((uv.x-uv.y)*50.0));
    t = max(t,band);
    // blend
    vec4 col = AA(d,0.0,pix)*vec4(vec3(0.2,0.1,0.03)*remap01(0.03,0.0,abs(d)),1.0)*t;
    return col;
}

vec4 Thorax(vec2 uv,float pix) {
    float d = sdHalfVesica2((uv-vec2(0.0,0.177)).yx,.1,.09,.04); 
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.8,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.05,-d);   
    col.rgb*=edgeShade;
    return col;
}

vec4 Head(vec2 uv,float pix) {
    float d = length(uv-vec2(clamp(uv.x,-.030,.030),0.0))-.041; 
    d = min(d, length(uv-vec2(0.0,0.02))-.03);
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.8,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.04,-d);  
    col.rgb*=edgeShade;
    return col;
}

vec4 Eyes(vec2 uv,float pix) {
    uv.x=abs(uv.x)-.044;
    float d = sdVesica((uv-vec2(0.0,0.29))*rot(-.1),.03,.025)-.025;
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.3,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.04,-d);  
    col.rgb*=edgeShade;
    return col;
}

// Inigo
float sdArc( in vec2 p, in vec2 sca, in vec2 scb, in float ra, float rb )
{
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

vec4 Antenna(vec2 uv,float pix) {
    uv.x = abs(uv.x);
    uv-=vec2(.024,0.33);
    float a=0.0; //1.-S(-blur,blur,d-0.02);
    float l=0.05;
    float bend=3.14*.15+0.2*sin(T*3.0);
    float r=l/bend;
    vec2 sc=vec2(sin(bend),cos(bend));
    vec2 start = uv-vec2(r,0.0);
    float d=sdArc(start,sc,sc,r,0.007);
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.8,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.007,-d);  
    col.rgb*=edgeShade*.3;
    return vec4(col);    
}

vec4 Legs(vec2 uv,float pix,float time) {
    float side = sign(uv.x);
    uv -= vec2(0.0,.20);
    uv.x = abs(uv.x);
    uv -= vec2(.05,0.0);
    float move = S(.5,.9,sin(time+3.14))*side*(.5-S(-2.2,2.2,sin(time*20.0)))*.2;
    uv *= rot(3.14*.25-move);
    uv.y +=sin(uv.x*6.28*6.*(1.0+move))*.01;
    float d = length(uv-vec2(clamp(uv.x,0.0,0.2*(1.0-move)),0.0))-0.01;
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.3,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.007,-d);  
    col.rgb*=edgeShade*.3;
    return vec4(col);    
}

vec4 Legs2(vec2 uv,float pix,float time) {
    float side = -sign(uv.x);
    uv -= vec2(0.0,.19);
    uv.x = abs(uv.x);
    uv -= vec2(.05,0.0);
    float move = S(.5,.9,sin(time+3.14))*side*(.5-S(-2.2,2.2,sin(time*20.0)))*.2;
    uv *= rot(-3.14*.35+move);
    uv.y +=cos(uv.x*6.28*3.5*(1.0+move))*.01;
    float d = length(uv-vec2(clamp(uv.x,0.0,0.4*(1.0-move)),0.0))-0.01;
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.3,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.007,-d);  
    col.rgb*=edgeShade*.3;
    return vec4(col);    
}

vec4 Legs3(vec2 uv,float pix,float time) {
    float side = -sign(uv.x);
    uv -= vec2(0.0,.19);
    uv.x = abs(uv.x);
    uv -= vec2(.05,0.0);
    float move = S(.5,.9,sin(time+3.14))*side*(.5-S(-2.2,2.2,sin(time*20.0)))*.2;
    uv *= rot(-3.14*.15-move);
    uv.y +=cos(uv.x*6.28*6.*(1.0-move))*.01;
    float d = length(uv-vec2(clamp(uv.x,0.0,0.2*(1.0+move)),0.0))-0.01;
    vec4 col = AA(d,0.0,pix)*vec4(0.8,0.3,0.0,1.0);
    // shading
    float edgeShade = remap01(0.0,0.007,-d);  
    col.rgb*=edgeShade*.3;
    return vec4(col);    
}

vec4 Bee ( vec2 uv, float blur, float time ) {
    if ( length(uv)>.7 ) return vec4(0);
    float a = 1.0;
    a=S(.9,.5,sin(time+3.14));
    vec4 col=vec4(0);
    col = blendOver(Legs(uv,blur,time),col);
    col = blendOver(Legs2(uv,blur,time),col);
    col = blendOver(Legs3(uv,blur,time),col);
    col = blendOver(Antenna(uv-vec2(0.0,0.0),blur),col);
    vec2 uv2 = uv;
    uv2 -= vec2(0.0,0.036*2.0);
    uv2 *= rot(cos(time)*.25+cos(time*15.0)*.5*S(0.1,0.6,-sin(time)));
    uv2 += vec2(0.0,0.036*2.0);
    uv2 -= vec2(0.0,0.03);
    col = blendOver(Abdomen((uv2),blur),col);
    col = blendOver(Thorax(uv,blur),col);
    col = blendOver(Head(uv-vec2(0.0,0.28),blur),col);
    col = blendOver(Eyes(uv-vec2(0.0,0.0),blur),col);
    col = blendOver(Wings2(uv-vec2(0.0,0.0),blur,a,time),col);
    col = blendOver(Wings1(uv-vec2(0.0,0.0),blur,a,time),col);
    return col;
}
// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 BeePath(float time) {
    vec2 pos = vec2(0.0);
    float turn = sign(sin(time*.5));
    pos = .7*vec2(turn*smin(cos(time)-.7,0.0,.1),1.9*sin(time));
    return pos;
}

vec3 BeeMoving(float time) {
    vec3 pos = vec3(0);
    pos.xy = BeePath(time);
    vec2 dir = BeePath(time+.1)-pos.xy;
    pos.z = -atan(dir.x,dir.y);
    return pos;
}

// Fabrice https://www.shadertoy.com/view/lsKSRt
// Fork of "Minimal Hexagonal Grid" by Shane. https://shadertoy.com/view/Xljczw
const vec2 s = vec2(1, 1.7320508);
float hex(in vec2 p){
    p = abs(p);
    return max(dot(p, s*.5), p.x); // Hexagon.
}

vec4 getHex(vec2 p){
    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);
}

vec3 Honeycomb(vec2 uv,float pix) {
    vec4 h = getHex(uv);
    float d = hex(h.xy)-.45;
    float d2 = dot(h.xy,h.xy);
    float rnd = hash21(h.zw);
    vec3 hue = ( .6 + .6 * cos( 6.3*(rnd)  + vec3(0,23,21)  ) );
    vec3 inner = vec3(0.8,0.7,0.02)*0.8*S(.5,0.,d2);
    inner = mix(inner,hue*hue,.5*S(.25,0.,d2)*S(.0,.5,sin(time*3.14+rnd*6.28)+.1));
    vec4 col = AA(d,0.0,pix)*vec4(inner,1.0);
    vec4 c = vec4(0.8,0.3,0.0,1.0)*.5;
    float band = .5*sin((uv.y+uv.x)*3.14159*40.);
    c += c*band;
    c.rbg *=0.2+0.8*d/0.05;
    col = blendOver(col,c);
    return col.rgb;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    float pix = 2.0/resolution.y;    
    
    vec2 m = mouse*resolution.xy.xy/resolution.xy;   
    //if ( mouse*resolution.xy.x > 0.0 ) {
    //    m=2.0*mouse*resolution.xy.xy/resolution.xy-1.0;
    //    uv.x -=m.x;
    //    uv *= (4. + 3.0*m.y)/4.0;
    //    pix *= (4. + 3.0*m.y)/4.0;
    //}
    
    vec3 col=vec3(.7);
    col = Honeycomb(uv*2.,pix*2.);
    for ( int i = 0 ; i < 5 ; i++ ) {
        vec2 p = uv;
        float time = T+float(i)*3.14*2.4;
        vec3 pos = BeeMoving(time+3.14/2.);
        p*=rot(-3.14*.5);
        p.y -= -.10;
        p -= pos.xy*0.7;
        p *= rot(pos.z);
        p.y -= -.2;
        vec4 layer = Bee(p,pix,time);
        float shadow = Bee((p-S(.9,.5,sin(time+3.14))*vec2(-.1,-.1))*(.8+.2*S(.5,.9,sin(time+3.14))),pix*2.0,time).a;
        col-=.5*col*shadow;
        col = blendOver(layer,vec4(col,1.0)).rgb;    
    }
    // gamma
    col = sqrt(col);
    glFragColor=vec4(col,0.0);
}
