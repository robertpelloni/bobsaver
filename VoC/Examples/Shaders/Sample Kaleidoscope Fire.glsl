#version 420

// original https://www.shadertoy.com/view/3sSfDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdEquilateralTriangle( in vec2 p )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float sdStar5(in vec2 p, in float r, in float rf)
{
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x,k1.y);
    p.x = abs(p.x);
    p -= 2.0*max(dot(k1,p),0.0)*k1;
    p -= 2.0*max(dot(k2,p),0.0)*k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf*vec2(-k1.y,k1.x) - vec2(0,1);
    float h = clamp( dot(p,ba)/dot(ba,ba), 0.0, r );
    return length(p-ba*h) * sign(p.y*ba.x-p.x*ba.y);
}

float sdHorseshoe( in vec2 p, in vec2 c, in float r, in vec2 w )
{
    p.x = abs(p.x);
    float l = length(p);
    p = mat2(-c.x, c.y, 
              c.y, c.x)*p;
    p = vec2((p.y>0.0)?p.x:l*sign(-c.x),
             (p.x>0.0)?p.y:l );
    p = vec2(p.x,abs(p.y-r))-w;
    return length(max(p,0.0)) + min(0.0,max(p.x,p.y));
}

float circle(in vec2 p, in float r ) {
    return length(p) - r;
}

float map(in vec2 p){    
    float d1 = sdEquilateralTriangle(p*0.5);
    float d2 = sdStar5(p*0.1, 1.0, 0.4);
    float d3 = sdStar5(p*0.2, 1.0, 0.4);
    //float d4 = sdHorseshoe(p-vec2(2.0,-0.1), vec2(0.4, -1.5), 1.5, vec2(0.750,0.25));
    float d4 = circle(p, 8.0);
    return min(min(d1, max(d2,-d3)), -d4);
}

vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

vec2 modMirror2(inout vec2 p, vec2 size) {
  vec2 halfsize = size*0.5;
  vec2 c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  p *= mod(c,vec2(2.0))*2.0 - vec2(1.0);
  return c;
}

vec3 postProcess(in vec3 col, in vec2 q) 
{
  col=pow(clamp(col,0.0,1.0),vec3(0.45)); 
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);  // satuation
  col*=vec3(0.15+0.85*pow(29.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7));  // vigneting
  return col;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 uv = -1. + 2. * q;
    uv.x *= resolution.x/resolution.y;
    
    float sc = 25.0;
    vec2 p = uv*sc;
    p = toPolar(p);
    modMirror2(p, vec2(150., 2.*PI/16.));
    p = toRect(p);
    modMirror2(p, vec2(15., 15.));
    p = rotate(p, time*0.5*PI);
    float d = map(p + vec2(0.4, 0)) / sc;
    
    float r = smoothstep(0.0, 0.001, d);
    float g = smoothstep(0.0, 0.01, d);
    float b = smoothstep(0.0, 0.1, d);
    
    vec3 color = vec3(r, g ,b);
    //color = 1.0 - color;
    color = postProcess(color, q);
    glFragColor = vec4(color, 1.0);
}
