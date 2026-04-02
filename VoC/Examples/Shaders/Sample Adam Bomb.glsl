#version 420

// original https://www.shadertoy.com/view/wdXfWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}

vec3 lineTex(vec2 uv)
{
    float stripeSize = 50.0;
    float t = time*10.0;
    return vec3(tan((uv.x+uv.y+(-t/stripeSize))*stripeSize)*stripeSize,tan((uv.x+uv.y+(-t/stripeSize))*stripeSize)*stripeSize,tan((uv.x+uv.y+(-t/stripeSize))*stripeSize)*stripeSize);
}

vec3 bom(vec2 p, vec3 col){
    vec2 prevP = p;
    col = mix(col,vec3(0.0),S( length(p)-0.25,0.0)); // bg
    
    p.x*=0.95;
    col = mix(col,vec3(0.0),S( length(p-vec2(0.0,0.27))-0.07,0.0));
    
    p = prevP;
    float d = abs(length(p)-0.25)-0.005;
    
    vec2 p2 = p-vec2(0.0,0.3);
    p2.y*=1.7;
    
    d = max(-sdBox(p-vec2(0.0,0.25),vec2(0.07,0.05)),d);
    
    float d2 = abs(length(p2)-0.07)-0.006;
    d = min(d,d2);
    
    vec2 p3 = p-vec2(0.0,0.25);
    float d3 = abs(sdBox(p3,vec2(0.07,0.05)))-0.006;
    d3 = max(-(length(p2)-0.07),d3);
    d = min(d,d3);
    
    vec2 p4 = p-vec2(0.0,0.2);
    p4.y*=1.7;
    float d4 = abs(length(p4)-0.07)-0.006;
    d4 = max((p4.y),d4);
    d = min(d,d4);
    d = max(-(length(p4)-0.065),d);
    
    vec2 p5 = p-vec2(0.02,0.03);
    p5*=Rot(radians(-20.0));
    p5.x*=2.0;
    
    float d5 = length(p5)-0.07;
    d = min(d,d5);
    
    vec2 p6 = p-vec2(0.013,0.05);
    p6*=Rot(radians(-20.0));
    p6.x*=3.0;
    p6.y*=1.8;
    
    float d6 = length(p6)-0.07;
    d = max(-d6,d);
    
    vec2 p7 = p-vec2(0.12,0.09);
    p7*=Rot(radians(-20.0));
    p7.x*=2.0;
    p7.y*=1.1;
    
    float d7 = length(p7)-0.07;
    d = min(d,d7);
    
    vec2 p8 = p-vec2(0.115,0.105);
    p8*=Rot(radians(-20.0));
    p8.x*=3.2;
    p8.y*=2.0;
    
    float d8 = length(p8)-0.07;
    d = max(-d8,d);
    
    float d9 = length(p)-0.22;
    p.y*=0.8;
    float d10 = length(p)-0.2;
    d9 = max(-d10,d9);
    d9 = max(p.x,d9);
    p = prevP;
    
    float d11 = sdBox((p-vec2(0.0,0.15))*Rot(radians(-20.0)),vec2(0.3,0.015));
    d9 = max(-d11,d9);
    
    d = min(d,d9);

    vec2 p9 = p-vec2(0.1,-0.14);
    p9*=Rot(radians(-40.0));
    p9.y*=2.0;
    float d12 = length(p9)-0.08;
    
    vec2 p10 = p-vec2(0.16,-0.17);
    p10*=Rot(radians(0.0));
    p10.x*=2.0;
    float d13 = length(p10)-0.08;
    d12 = max(-d13,d12);
    
    d = min(d,d12);
    
    vec2 p11 = p-vec2(-0.04,0.2);
    float d14 = sdBox(p11,vec2(0.007,0.028));
    d = min(d,d14);
        
    vec2 p12 = p-vec2(-0.04,0.255);
    float d15 = sdBox(p12,vec2(0.007,0.011));
    d = min(d,d15);
    
    
    col = mix(col,vec3(1.0),S(d,0.0));
    
    
    vec2 p13 = p-vec2(0.0,0.37);
    const float k = 3.0;
    float c = cos(k*p13.y);
    float s = sin(k*p13.y);
    mat2  m = mat2(c,-s,s,c);
    
    
    d = sdBox((p13*m)*Rot(radians(10.0)),vec2(0.022,0.07));
    col = mix(col,lineTex(p),S(d,0.0));
    
    return col;
}

vec3 fire(vec2 p, vec3 col) {
    vec2 prevP = p;
    float d = sdTriangle(p,vec2(0.0,0.2),vec2(0.1,-0.2),vec2(-0.1,-0.2));
    
    p.x = abs(p.x);
    vec2 p2 = (p-vec2(0.15,-0.1));
    p2*=Rot(radians(45.0));
    
    float d2 = sdTriangle(p2,vec2(0.0,0.15),vec2(0.1,-0.1),vec2(-0.1,-0.1));
    d = min(d,d2);
    
    p2 = (p-vec2(0.15,-0.2));
    p2*=Rot(radians(100.0));
    d2 = sdTriangle(p2,vec2(0.0,0.3),vec2(0.06,-0.1),vec2(-0.06,-0.1));
    d = min(d,d2);
    
    p2 = (p-vec2(0.15,-0.25));
    p2*=Rot(radians(110.0));
    d2 = sdTriangle(p2,vec2(0.0,0.1),vec2(0.03,-0.1),vec2(-0.03,-0.1));
    d = min(d,d2);
    
    p2 = (p-vec2(0.15,-0.3));
    p2*=Rot(radians(130.0));
    d2 = sdTriangle(p2,vec2(0.0,0.23),vec2(0.06,-0.1),vec2(-0.06,-0.1));
    d = min(d,d2);
    
    col = mix(col,vec3(0.8,0.7,0.0),S(d,0.0));
    
    col = mix(col,vec3(0.7,0.3,0.0),S(abs(d)-0.01,0.0));
    return col;
}

vec3 chara(vec2 p, vec3 col) {
    vec2 prevP = p;
    
    p*=1.0+sin(time*6.0)*0.05;
    col = fire(p-vec2(0.0,0.43),col);
    
    p = prevP;
    col = bom(p,col);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec3 col = vec3(0.0);
    float t = time*0.1;
    
    uv-=t;
    uv*=1.5;
    uv.x = mod(uv.x,0.52)-0.26;
    uv.y = mod(uv.y,1.1)-0.55;
    col = bom(uv,col);
    uv = prevUV;
    
    uv-=t;
    uv*=1.5;
    uv.x += 0.26;
    uv.x = mod(uv.x,0.52)-0.26;
    
    uv.y -= 0.55;
    uv.y = mod(uv.y,1.1)-0.55;
    
    col = bom(uv,col);
    
    uv = prevUV;
    uv*=1.5;
    col = chara((uv-vec2(0.7,0.35))*Rot(radians(120.0)),col);
    
    uv = prevUV;
    uv*=1.2;
    col = chara((uv-vec2(-0.6,0.2))*Rot(radians(200.0)),col);
        
    uv = prevUV;
    uv*=1.3;
    col = chara((uv-vec2(0.85,-0.35))*Rot(radians(260.0)),col);
    
    uv = prevUV;
    col = chara(uv-vec2(0.0,-0.2),col);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
