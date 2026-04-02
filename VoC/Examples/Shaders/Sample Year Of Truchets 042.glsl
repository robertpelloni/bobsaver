#version 420

// original https://www.shadertoy.com/view/mdlcRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define PI         3.14159265359
#define PI2        6.28318530718

float tspeed=0.,tmod=0.,ga1=0.,ga2=0.,ga3=0.,ga4=0.;

mat2 rot(float a) {return mat2(cos(a),sin(a),-sin(a),cos(a));}
float hash21(vec2 a) {return fract(sin(dot(a,vec2(27.609,57.583)))*43758.5453);}
float box(vec2 p, vec2 a) {vec2 q=abs(p)-a;return length(max(q,0.))+min(max(q.x,q.y),0.);}
float lsp(float b, float e, float t){return clamp((t-b)/(e-b),0.,1.); }
float eoc(float t){return (t = t-1.)*t*t+1.; }

//@iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1., 0., 1.0 );
    return c.z * mix( vec3(1), rgb, c.y);
}

void main(void) {
    
    tspeed = T*.3;
    tmod = mod(tspeed,12.5);

    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    // @stb polar thing.. 
    uv.x -= .25;
    uv /= uv.x*uv.x + uv.y*uv.y;
    uv.x += 2.;
    
    // inversion
    float scale = 1.2726;
    uv *= rot(-T*.035);
    uv = vec2(log(length(uv)), atan(uv.y, uv.x))*scale;
    uv.x -= T*.2;
 
    float px = fwidth(uv.x); 
    
    // std truchet stuff
    vec2 id = floor(uv), q = fract(uv)-.5;
    float rnd = hash21(id.xy);
    float ck =mod(id.x+id.y,2.)*2.-1.;

    float sn = length(id*.25)+hash21(id.yx)*11.;
    sn = mod(sn,10.);
    
    float t1 = lsp(sn,sn+.5,tmod);
    float t2 = lsp(sn+2.,sn+2.5,tmod);
    t1 = eoc(t1); t1 = t1*t1*t1;
    t2 = eoc(t2); t2 = t2*t2*t2;
    q.xy*=rot((t1+t2)*1.5707);
    
    // main pattern
    if(rnd>.5) q.y = -q.y;
    rnd=fract(rnd*32.232);
    
    vec2 u2 = vec2(length(q-.5),length(q+.5));
    vec2 q2 = u2.x<u2.y ? q-.5 : q+.5;
    
    float tk = .1275;
    float d1 = abs(length(q2)-.5)-tk;
    float d3 = length(q)-.485;
    
    if(rnd>.85) d1 = min(length(q.x)-tk,length(q.y)-tk);
    
    float d4=max(d1,d3);
    d1=abs(d1)-.035;
    d1=max(d1,d3);
   
    rnd=fract(rnd*32.232);

    // color mixdown
    vec3 C = hsv2rgb(vec3((uv.x*.025),.9,.1));
    vec3 klr = hsv2rgb(vec3((rnd*.15)+(uv.x*.025),1.,.5));//vec3(.282,.114,.039)
    vec3 clr = mix(vec3(.02,.341,.02),klr,rnd);//
    C = mix(C,C*.75,smoothstep(.03+px,-px,d3-.035));
    C = mix(C,clr,smoothstep(px,-px,d3));
    C = mix(C,vec3(.5),smoothstep(px,-px,d1));
    C = mix(C,klr*.425,smoothstep(px,-px,d4));
    C = mix(C,vec3(.5),smoothstep(px,-px,abs(d3)-.015));

    // gamma and output
    C = pow(C,vec3(.4545));
    glFragColor = vec4(C,1.);
}