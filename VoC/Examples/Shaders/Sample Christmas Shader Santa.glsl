#version 420

// original https://www.shadertoy.com/view/7lGXzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p.x)-s.x,abs(p.y)-s.y)
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )

vec3 santa(vec2 p, vec3 col){
    vec2 prevP = p;
    
    // shadow
    p.x*=0.5;
    p.y*=1.5;
    p.y+=0.5;
    float d = length(p)-0.2;
    col = mix(col,vec3(0.0),S(d,-0.3));     
    
    // body
    p = prevP;
    d = B(p,vec2(0.2,0.17));
    p.x = abs(p.x)-0.15;
    float a = radians(10.0);
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    float d2 = d;
    col = mix(col,vec3(0.7,0.0,0.0),S(d,0.0));
    
    d = max(p.y+0.13,d);
    col = mix(col,vec3(1.0),S(d,0.0));
    
    d2 = max(abs(p.y+0.08)-0.016,d2);
    col = mix(col,vec3(0.0),S(d2,0.0));   
    
    p = prevP;
    p.y+=0.078;
    d = abs(B(p,vec2(0.03,0.02)))-0.005;
    col = mix(col,vec3(0.7,0.7,0.3),S(d,0.0)); 
    p = prevP;
    
    // legs
    p.x = abs(p.x)-0.12;
    p.y+=0.25;
    d = B(p,vec2(0.01,0.08));
    col = mix(col,vec3(0.7,0.0,0.0),S(d,0.0));
    
    p.y+=0.05;
    d = B(p,vec2(0.01,0.03));
    col = mix(col,vec3(0.0),S(d,0.0));
    
    p.x-=0.02;
    p.y+=0.02;
    d = B(p,vec2(0.02,0.01));
    col = mix(col,vec3(0.0),S(d,0.0));
    
    // arm
    p = prevP;
    p.x = abs(p.x)-0.21;
    
    float frame = mod(time,1.);
    if(frame<0.5){
        p.y-=0.05;
        p*=Rot(radians(-60.0));
    } else {
        p.y-=0.13;
        p*=Rot(radians(-120.0));
    }
    
    d = B(p,vec2(0.01,0.1));
    col = mix(col,vec3(0.7,0.0,0.0),S(d,0.0));
    
    p.y+=0.12;
    d = B(p,vec2(0.01,0.02));
    col = mix(col,vec3(0.0),S(d,0.0));
    
    p.x-=0.015;
    p.y-=0.008;
    d = B(p,vec2(0.005,0.007));
    col = mix(col,vec3(0.0),S(d,0.0));
    
    // face and head
    p = prevP;
    p.y-=0.17;
    p.y*=0.8;
    d = length(p)-0.14;
    col = mix(col,vec3(1.0),S(d,0.0));    
    
    p = prevP;
    p.y-=0.25;
    p.y*=1.25;
    d = length(p)-0.125;
    col = mix(col,vec3(0.9,0.7,0.6),S(d,0.0));
    
    // face details
    p = prevP;
    p.y-=0.2;
    p.x = abs(p.x)-0.07;
    p*=Rot(radians(10.0));
    p.x*=0.7;
    p.y*=0.9;
    d = length(p)-0.08;
    p.y-=0.07;
    d2 = length(p)-0.08;
    d = max(-d2,d);
    col = mix(col,vec3(.99,0.95,0.8),S(d,0.0));
    p = prevP;
    p.y-=0.21;
    p.y*=1.5;
    d = length(p)-0.03;
    col = mix(col,vec3(.8,0.6,0.5),S(d,0.0));
    p = prevP;
    p.y-=0.13;
    p.y*=0.8;
    d = length(p)-0.01;
    col = mix(col,vec3(.5,0.2,0.2),S(d,0.0));
    
    p = prevP;
    p.x = abs(p.x)-0.07;
    p.y-=0.255;
    p*=Rot(radians(20.0));
    p.y*=2.5; 
    
    d = length(p)-0.04;
    col = mix(col,vec3(1.0),S(d,0.0));
    
    p = prevP;
    p.x = abs(p.x)-0.04;
    p.y-=0.235;
    d = length(p)-0.008;
    col = mix(col,vec3(0.0),S(d,0.0));
    
    // hat
    p = prevP;
    p.y-=0.43;
    d = B(p,vec2(0.15,0.12));
    a = radians(10.);
    p.x+=0.13;
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    a = radians(52.);
    p.y-=0.43;
    p.x+=0.04;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    col = mix(col,vec3(0.7,0.0,0.0),S(d,0.0));
    p = prevP;
    p.y-=0.3;
    d = B(p,vec2(0.12,0.02));
    col = mix(col,vec3(1.0),S(d,0.0));
    p.x+=0.14;
    p.y-=0.21;
    d = length(p)-0.03;
    col = mix(col,vec3(1.0),S(d,0.0));
    
    return col;
}

float snowflake(vec2 p){
    p*=Rot(radians(time*30.0));
    p = DF(p,1.5);
    p -= vec2(0.04);
    p*=Rot(radians(45.0));
    
    float d = B(p,vec2(0.003,0.055));
    p.x = abs(p.x)-0.01;
    p*=Rot(radians(-25.0));
    d = min(B(p,vec2(0.02,0.003)),d);
    p.y-=0.025;
    d = min(B(p,vec2(0.02,0.003)),d);
    return d;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 prevP = p;
    
    vec3 col = vec3(0.8);
    
    p.y-=0.15;
    p.x = abs(p.x)-0.5;
    p.x*=1.5+cos(time*6.0)*0.05;
    p.y*=1.5+sin(time*6.0)*0.03; 
    
    col = santa(p-vec2(0.0,-0.1),col);
    
    p = prevP;
    p.x*=1.0+cos(time*6.0)*0.05;
    p.y*=1.0+sin(time*6.0)*0.03; 
    
    col = santa(p-vec2(0.0,-0.1),col);
    
    p = prevP;
    p*=2.0;
    p.x += -1.75;
    p.x+=sin(time*0.5)*2.0;
    for(int i = 1; i<=20; i++){
        vec3 pt = vec3(0);
        p.x += float(i)/20.0*0.6;
        p.y += mod((time*0.1)+float(i),4.0)-2.0;
        float d = snowflake(p);
        col = mix(col, vec3(1.0),S(d,0.0));
    }
    
    glFragColor = vec4(col,1.0);
}
