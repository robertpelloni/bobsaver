#version 420

// original https://www.shadertoy.com/view/7lVcWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 400
#define MAX_DIST 100.
#define SURF_DIST .001

// RayMarching code stolen from TheArtOfCode

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+1e-2)
//#define sabs(x, k) sqrt(x*x+k)

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float cc(float a, float b) {
    float f = thc(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float cs(float a, float b) {
    float f = ths(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

vec3 pal(in float t, in vec3 d) {
    return 0.5 + 0.5 * cos(2. * pi * (0.5 * t + d));
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(2. * pi * (c * t + d));
}

float h21(vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

float mlength(vec3 uv) {
    return max(max(abs(uv.x), abs(uv.y)), abs(uv.z));
}

float sfloor(float a, float b) {
    return floor(b) + 0.5 + 0.5 * tanh(a * (fract(b) - 0.5)) / tanh(0.5 * a);
}

// Stolen from iq, k = 0.12 is good
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

float smax(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) + k * h * (1. - h); 
}
    
    
// Stolen from BlackleMori
#define FK(k) floatBitsToInt(k*k/7.)^floatBitsToInt(k)
float hash(float a, float b) {
    int x = FK(a), y = FK(b);
    return float((x*x+y)*(y*y-x)-x)/2.14e9;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax, p)*ax, p, cos(ro)) + cross(ax,p)*sin(ro);
}

vec3 face(vec3 p) {
     vec3 a = abs(p);
     return step(a.yzx, a.xyz)*step(a.zxy, a.xyz)*sign(p);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

vec3 getRo() {
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    
    float a = -0.25 * time;
    float zm = (0.5 + 0.5 * thc(2., - 0.5 * time));
    float r = 3. + zm;
    vec3 ro = vec3(r * cos(a), 1. + zm, r * sin(a));
   // ro.yz *= rot(-m.y*3.14+1.);
    //ro.xz *= rot(-m.x*6.2831);
    return ro;
}

float GetDist( vec3 p0 ){
    p0.y += 0.15;
    float sd = abs(p0.y) - 0.01;
    sd -= 0.3;// * (0.5 + 0.5 * thc(4., length(p0.xz) - 0.5 * time));
    sd = max(sd, length(p0.xz) - 1.34);
   // p0.xz += 0.1 * thc(2., 5. * p0.y);
    p0 *= 0.5;
    vec4 p = vec4(p0, 1.);
      
    //p.xyz = erot(p.xyz, normalize(p.yzx), 0.5 * time);
    p.y += 0.05 * time;
    for(int i = 0; i < 8; i++){
      p.xyz = mod(p.xyz-1., 2.)-1.;
     // p.xyz *= 1. + 0.12 * cos(p.zxy * 8.);
     // p.xyz *= 1. +  0.15 * cos(length(p.xyz) * 10.);
     // p.y += .05 * cos(6. * length(p.xz) + time);// cos(time) * 0.5;
      
      // float r1 = 0.5;
      // float r2 = 0.1;
      // float d1 = length(p.xz) - r1;
      // float d2 = length(vec2(d1, p.y)) - r2;     
      // p.y = d2;//mlength(p.xyz);
     
      //This one looks really cool
      //p.y = 0.5 + 0.4 * cos(0.25 * time - pi * p.y);
      p*=(1.34/dot(p.xyz, p.xyz));
    }
    p/=p.w;
    return max(sd, abs(p.y)*0.5 - 0.00);
}

float RayMarch(vec3 ro, vec3 rd, float z) {
    
    float dO=0.;
    float s = sign(z);
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        if (s != sign(dS)) { z *= 0.5; s = sign(dS); }
        if(abs(dS)<SURF_DIST || dO>MAX_DIST) break;
        dO += dS*z; 
    }
    
    return min(dO, MAX_DIST);
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 ro = getRo();
    
    float zm = 5. - 1. * (0.5 + 0.5 * thc(1., -0.5 * time));
    vec3 rd = GetRayDir(uv, ro, vec3(0), zm);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

   
    float IOR = 1.2;
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        
        vec3 pIn = p - 20. * SURF_DIST * n;
        vec3 rdIn = refract(rd, n, 1./IOR);
        float dIn = RayMarch(pIn, rdIn, -1.);
        
        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = -GetNormal(pExit);
        
        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
       
        float fres = pow(1. + dot(rd, n), 5.);
        
        // Change me
        float c = 4.; // [0.6,6] is an okay range (<1 is like fresnel)
        float I = 3.; // anything above 0. lower numbers more intense
        
        vec3 n1 = 0.8 * (abs(r) - abs(n));
        float mx2 = exp(-5. * length(abs(r)-abs(n1)));

        vec3 r2 = c * (abs(r)-abs(n));
        vec3 n2 = c * (abs(r2)-abs(n));
        
        float mx = exp(-I * length(abs(r2)-abs(n2)));
 
        float cl = 0.5 + 0.25 * dif + max(0.5 * fres, max(mx,mx2));

        vec3 e = vec3(0.5);
        vec3 col2 = pal(1. + p.y - 0.1 * time + 4. * length(p) - p.y * 0.05  + 0.75 * mx, e, e, e, 0.5 * vec3(0,1,2)/3.);
        vec3 col3 = pal(1. + p.y - 0.1 * time + 4. * length(p) - p.y * 0.05  + 1.5 * mx2, e, e, e, 0.5 * vec3(0,1,2)/3.);
        
        float c1 = 0.0; //texture(iChannel0, 0.05 * time + 3. * p.xy).r;
        float c2 = 0.0; //texture(iChannel0, 0.05 * time + 3. * p.yz).r;
        float c3 = 0.0; //texture(iChannel0, 0.05 * time + 3. * p.zx).r;
        
        vec3 n3 = abs(n);
        float c4 = n3.z * c1 + n3.x * c2 + n3.y * c3;
        
        // add (dif + reflections) * base color
        col = cl * col2;

        // mix to second color based on ray distance inside object
        float mx3 = exp(-0.333 * dIn);
        //col = cl * col3;
        //col = mix(col, col3, mx3);
        // col= cl * col3;
        col *= 2. * col3;
        
        // add vertical shading ("light source" from above)
        col += 0.3 * n.y;
        col *= 0.8 + 0.5 * c4;
        
        // more color + reflections to match background 
        col += 0.075 * (exp(vec3(abs(rd.x),rd.y,abs(rd.z))) + exp(-r) + 0.1 * exp(r2) - 1.05);
    } else {    
        col = 0.65 * exp(vec3(abs(rd.x),rd.y,abs(rd.z)));
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
