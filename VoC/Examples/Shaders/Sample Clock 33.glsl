#version 420

// original https://www.shadertoy.com/view/flyyDt

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653
#define date (date * 1.0)
#define smooth 0.005

float mapRange(float x1, float x2, float y1, float y2, float v)
{
    return (v - x1) / (x2 - x1) * (y2 - y1) + y1;
}

vec4 blackbody(float x, float intensity) //By @FabriceNeyret2 (modified by me) https://www.shadertoy.com/view/4tdGWM
{
    vec4 O = vec4(0.0);
    float m = .01+5.*intensity,
        T = x*16000.; // absolute temperature (K)
    
    O -= O;
    
/*  // --- with physical units: (but math conditionning can be an issue)
    float h = 6.6e-34, k=1.4e-23, c=3e8; // Planck, Boltzmann, light speed  constants

    for (float i=0.; i<3.; i++) {  // +=.1 if you want to better sample the spectrum.
        float f = 4e14 * (1.+.5*i); 
        O[int(i)] += 1e7/m* 2.*(h*f*f*f)/(c*c) / (exp((h*f)/(k*T)) - 1.);  // Planck law
    }
*/
    // --- with normalized units:  f = 1 (red) to 2 (violet). 
    // const 19E3 also disappears if you normalized temperatures with 1 = 19000 K
     for (float i=0.; i<3.; i += .05) {  // +=.1 if you want to better sample the spectrum.
        float f = 1.+.5*i; 
        O[int(i)] += 10./m* (f*f*f) / (exp((19E3*f/T)) - 1.);  // Planck law
    }
    return O;
}

#define ease 1.5

float erp(float x, float k)
{
    return x < 0.5 ? pow(2.0*x, k)*0.5  : 1. - pow(2.0*(1.0-x), k) / 2.;
}

float hash2(in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

float noise(vec2 p)
{
  
    float tl = hash2(vec2(floor(p.x),  ceil(p.y)));
    float bl = hash2(vec2(floor(p.x), floor(p.y)));
    float tr = hash2(vec2( ceil(p.x),  ceil(p.y)));
    float br = hash2(vec2( ceil(p.x), floor(p.y)));
    
    
    float a = mix(bl, tl, erp(fract(p.y), ease));
    float b = mix(br, tr, erp(fract(p.y), ease));
    
    return mix(a, b, erp(fract(p.x), ease));
}

//Both of these functions are from here: https://stackoverflow.com/questions/68901847/opengl-esconvert-rgb-to-hsv-not-hsl
vec3 rgb2Hsl(vec3 c) { 
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0); 
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g)); 
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r)); 
    
    float d = q.x - min(q.w, q.y); 
    float e = 1.0e-10; 
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x); 
} 

vec3 hsl2Rgb(vec3 c) { 
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0); 
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www); 
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
} 

float join( float d1, float d2)
{
    float h = max(smooth-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/smooth;
    //float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    //return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdOrientedBox( in vec2 p, in vec2 a, in vec2 b, float th ) // Made by iq
{
    float l = length(b-a);
    vec2  d = (b-a)/l;
    vec2  q = (p-(a+b)*0.5);
          q = mat2(d.x,-d.y,d.y,d.x)*q;
          q = abs(q)-vec2(l,th)*0.5;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);    
}

float sdDisk(vec2 p, float r)
{
    return length(p) - r;
}

float sdDiskOutline(vec2 p, float r1, float r2)
{
    return abs(length(p) - r1) - r2*0.5;
}

float sdRotatedLine(vec2 p, vec2 start, float offset, float len, float theta, float thick)
{
    return sdOrientedBox(p, start + vec2(sin(theta), cos(theta)) * offset, vec2(sin(theta), cos(theta)) * (len + offset), thick);
}

vec4 sd(vec2 p)
{
    float seconds = sdRotatedLine(p, vec2(0.0, 0.0), 0.0, 0.15, (floor(date.w)/60.0)*2.0*PI, -0.001);
    float minutes = sdRotatedLine(p, vec2(0.0, 0.0), 0.0, 0.11, (date.w/60.0/60.0)*2.0*PI, 0.0);
    float hours = sdRotatedLine(p, vec2(0.0, 0.0), 0.0, 0.1, (date.w/60.0/60.0/12.0)*2.0*PI, 0.0);
    float centerDisk = sdDisk(p, 0.0);
    float outerCircle = sdDiskOutline(p, 0.23, 0.0);
    float ticks = 1000000.0;
    for(float i = 0.0; i < 2.0*PI; i+= 2.0*PI/12.0)
    {
        ticks = join(ticks, sdRotatedLine(p, vec2(0.0, 0.0), 0.18, 0.03, i, 0.0));
    }
    
    for(float i = 0.0; i < 2.0*PI; i+= 2.0*PI/60.0)
    {
        ticks = join(ticks, sdRotatedLine(p, vec2(0.0, 0.0), 0.2, 0.01, i, -0.005));
    }
    return vec4(join(join(join(join(join(seconds, minutes), hours), centerDisk), outerCircle), ticks), 0.0, 0.0, 0.0);
}

void main(void)
{
    float ratio = resolution.y/resolution.x;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(0.5);
    uv.y *= ratio;
    
    float px = 1.0/ratio/max(resolution.x, resolution.y);
    float intensity = mapRange(0.0, 1.0, 1.5, 2.0, erp(noise(vec2(uv.x, uv.x+date.w*0.05 + uv.y * 0.3)*10.0), 5.0));
    vec3 col = blackbody(.005/max(0.0, sd(uv).x + 0.01), intensity).xyz;
    col += max(vec3(0.0), blackbody(erp(abs(gl_FragCoord.xy.y/resolution.y - 0.5)*2.0, 0.1) * 0.5, intensity).xyz) * 1.0;
    col = rgb2Hsl(col);
    col.x = (uv.x * 0.5 + uv.y * 0.2) + fract(date.w*0.1);
    col = hsl2Rgb(col);
    glFragColor = vec4(col, 1.0);
    //glFragColor = vec4(uv.xy, 0.0, 1.0);
}
