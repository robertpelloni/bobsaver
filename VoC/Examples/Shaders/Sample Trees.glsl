#version 420

// original https://www.shadertoy.com/view/wljBDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

const float pi = 3.1459;

vec2 hash( vec2 p ) // replace this by something better
{
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
    vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, vec3(70.0) );
}

float tree(int seed, vec2 uv, float scale){
    float theta = pi/2.;
    float dotperp = 0.;
    float minp = 1000.;
    scale = noise(vec2(seed+10,seed+100))*0.5+.5;
    
    vec2 rando = vec2(noise(uv*2.+vec2(seed)),noise(uv*2.+vec2(seed+100)));
    vec2 pos = vec2(noise(vec2(seed+5,seed))*2.-.4,-0.2-scale);
    uv += rando*0.015;
    rando = vec2(noise(uv/3.+vec2(seed+100)),noise(uv/3.+vec2(seed+200)));
    uv += rando*0.1;

    
    int path = seed;
    for(int i=0; i<8; i++){
  
  
        vec2 pa = uv-pos;
        vec2 dir = vec2(cos(theta),sin(theta));
        vec2 ba = dir*scale;
        vec2 perp = vec2(dir.y,-dir.x);
        dotperp = dot(perp,pa);
        bool side = dotperp>0.;
        path = path*2+int(side);
        float newtheta = theta - (float(side)*2.-1.)*0.25*(sin(time/scale*0.5+float(seed))*0.03+1.)/(float(i)*0.2+1.);
        pos +=vec2(cos(theta),sin(theta))*scale;
        float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
        float len = length( pa - ba*h )-0.02*(1.+(1.-h))*scale;
        minp = min(len,minp);
        theta = newtheta;
        //theta += (rand(vec2(float(path*10),0.))*2.-1.)*0.3;
        scale = scale/2.*(1.+rand(vec2(float(path*10),0.))*.3);
    }
    return minp;
}

void main(void)
{
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.-1.;
/*
    float minp = 
        min(min(
            tree(0,uv,vec2(-0.3,-1),0.6),
            tree(7,uv,vec2(0.2,-1),0.7)),
            tree(10000,uv,vec2(0.,-1),0.3));
*/
    float minp = 1000.;
    for(int i=0; i<30; i++){
        minp = min(minp,tree(i,uv,0.6));
    }
    
    float fill = max(0.,min(1.,minp/0.002));
    glFragColor = vec4(vec3(fill),1.0);
}

