#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

// distance function from Hartverdrahtet
// ( http://www.pouet.net/prod.php?which=59086 )
float hartverdrahtet(vec3 f)
{
    vec3 cs=vec3(.808,.808,1.167);
    float fs=1.;
    vec3 fc=vec3(0);
    float fu=10.;
    float fd=.763;
    
    // scene selection
    int i = int(mod(time/2.0, 9.0));
    if(i==0) cs.y=.58;
    if(i==1) cs.xy=vec2(.5);
    if(i==2) cs.xy=vec2(.5);
    if(i==3) fu=1.01,cs.x=.9;
    if(i==4) fu=1.01,cs.x=.9;
    if(i==6) cs=vec3(.5,.5,1.04);
    if(i==5) fu=.9;
    if(i==7) fd=.7,fs=1.34,cs.xy=vec2(.5);
    if(i==8) fc.z=-.38;
    
    //cs += sin(time)*0.2;
        
    float v=1.;
    for(int i=0; i<12; i++){
        f=2.*clamp(f,-cs,cs)-f;
        float c=max(fs/dot(f,f),1.);
        f*=c;
        v*=c;
        f+=fc;
    }
    float z=length(f.xy)-fu;
    return fd*max(z,abs(length(f.xy)*f.z)/sqrt(dot(f,f)))/abs(v);
}

float pseudo_kleinian(vec3 p)
{
    const vec3 CSize = vec3(0.92436,0.90756,0.92436);
    const float Size = 1.0;
    const vec3 C = vec3(0.0,0.0,0.0);
    float DEfactor=1.;
    const vec3 Offset = vec3(0.0,0.0,0.0);
       vec3 ap=p+1.;
    for(int i=0;i<10 ;i++){
        ap=p;
        p=2.*clamp(p, -CSize, CSize)-p;
        float r2 = dot(p,p);
        float k = max(Size/r2,1.);
        p *= k;
        DEfactor *= k;
        p += C;
    }
    float r = abs(0.5*abs(p.z-Offset.z)/DEfactor);
    return r;
}

float pseudo_knightyan(vec3 p)
{    
    const vec3 CSize = vec3(0.63248, 0.78632, 0.775);
    float DEfactor=1.;
    for(int i=0;i<6;i++){
        p = 2.*clamp(p, -CSize, CSize)-p;
        float k = max(0.70968/dot(p,p),1.);
        p *= k;
        DEfactor *= k*1.1;
    }
    float rxy=length(p.xy);
    return max(rxy-0.92784, abs(rxy*p.z) / length(p))/DEfactor;
}

float map(vec3 p)
{
    //return pseudo_kleinian(p);
    //return pseudo_knightyan(p);
    return hartverdrahtet(p);
}

vec3 guess_normal(vec3 p)
{
    const float d = 0.001;
    return normalize( vec3(
        map(p+vec3(  d,0.0,0.0))-map(p+vec3( -d,0.0,0.0)),
        map(p+vec3(0.0,  d,0.0))-map(p+vec3(0.0, -d,0.0)),
        map(p+vec3(0.0,0.0,  d))-map(p+vec3(0.0,0.0, -d)) ));
}

vec2 pattern(vec2 p)
{
    p = fract(p);
    float r = 0.123;
    float v = 0.0, g = 0.0;
    r = fract(r * 9184.928);
    float cp, d;
    
    d = p.x;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.y;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.x - 1.0;
    g += pow(clamp(3.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.y - 1.0;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 10000.0);
    
    const int iter = 12;
    for(int i = 0; i < iter; i ++)
    {
        cp = 0.5 + (r - 0.5) * 0.9;
        d = p.x - cp;
        g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 200.0);
        if(d > 0.0) {
            r = fract(r * 4829.013);
            p.x = (p.x - cp) / (1.0 - cp);
            v += 1.0;
        }
        else {
            r = fract(r * 1239.528);
            p.x = p.x / cp;
        }
        p = p.yx;
    }
    v /= float(iter);
    return vec2(g, v);
}

vec2 sphere_mapping(vec3 p)
{
    return vec2(
        asin(p.x)/PI + 0.5,
        asin(p.y)/PI + 0.5);
}

void main( void ) {
    
    vec2 pos = (gl_FragCoord.xy*2.0 - resolution.xy) / resolution.y;
    vec3 camPos = vec3(5.0*cos(time*0.1), 5.0*sin(time*0.1), 0.25*sin(time*0.25)+0.75);
    vec3 camDir = normalize(camPos*vec3(-1.0, -1.0, sin(time*0.33)*2.5));
    
    vec3 camUp  = normalize(vec3(0.0, 1.0, 1.0));
    vec3 camSide = cross(camDir, camUp);
    float focus = 1.8;
    
    vec3 rayDir = normalize(camSide*pos.x + camUp*pos.y + camDir*focus);
    vec3 ray = camPos;
    float m = 0.0;
    float d = 0.0, total_d = 0.0;
    const int MAX_MARCH = 100;
    const float MAX_DISTANCE = 100.0;
    for(int i=0; i<MAX_MARCH; ++i) {
        d = map(ray);
        total_d += d;
        ray += rayDir * d;
        m += 1.0;
        if(d<0.001) { break; }
        if(total_d>MAX_DISTANCE) { break; }
    }
    
    vec3 normal = guess_normal(ray);
    
    float r = mod(time*2.0, 20.0);
    float glow = max((mod(length(ray)-time*1.5, 10.0)-9.0)*2.5, 0.0);
    vec3 gp = abs(mod(ray, vec3(0.4)));
    vec2 p = pattern(sphere_mapping(normalize(ray)*mod(length(ray), 1.0))*2.0);
    if(p.x<1.4) {
        glow = 0.0;
    }
    else {
        glow += 0.0;
    }
    glow += max(1.0-abs(dot(-camDir, normal)) - 0.4, 0.0) * 0.5;
    
    float c = (total_d)*0.01;
    vec4 result = vec4( vec3(c, c, c) + vec3(0.02, 0.02, 0.025)*m*0.4, 1.0 );
    result.xyz += vec3(0.5, 0.5, 0.75)*glow;
    //result *= mod(gl_FragCoord.y, 4.0)<2.0 ? 0.6 : 1.0;
    //result.xyz = abs(normal);
    glFragColor = result;
}
