#version 420

// original https://www.shadertoy.com/view/dsS3Wd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Tri(p,s,a) max(-dot(p,vec2(cos(-a),sin(-a))),max(dot(p,vec2(cos(a),sin(a))),max(abs(p).x-s.x,abs(p).y-s.y)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define Skew(a,b) mat2(1.0,tan(a),tan(b),1.0)
#define SkewX(a) mat2(1.0,tan(a),0.0,1.0)
#define SkewY(a) mat2(1.0,0.0,tan(a),1.0)
#define SymdirX(p) mod(floor(p).x,2.)*2.-1.
#define SymdirY(p) mod(floor(p).y,2.)*2.-1.

float Hash21(vec2 p) {
    p = fract(p*vec2(234.56,789.34));
    p+=dot(p,p+34.56);
    return fract(p.x+p.y);
}

float thunderIcon(vec2 p){
    float dir = SymdirY(p);
    p.x = abs(p.x)-0.17;
    vec2 prevP2 = p;
    p.y+=time*0.15*dir;
    p.y = mod(p.y,0.1)-0.05;
    vec2 prevP = p;
    
    vec2 size = vec2(0.01,0.04);
    float a = radians(-25.);
    
    p.x+=0.008;
    p.y-=0.035;
    float d = B(p,size);
    p.x-=0.01;
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    
    p = prevP;
    p.x-=0.008;
    p.y+=0.035;
    a = radians(-25.);
    float d2 = B(p,size);
    p.x+=0.01;
    d2 = max(dot(p,vec2(cos(a),sin(a))),d2);
    
    d = min(d,d2);
    
    return abs(d)-0.0005;
}

float arrow(vec2 p){
    float dir = SymdirY(p);
    p.x = abs(p.x)-0.05;
    vec2 prevP = p;
    
    p.y+=(0.1*time)*dir;
    
    p.y=mod(p.y,0.07)-0.035;
    p.y+=0.025;
    if(dir == 1.){
        p.y-=0.05;
    }
    p.y*=dir*-1.;
    float a = radians(60.);
    p.x = abs(p.x)-0.1;
    float d = dot(p,vec2(cos(a),sin(a)));
    p.y+=0.03;
    float d2 = dot(p,vec2(cos(a),sin(a)));
    d = max(-d2,d);
    p = prevP;
    
    d = max(abs(p.x)-0.04,d);
    
    return abs(d)-0.0005;
}

float arrowItem (vec2 p){
    vec2 prevP = p;
    float dist = 0.16;
    p.x = abs(p.x)-dist;
    p*=SkewX(radians(45.));
    float d = B(p,vec2(0.04,0.01));
    
    p = prevP;
    p.x = abs(p.x)-dist;
    p-=vec2(-0.04,0.07);
    p*=SkewY(radians(45.));
    float d2 = B(p,vec2(0.01,0.07));
    d = abs(min(d,d2))-0.0005;
    
    p =  prevP;
    p.y-=time*0.23;
    p.y = mod(p.y,0.3)-0.15;

    p.x = abs(p.x)-dist;
    p-=vec2(-0.04,0.0);
    p*=SkewY(radians(45.));
    d2 = B(p,vec2(0.01,0.1));
    p = prevP;
    d2 = max(-p.y+0.16,d2);
    
    p.x = abs(p.x);
    float a = radians(45.);
    
    p.y-=0.3;
    d2 = max(-dot(p,vec2(cos(a),sin(a))),d2);
    
    d = abs(min(d,d2))-0.0005;
    
    return d;
}

float arrows(vec2 p){
    vec2 prevP = p;
    p*=Rot(radians(45.));
    float d = arrow(p);
    
    p = prevP;
    p*=Rot(radians(-45.));
    float d2 = arrow(p);
    
    d = min(d,d2);
    
    p = prevP;
    p*=Rot(radians(45.));
    
    d2 = B(p,vec2(0.32));    
    d = max(-d2,d);
    
    p = prevP;
    
    p*=Rot(radians(45.));
    p.y=abs(p.y)-0.34;
    
    d2 = arrowItem(p);
    d = min(d,d2);
    
    p = prevP;
    
    p*=Rot(radians(-45.));
    p.y=abs(p.y)-0.34;
    
    d2 = arrowItem(p);
    d = min(d,d2);    
    

    p = prevP;
    p*=Rot(radians(-45.));
    d2 = thunderIcon(p);
    
    p = prevP;
    p*=Rot(radians(45.));
    float d3 = thunderIcon(p); 
    d2 = min(d2,d3);
    
    p = prevP;
    p*=Rot(radians(45.));
    
    float mask = B(p,vec2(0.38));    
    d2 = max(-mask,d2);
    
    
    d = min(d,d2);   
    
    return d;
}

