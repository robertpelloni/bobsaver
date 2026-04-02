#version 420

// original https://www.shadertoy.com/view/slsXWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//just experimenting ...
//gtz joeydee

//std 2d noise
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

//std 2d interpolated noise
float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);
    return res;
}

//std 3d noise
float rand(vec3 n) {
    return fract(sin(dot(n, vec3(12.9898, 4.1414,7.5531))) * 43758.5453);
}

//std 3d interpolated noise
float noise(vec3 p){
    vec3 ip = floor(p);
    vec3 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    float a0=rand(ip);
    float a1=rand(ip + vec3(1.0, 0.0, 0.0));
    float a2=rand(ip + vec3(0.0, 1.0, 0.0));
    float a3=rand(ip + vec3(1.0, 1.0, 0.0));
    float ares = mix(
        mix(a0, a1, u.x),
        mix(a2, a3, u.x), u.y);
    float b0=rand(ip + vec3(0.0, 0.0, 1.0));
    float b1=rand(ip + vec3(1.0, 0.0, 1.0));
    float b2=rand(ip + vec3(0.0, 1.0, 1.0));
    float b3=rand(ip + vec3(1.0, 1.0, 1.0));
    float bres = mix(
        mix(b0, b1, u.x),
        mix(b2, b3, u.x), u.y);
    return mix(ares,bres,u.z);
}

//somewhat perlin noise
float perlin(vec2 p){
    int numOctaves=8;
    float H=1.2;
    float t = 0.0;
    for (int i = 0; i < numOctaves; i++)
    {
        float f = pow(2.0, float(i));
        float a = pow(f, -H);
        t += a * noise(f * p);
    }
    return t; 
}

          
//organic dots
float dotNoise(vec2 p, float d){
    float res=noise(p*50.0+100.0)*d;
    res*=noise(p*70.0+10.0)*d;
    res*=noise(p*90.0+50.0)*d;
    res=1.0-res*res*res*res;
    return clamp(res,0.0,1.0);
}

float dotNoise(vec3 p, float d){
    float res=noise(p*50.0+100.0)*d;
    res*=noise(p*70.0+10.0)*d;
    res*=noise(p*90.0+50.0)*d;
    res=1.0-res*res*res*res;
    return clamp(res,0.0,1.0);
}

//turbulence lookup vector
vec2 turbulence(vec2 p, float s, float w){
    return vec2(p.x+perlin(p*s+12345.0)*w,p.y+perlin(p*s+67890.0)*w);
}

//a simple gradient lookup
float grad1(float f, float k){
     return 1.0-pow( 4.0*f*(1.0-f), k ); 
}

//a simple color lookup
vec3 colmap(float h, float t, float g){
     return vec3(h+t,h*(1.0+g),h-t); 
}

//experimenteller statischer Flockenbrei
float organicShice(vec2 p){
    float hue=0.7;
    hue*=dotNoise(p*0.3+300.0, 1.4)*0.3+0.7;                      //large dots
    hue*=dotNoise(turbulence(p,20.0,0.2)*0.3+300.0, 1.3)*0.5+0.5; //turbulence dots
    hue*=perlin(turbulence(p, 10.0, 0.5)*20.0)*0.3+0.7;           //turbulence perlin
    hue*=grad1(dotNoise(p*0.5, 1.3), 10.0)*0.6+0.4;               //hollow dots
    hue*=dotNoise(p, 1.2)*0.7+0.3;                                //small dots
    hue*=(perlin(p*15.0))*0.4+0.6;                                //perlin
    return hue;
}

//Frühstücksmüsli @ t_verdauung(0.5f)
float movingOrganicShice(vec2 p){
    float hue=0.7;
    vec3 p3=vec3(p,time*0.003);//depth offset
    vec2 o=vec2(sin(time*0.3)*0.4,time*0.2);//moving
    vec3 o3=vec3(o,0);
    hue*=dotNoise(((p3+o3*0.1)*2.0)*0.3+300.0, 1.4)*0.3+0.7;                        //large dots
    hue*=dotNoise(time*0.005+turbulence(p+o*0.134,20.0,0.2)*0.2+300.0, 1.3)*0.5+0.5; //turbulence dots
    hue*=perlin(time+turbulence(p+o*0.12, 10.0, 0.5)*20.0)*0.3+0.7;                //turbulence perlin
    hue*=grad1(dotNoise((p3+o3*0.13)*0.5, 1.3), 10.0)*0.6+0.4;                      //hollow dots
    hue*=dotNoise((p+o*0.11), 1.2)*0.7+0.3;                                         //small dots
    hue*=dotNoise((p+o*0.12)+1000.0, 1.3)*0.6+0.4;                                   //more dots
    hue*=(perlin((p+o*0.05)*15.0))*0.4+0.6;                                         //perlin
    return hue;
}

void main(void)
{
    // pixel coordinates
    vec2 p = gl_FragCoord.xy/resolution.xx;

    // Output to screen
    //glFragColor = vec4(colmap(organicShice(p),-0.2,0.4), 1.0);                                      //static example
    glFragColor = vec4(colmap(movingOrganicShice(p),-cos(time*0.1+0.9)*0.3,sin(time*0.007+0.5)*0.5), 1.0);  //dynamic example
}

