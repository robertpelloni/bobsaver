#version 420

// original https://www.shadertoy.com/view/3dyfzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define skew(x, y) mat2(1,tan(x),tan(y),1)
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdEquilateralTriangle( in vec2 p )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
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

// noise and fbm function from https://www.shadertoy.com/view/Xd3GD4
//-----------------------------------------------------------------------------
vec2 hash( vec2 p )
{
    p = vec2( dot(p,vec2(127.1,311.7)),
             dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise2d( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    
    vec2 i = floor( p + (p.x+p.y)*K1 );
    
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;
    
    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    
    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    
    return dot( n, vec3(70.0) );
}

float fbm(vec2 uv)
{
    float f;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise2d( uv ); uv = m*uv;
    f += 0.2500*noise2d( uv ); uv = m*uv;
    f += 0.1250*noise2d( uv ); uv = m*uv;
    f += 0.0625*noise2d( uv ); uv = m*uv;
    f = 0.5 + 0.5*f;
    return f;
}

float textile1Dist(vec2 p) {
    vec2 prevUV = p;
    vec3 col = vec3(0);
    
    p.x *=0.8;
    const float k = -5.5;
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec2  q = p*m;
    prevUV = q;
    
    float smallMaskSize = 0.055;
    float d = length(q)-0.1;
    q.x = abs(q.x);
    q.x *= 0.8;
    float d2 = length(q-vec2(0.059,0.035))-smallMaskSize;
    d = max(-d2,d);

    d = max(-(p.y-0.009),d);
    return d;
}

vec3 textile1(vec2 uv, vec3 col, float ratio) {
    vec2 prevUV = uv;
    float d = length(uv)-0.125;
    col = mix(col,vec3(0.9,0.3,0.6)*(ratio+0.9),S(d,0.0));
    
    d = textile1Dist(uv*Rot(radians(20.0)));
    uv*=-1.0;
    float d2 = textile1Dist(uv*Rot(radians(-45.0)));
    d = min(d,d2);
    uv = prevUV;
    d2 = textile1Dist(uv*Rot(radians(-100.0)));
    d = min(d,d2);
    
    uv*=61.0;
    d2 = sdEquilateralTriangle(uv*Rot(radians(77.0)));
    d = min(d,d2);
    col = mix(col,vec3(1.0,0.7,0.8)*(ratio+0.9),S(d,0.0));
    return col;
}

vec3 textileLayer1(vec2 uv, vec3 col, float scale, float i) {
    uv*=scale;
    uv.x+=0.35;
    uv = mod(uv,0.8)-0.4;
    col = textile1(uv*Rot(radians(time*-50.0*scale)),col,i);
    return col;
}

float bgTexDist(vec2 uv) {
    uv.x = abs(uv.x);
    uv.x -= 0.02;
    uv.x*=-1.0;
    uv*=0.7;
    vec2 prevUV = uv;
    uv.y = abs(uv.y);
    uv.y-=0.053;
    float d = sdTriangle(uv,vec2(0.005,-0.025),vec2(-0.01,-0.05),vec2(-0.035,-0.05));
    uv = prevUV;
    float d2 = sdTriangle(uv,vec2(-0.005,0.0),vec2(0.01,0.025),vec2(0.01,-0.025));
    d = min(d,d2);
    return d;
}

vec3 bg(vec2 uv, vec3 col) {
    vec2 prevUV = uv;
    uv.x = mod(uv.x,0.18)-0.09;
    uv.y = mod(uv.y,0.1)-0.05;
    float d = bgTexDist(uv);
    
    uv = prevUV;
    uv.x -= 0.09;
    uv.y -= 0.25;    
    uv.x = mod(uv.x,0.18)-0.09;
    uv.y = mod(uv.y,0.1)-0.05;
    
    float d2 = bgTexDist(uv);
    d = min(d,d2);
    col = mix(col,vec3(0.9),S(d,0.0));
    return col;
}

float leaf(vec2 uv) {
    float sc = mix(0.01,2.0,smoothstep(0.3,-0.3,uv.y));
    uv.x *= 2.0*sc;
    float d = length(uv)-0.08;
    return d;
}

vec3 flower(vec2 uv, vec3 col, vec3 baseCol){
    float leafNum = 5.0;
    float deg = 360.0/leafNum;
    float leafDist = 0.09;
    float d = 1.0;
    for(float i = 0.0; i<5.0; i+=1.0) {
        float rad = radians(i*deg);
        float x = cos(rad)*leafDist;
        float y = sin(rad)*leafDist;
        
        vec2 pos = uv;
        pos.x -= x;
        pos.y -= y;
        pos*=Rot(-rad-radians(-90.0));
        float d2 = leaf(pos);
        d = min(d,d2);
    }
    float d3 = length(uv)-0.02;
    d = min(d,d3);
    col = mix(col,baseCol,S(d,0.0));
    return col;
}

vec3 textile2(vec2 uv, vec3 col, float ratio) {
    col = flower(uv*Rot(radians(35.0)),col, vec3(0.9,0.5,1.0)*(ratio+0.9));
    col = flower(uv,col, vec3(0.7)*(ratio+0.9));
    col = flower(uv*1.1,col, vec3(0.6,0.1,0.8)*(ratio+0.9));
    return col;
}

vec3 textileLayer2(vec2 uv, vec3 col, float scale, float i) {
    uv*=scale;
    uv.x+=0.35;
    uv = mod(uv,0.8)-0.4;
    col = textile2(uv*Rot(radians(time*50.0*scale)),col,i);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec3 col = vec3(1);
    
    uv.y+=time*0.05;
    col = bg(uv,col);       
    
    uv = prevUV;
    for(float i = 0.; i<1.0; i+=1.0/3.0) {
        float z = mix(-0.6,-0.1,i);
        
        uv.x += (fract(0.3+i*5.0));
        uv.y+= (i*0.3)-0.1;
        uv.y+=time*(0.08*i+0.15);
       
        col = textileLayer2(uv,col,0.4+((1.0-i)*2.2+z),i); 
        
        uv = prevUV;
        uv.y+= (i*0.8)-0.1;
        uv.y+=time*(0.1*i+0.1);
        uv.x += (fract(0.2+i*2.0));
        uv.x+=sin(time*0.5)*0.3;
       
        col = textileLayer1(uv,col,0.4+((1.0-i)*2.0+z),i);
    }
    
    uv = prevUV;
    uv*=2.0;
    float smokeD = (length(uv)*0.9)*fbm(uv - vec2(cos(time*0.3)*2.5,sin(time*0.1)*2.5));
    col *= mix( col, vec3(1.5,1.0,0.7), S(smokeD,1.1) );
        
    glFragColor = vec4(col,1.0);
}