float arrow2(vec2 p){
    vec2 prevP = p;

    float dir = SymdirY(p);
    p.y-=0.03;
    p.y+=(0.1*time)*dir;
    p.y=mod(p.y,0.08)-0.04;
    p.x = abs(p.x)-0.04;
    p*=SkewY(radians(45.*dir*-1.));
    float d = abs(B(p,vec2(0.025,0.015)))-0.0005;

    return d;
}

float arrowItem2 (vec2 p, float dist){
    vec2 prevP = p;
    p.x = abs(p.x)-dist;
    float d = B(p,vec2(0.0119,0.057));
    
    p = prevP;
    p.x = abs(p.x)-dist;
    p-=vec2(0.025,0.075);
    p*=Rot(radians(-45.));
    float d2 = B(p,vec2(0.04,0.0125));
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x)-dist;
    p-=vec2(0.0487,0.225);
    d2 = B(p,vec2(0.0127,0.13));
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x);
    float a = radians(45.);
    
    p.y-=0.49;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
        
    
    return abs(d)-0.0005;
}

float arrows2(vec2 p){
    vec2 prevP = p;
    float d = arrow2(p);
    
    p*=Rot(radians(90.));
    float d2 = arrow2(p);
    
    d = min(d,d2);
    
    p = prevP;
    p*=Rot(radians(45.));
    
    d2 = B(p,vec2(0.32));    
    d = max(-d2,d);
    
    p = prevP;
    
    p.x = abs(p.x)-0.47;
    p*=Rot(radians(90.));
    d2 = arrowItem2(p,0.095);
    d = min(d,d2);
    
    p = prevP;
    
    p.y = abs(p.y)-0.47;
    d2 = arrowItem2(p,0.095);
    d = min(d,d2);    
    
    p = prevP;
    p.x = abs(p.x)-0.6;
    p.x -= 0.05;
    p.y = abs(p.y)-0.1;
    p.x = mod(p.x,0.08)-0.04;
    d2 = abs(length(p)-0.01)-0.001;
    p = prevP;
    d2 = max(-(abs(p.x)-0.58),d2);
    d = min(d,d2); 
    
    p = prevP;
    p.x = abs(p.x)-0.46;
    p.y = abs(p.y)-0.17;
    d2 = abs(Tri(p,vec2(0.035),radians(45.)))-0.001;
    d = min(d,d2); 
    
    p = prevP;
    p.x = abs(p.x)-0.17;
    p.y = abs(p.y)-0.46;
    p*=Rot(radians(90.));
    d2 = abs(Tri(p,vec2(0.035),radians(45.)))-0.001;
    d = min(d,d2);     
    
    p = prevP;
    p.x = abs(p.x)-0.505;
    p.y = abs(p.y)-0.18;
    p*=Rot(radians(45.));
    d2 = abs(B(p,vec2(0.03,0.01)))-0.001;
    d = min(d,d2); 
        
    p = prevP;
    p.x = abs(p.x)-0.18;
    p.y = abs(p.y)-0.505;
    p*=Rot(radians(45.));
    d2 = abs(B(p,vec2(0.03,0.01)))-0.001;
    d = min(d,d2); 
    
    return d;
}

float shapeBase(vec2 p, float s, int mode){
    vec2 prevP = p;
    p*=10.;

    if(mode ==1){
        p = abs(p);
        p-=time*0.5;
    } else {
        p*=2.;
        p.x-=0.2;
        p.y+=time*1.;
    }
    
    vec2 id = floor(p);
    vec2 gv = fract(p)-0.5;
    
    float n = Hash21(id);
    
    float w = 0.1;
    if(n<0.5 || n>=0.8){
        float dir = (n>=0.8)?1.0:-1.0;
        gv*=Rot(radians(dir*45.0));
        if(mode ==1){
            gv.x = abs(gv.x);
        }
        gv.x-=0.355;
    } else {
        w = 0.135;
    }
    
    w*=s;
    float d = B(gv,vec2(w,1.));
    return d;
}

