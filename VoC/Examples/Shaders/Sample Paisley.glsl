#version 420

// original https://www.shadertoy.com/view/wldcRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define BASE_COLOR vec3(0.3,0.6,0.3)

vec2 bend(vec2 p, float k){
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec2  q = p*m;
    return q;
}

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r*r-d*d);
    return ((p.y-b)*d>p.x*b) ? length(p-vec2(0.0,b))
                             : length(p-vec2(-d,0.0))-r;
}

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdUnevenCapsule( vec2 p, float r1, float r2, float h )
{
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,vec2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
    return dot(p, vec2(a,b) ) - r1;
}

float paiselyDist(vec2 p, float sy, float scale) {
    vec2  q = bend(p,1.5);

    q.y*=sy*scale;
    q*=0.8*scale;
    float d = sdUnevenCapsule(q,0.15,0.02*scale,0.35*scale);
    return d;
}

vec3 paiselyTex(vec2 p, vec3 col, float dir, float t) {
    p*=Rot(radians(t*30.0*dir));
    p*=1.2;
    vec2 prevP = p;
    p = abs(p);
    p -= vec2(0.05,0.05);
    float d = abs(sdVesica(p*Rot(radians(45.0)),0.1,0.07))-0.005;
    col = mix(col,BASE_COLOR,S(d,0.0));
    
    p = prevP;
    
    p *= Rot(radians(45.0));
    p = abs(p);
    p -= vec2(0.05,0.05);
    d = abs(sdVesica(p*Rot(radians(45.0)),0.1,0.07))-0.005;
    col = mix(col,BASE_COLOR,S(d,0.0));
    
    return col;
}

vec3 paisely(vec2 p, vec3 col, float t) {
    vec3 baseCol = BASE_COLOR;
    vec2 pos = vec2(0.0,-0.1);
    vec2 prevP = p;
    float d = abs(paiselyDist(p-pos,0.9,0.88))-0.002;
    float d2 = abs(paiselyDist(p-pos,0.87,1.05))-0.001;
    float d3 = abs(paiselyDist(p-pos,0.85,1.25))-0.003;
    float d4 = abs(paiselyDist(p-pos,0.9,0.82))-0.001;
    col = mix(col,baseCol,S(d,0.0));
    col = mix(col,baseCol*1.2,S(d2,0.0));
    col = mix(col,baseCol,S(d3,0.0));
    col = mix(col,baseCol,S(d4,0.0));
    
    p*=3.2;
    col = paiselyTex(p-vec2(0.4,0.55),col,1.0,t);
    
    p = prevP;
    p*=1.8;
    col = paiselyTex(p-vec2(0.11,0.15),col,-1.0,t);
    
    p = prevP;
    col = paiselyTex(p-vec2(0.01,-0.11),col,1.0,t);
    
    p = prevP;
    p*=3.5;
    col = paiselyTex(p-vec2(-0.13,0.13),col,1.0,t);
    
    p = prevP;
    p*=2.8;
    col = paiselyTex(p-vec2(0.1,-0.82),col,-1.0,t);
    
    p = prevP;
    p*=3.2;
    col = paiselyTex(p-vec2(-0.2,-0.89),col,1.0,t);
    
    p = prevP;
    p*=3.2;
    col = paiselyTex(p-vec2(0.4,-0.78),col,1.0,t);
        
    p = prevP;
    p*=4.2;
    col = paiselyTex(p-vec2(1.15,1.25),col,1.0,t);
    
    p = prevP;
    
    p.x -=0.01;
    p.x = abs(p.x);
    p.x -= 0.15;
    d = length(p-vec2(0.01,0.0))-0.02;
    col = mix(col,baseCol,S(d,0.0));
    
    p = prevP;
    p.x = abs(p.x);
    p.x -= 0.18;
    d = length(p-vec2(0.0,-0.12))-0.02;
    col = mix(col,baseCol,S(d,0.0));
    
    p = prevP;
    d = length(p-vec2(-0.14,-0.22))-0.02;
    col = mix(col,baseCol,S(d,0.0));
    
    d = length(p-vec2(-0.072,0.11))-0.02;
    col = mix(col,baseCol,S(d,0.0));
    
    d = length(p-vec2(0.063,0.215))-0.013;
    col = mix(col,baseCol,S(d,0.0));
        
    d = length(p-vec2(0.187,0.13))-0.017;
    col = mix(col,baseCol,S(d,0.0));
    
    return col;
}

vec3 renderTexture(vec2 p, vec3 col, float t) {
    p*=1.3;
    
    vec2 prevP = p;
    
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,0.8)-0.4;
    col = paisely(p,col,t);
    p = prevP;
        
    p.y+=0.1;
    p.x+=0.475;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,0.8)-0.4;
    
    p*=1.2;
    col = paisely(p*Rot(radians(-180.0)),col,t);
    p = prevP;
    
    p.x+=0.3;
    p.y+=-0.35;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,0.8)-0.4;
    p*=1.8;
    col = paisely(p*Rot(radians(120.0)),col,t);
    p = prevP;
    
    p.x+=0.08;
    p.y+=-0.31;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,0.8)-0.4;
    p*=1.2;
    col = paiselyTex(p,col,1.0,t);
    p = prevP;
        
    p.x+=0.28;
    p.y+=-0.57;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,0.8)-0.4;
    p*=1.8;
    col = paiselyTex(p,col,-1.0,t);
    p = prevP;
            
    p.x+=0.56;
    p.y+=-0.3;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,0.8)-0.4;
    p*=2.1;
    col = paiselyTex(p,col,1.0,t);
    
    return  col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float t = time*0.1;
    
    uv.y+=t;
    
    vec2 prevUV = uv;
    vec3 col = vec3(0.99,0.98,0.95);

    float t2 = mod(time,8000.0);
    col = renderTexture(uv,col,t2);
    
    glFragColor = vec4(col,1.0);
}
