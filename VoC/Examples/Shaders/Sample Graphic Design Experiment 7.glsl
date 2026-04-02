#version 420

// original https://www.shadertoy.com/view/ddGXzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(3.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define R45(p) (( p + vec2(p.y,-p.x) ) *.707)
#define Tri(p,s) max(R45(p).x,max(R45(p).y,B(p,s)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define SymdirY(p) mod(floor(p).y,2.)*2.-1.

float random (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float animateAarrow(vec2 p){
    float dir = SymdirY(p);
    p.y+=time*0.2*dir;    
    p.y = mod(p.y,0.3)-0.15;
    p*=Rot(radians(45.));
    float d = abs(B(p,vec2(0.05)))-0.02;
    return d;
}

float arrow(vec2 p){
    float d = Tri(p,vec2(0.15));
    p-=vec2(0.0,-0.1);
    float d2 = Tri(p,vec2(0.12));
    d = max(-d2,d);
    return d;
}

float pattern0(vec2 p, float dir, float n, float size){
    float d = length(p)-size;
    p*=Rot(radians(45.+time*dir*30.+(n*5.)));
    float d2 = abs(length(p)-0.25)-0.05;
    d2 = max(-(abs(p.x)-0.05),d2);
    return min(d,d2);
}

float pattern1(vec2 p, float dir, float n){
    p*=Rot(radians(-45.+time*dir*60.+(n*10.)));
    vec2 prevP = p;
    p = DF(p,4.);
    p -= vec2(0.17);
    p*=Rot(radians(45.));
    float d = B(p,vec2(0.001,0.03));
    
    p = prevP;
    p = DF(p,2.);
    p -= vec2(0.18);
    p*=Rot(radians(45.));
    float d2 = B(p,vec2(0.001,0.05));
    
    d = min(d,d2);
    p = prevP;
    
    d2 = abs(length(p)-0.12)-0.04;
    
    p = DF(p,1.5);
    p -= vec2(0.18);
    p*=Rot(radians(45.));
    d2 = max(-B(p,vec2(0.02,0.2)),d2);
    
    d = min(d,d2);
    
    return d;
}

float pattern2(vec2 p, float dir, float n){
    p*=Rot(radians(-45.+time*dir*60.+(n*10.)));
    float d = abs(length(p)-0.29)-0.001;
    p.x = abs(p.x)-0.12;
    float d2 = length(p)-0.07;
    
    d = min(d,d2);
    
    return d;
}

float pattern3(vec2 p, float dir, float n){
    p*=Rot(radians(-45.+time*dir*60.+(n*10.)));
    vec2 prevP = p;
    p = DF(p,2.);
    p -= vec2(0.2);
    p*=Rot(radians(45.));
    float d = Tri(p,vec2(0.06));
    
    p = prevP;
    p = DF(p,2.);
    p -= vec2(0.1);
    p*=Rot(radians(45.));
    float d2 = B(p,vec2(0.001,0.03));
    d = min(d,d2);
    
    return d;
}

float pattern4(vec2 p, float dir, float n){
    p*=Rot(radians(-45.+time*dir*60.+(n*10.)));
    vec2 prevP = p;
    p = DF(p,2.);
    p -= vec2(0.1);
    p*=Rot(radians(45.));
    float d = B(p,vec2(0.001,0.15));
    
    p = prevP;
    p = DF(p,2.);
    p -= vec2(0.17);
    float d2 = B(p,vec2(0.04));
    d = min(d,d2);
    
    p = prevP;
    p*=Rot(radians(45.));
    d2 = B(p,vec2(0.08));
    d = min(d,d2);
    
    return d;
}

float drawGraphics(vec2 p){
    vec2 prevP = p;

    p.y+=time*0.1;
    p*=5.;
    vec2 id = floor(p);
    vec2 gr = fract(p)-0.5;
    vec2 prevGr = gr;
    
    float n = random(id);
    float d = 10.;
    if(n<0.5){
        if(n<0.25){
            gr*=Rot(radians(90.));
            prevGr*=Rot(radians(90.));
        }
    
        gr-=vec2(0.49);
        d = abs(length(gr)-0.49)-0.05;
        gr = prevGr;

        gr+=vec2(0.49);
        float d2 = abs(length(gr)-0.49)-0.05;
        d = min(d,d2);
        
        gr-=vec2(0.08);
        gr*=Rot(radians(225.));

        d2 = arrow(gr);
        d = min(d,d2);
         
        gr = prevGr;
        gr-=vec2(0.42);
        gr*=Rot(radians(45.));

        d2 = arrow(gr);
        d = min(d,d2);
        
        gr = prevGr;
        gr*=Rot(radians(-45.));
        d2 = animateAarrow(gr);
        d = min(d,d2);
    } else {
        float size = 0.05;
        
        float dir = (n>=0.75)?1.:-1.;
        
        if(n>=0.5 && n<0.6){
            d = pattern0(gr,dir,n, size);
        } else  if(n>=0.6 && n<0.7){
            d = pattern1(gr,dir,n);
        } else  if(n>=0.7 && n<0.8){
             d = pattern2(gr,dir,n);
        } else  if(n>=0.8 && n<0.9){
            d = pattern3(gr,dir,n);
        } else {
            d = pattern4(gr,dir,n);
        }
        
        gr = prevGr;
        gr = abs(gr)-0.42;
        gr*=Rot(radians(45.));

        float d2 = arrow(gr);
        d = min(d,d2);
        
        gr = prevGr;
        if(n>=0.65){
            d2 = length(gr-vec2(0.49,0.))-size;
            d = min(d,d2);

            gr = prevGr;
            gr-=vec2(-0.365,0.);
            gr*=Rot(radians(90.));

            d2 = Tri(gr,vec2(size*2.5));
            gr = prevGr;
            d2 = min(B(gr-vec2(-0.49,0.0),vec2(0.05)),d2);
            d = min(d,d2);
        } else {
            d2 = length(gr-vec2(-0.49,0.))-size;
            d = min(d,d2);

            gr = prevGr;
            gr-=vec2(0.365,0.);
            gr*=Rot(radians(-90.));

            d2 = Tri(gr,vec2(size*2.5));
            gr = prevGr;
            d2 = min(B(gr-vec2(0.49,0.0),vec2(0.05)),d2);
            d = min(d,d2);
        }
        
        gr = prevGr;
        gr.y = abs(gr.y)-0.49;
        d2 = length(gr)-size;
        d = min(d,d2);
    }
    return d;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    
    float thick = 0.008;
    float d = drawGraphics(p);
    col = mix(col,vec3(1.),S(abs(d)-thick,-0.01));

    glFragColor = vec4(sqrt(col),1.0);
}
