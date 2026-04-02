#version 420

// original https://www.shadertoy.com/view/mtdGWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(3.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define deg45 .707
#define R45(p) (( p + vec2(p.y,-p.x) ) *deg45)
#define Tri(p,s) max(R45(p).x,max(R45(p).y,B(p,s)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )

float random (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

// principal value of logarithm of z
// https://gist.github.com/ikr7/d31b0ead87c73e6378e6911e85661b93
vec2 clog (vec2 z) {
    return vec2(log(length(z)), atan(z.y, z.x));
}

// The following code will return the Droste Zoom UV.
// by roywig https://www.shadertoy.com/view/Ml33R7
vec2 drosteUV(vec2 p){
    float speed = 0.5;
    float animate = mod(time*speed,2.07);
    float rate = sin(time*0.5);
    p = clog(p)*mat2(1,.11,rate*0.5,1);
    //p = clog(p);
    p = exp(p.x-animate) * vec2( cos(p.y), sin(p.y));
    vec2 c = abs(p);
    vec2 duv = .5+p*exp2(ceil(-log2(max(c.y,c.x))-2.));
    return duv;
}

float arrowBase(vec2 p){
    vec2 prevP = p;
    p.y-=0.3;
    float d = Tri(p,vec2(0.35));
    p = prevP;
    p-=vec2(0.,0.1);
    float d2 = Tri(p,vec2(0.3));
    d = max(-d2,d);
    p = prevP;
    p.y+= 0.1;
    d2 = B(p,vec2(0.07,0.2));
    float a = radians(-45.);
    p.x = abs(p.x);
    p.y+=0.2;
    d2 = max(dot(p,vec2(cos(a),sin(a))),d2);
    d = min(d,d2);
    
    return d;
}

float arrow(vec2 p, float speed){
    p.y-= 0.5;
    p.y-=time*(0.5+(speed*0.5));
    p.y = mod(p.y,1.)-0.5;
    vec2 prevP = p;
    float d = abs(arrowBase(p))-0.01;
    
    p.y+= 0.04;
    float d2 = B(p,vec2(0.03,0.2));
    float a = radians(-45.);
    p.x = abs(p.x);
    p.y+=0.2;
    d2 = max(dot(p,vec2(cos(a),sin(a))),d2);
    p = prevP;
    a = radians(45.);
    p.x = abs(p.x);
    p.y-=0.1;
    d2 = max(dot(p,vec2(cos(a),sin(a))),d2);
    
    d = min(d,abs(d2)-0.01);
    
    p = prevP;
    p.y-=0.21;
    d2 = Tri(p,vec2(0.2));
    p = prevP;
    p-=vec2(0.,0.18);
    
    d2= max(-Tri(p,vec2(0.2)),d2);
    
    d = min(d,d2);    
    
    
    return d;
}

float bg(vec2 p){
    vec2 prevP = p;
    p = mod(p,0.1)-0.05;
    float d = length(p)-0.002;
    
    return d;
}

float otherGraphicItems(vec2 p){
    vec2 prevP = p;
    
    p.x = abs(p.x);
    p.x-=0.45;
    float d = B(p,vec2(0.002,0.3));
    p.x+=0.02;
    p.y+=time*0.2;
    p.y=mod(p.y,0.05)-0.025;
    float d2 = B(p,vec2(0.02,0.002));
    d2 = max((abs(prevP.y)-0.3),d2);
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x);
    p.x-=0.42;
    p.y = abs(p.y)-0.3;
    d2 = B(p,vec2(0.03,0.003));
    d = min(d,d2);
    
    p = prevP;
    p = abs(p)-0.3;
    p*=Rot(radians(time*100.-45.));
    d2 = B(p,vec2(0.04,0.003));
    d = min(d,d2);
    
    p = prevP;

    p.y+=sin(-time)*0.25;
    p.x = abs(p.x)-0.39;
    d2 = B(p,vec2(0.005,0.02));
    d = min(d,d2);
    
    return d;
}

float drawGraphics(vec2 p){
    vec2 prevP = p;
    p*=4.; // `4.` will be the best fit.
    vec2 id = floor(p);
    vec2 gr = fract(p)-0.5;
    vec2 prevGr = gr;
    
    float n = random(id);
    
    float d = bg(gr);
    
    gr = prevGr;
    if(n<0.3){
        gr*=Rot(radians(90.));
    } else if(n>=0.3 && n<0.6){
        gr*=Rot(radians(180.));
    } else if(n>=0.6 && n<0.9){
        gr*=Rot(radians(270.));
    }
    
    float d2 = otherGraphicItems(gr);
    d = min(d,d2);
    
    d2 = max(B(prevGr,vec2(0.45)),arrow(gr,n));
    d = min(d,d2);
    
    gr = prevGr;
    d2 = abs(B(gr,vec2(0.45)))-0.01;
    d2 = max(-(abs(gr.x)-0.35),d2);
    d2 = max(-(abs(gr.y)-0.35),d2);
    d = min(d,d2);
    
    return d;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 prevP = p;
    vec2 duv = drosteUV(p);
    
    vec3 col = vec3(0.);
    
    p = duv;
    float d =drawGraphics(p);
    
    col = mix(col,vec3(1.),S(d,0.));
    p = prevP;
    col*=length(p); // The Antialiasing of the small scale of the graphics looks not great. Added the fog effect to fade them out.
    
    // debug
    //p = duv;
    //vec2 gr = fract(p*4.)-0.5;
    //col.rg+=gr;
    glFragColor = vec4(sqrt(col),1.);
}