float centerItem(vec2 p){
    vec2 prevP = p;

    float d = shapeBase(p,1.,1);
    
    p = prevP;
    p*=Rot(radians(45.));
    float d2 = B(p,vec2(0.2));
    d = max(d2,d);
    
    d2 = abs(B(p,vec2(0.22)))-0.005;
    p = prevP;
    d2 = max(abs(p.x)-0.1,d2);
    d = min(d,d2);
    
    p*=Rot(radians(45.));
    d2 = abs(B(p,vec2(0.22)))-0.005;
    p = prevP;
    d2 = max(abs(p.y)-0.1,d2);
    d = min(d,d2);
    
    p*=Rot(radians(45.));
    d2 = abs(B(p,vec2(0.24)))-0.001;
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x)-0.2;
    p.y-=0.2;
    p*=Rot(radians(-225.));
    d2 = shapeBase(p,1.,0);
    
    d2 = max(abs(p.x)-0.02,d2);
    d2 = max(abs(p.y)-0.3,d2);
    p = prevP;
    d2 = max(-p.y,d2);
    
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x)-0.2;
    p.y+=0.2;
    p*=Rot(radians(225.));
    d2 = shapeBase(p,1.,0);
    
    d2 = max(abs(p.x)-0.02,d2);
    d2 = max(abs(p.y)-0.3,d2);
    p = prevP;
    d2 = max(p.y,d2);
    d = min(d,d2);    
    
    
    return d;
}

float circleItem(vec2 p){
    vec2 prevP = p;
    p*=Rot(radians(time*-30.));
    p = DF(p,2.);
    p -= vec2(0.06);
    p*=Rot( radians(-45.+sin(time*2.)*-10.));
    
    p.x*=2.;
    float d = abs(Tri(p,vec2(0.025),radians(45.)))-0.002;
    p = prevP;
    float d2 = abs(length(p)-0.05)-0.002;
    d = min(d,d2);
    d2 = length(p)-0.02;
    d = min(d,d2);
    return d;
}

float circleItems(vec2 p){
    vec2 prevP = p;
    
    p.x = abs(p.x)-0.77;
    p.y = abs(p.y)-0.32;
    float d = circleItem(p);
    
    p = prevP;
    p.x = abs(p.x)-0.61;
    p.y = abs(p.y)-0.21;
    p*=Rot(radians(45.));
    float d2 = B(p,vec2(0.07,0.04));
    float a = radians(-45.);
    p.y+=0.03;
    d2 = max(dot(p,vec2(cos(a),sin(a))),d2);
    
    d = min(d,abs(abs(d2)-0.01)-0.001);
    
    p = prevP;
    p.x = abs(p.x)-0.815;
    p.y = abs(p.y)-0.19;
    p*=Rot(radians(-90.));
    d2 = abs(Tri(p,vec2(0.04),radians(45.)))-0.001;
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x)-0.63;
    p.y = abs(p.y)-0.32;    
    d2 = abs(length(p)-0.015)-0.001;
    d = min(d,d2);
        
    p = prevP;
    p.x = abs(p.x)-0.84;
    p.y = abs(p.y)-0.46;    
    d2 = abs(length(p)-0.025)-0.001;
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x)-0.77;
    p.y = abs(p.y)-0.46;    
    d2 = abs(length(p)-0.013)-0.001;
    d = min(d,d2);    
        
    p = prevP;
    p.x = abs(p.x)-0.7585;
    p.y = abs(p.y)-0.186;
    d2 = abs(B(p,vec2(0.04,0.006)))-0.001;
    d = min(d,d2);  
    
    return d;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 prevP = p;
    vec3 col = vec3(0.);

    float d = centerItem(p);
    col = mix(col,vec3(1.),S(d,0.0));
    
    d = arrows2(p);
    
    float d2 = arrows(p);
    d = min(d,d2);
    d2 = circleItems(p);
    d = min(d,d2);
    
    col = mix(col,vec3(0.5),S(d,0.0));
    
    
    glFragColor = vec4(sqrt(col),1.0);
}
