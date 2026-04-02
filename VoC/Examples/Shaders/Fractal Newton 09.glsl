#version 420

// Smooth Newton Fractal 1-z^3 by @hintz
// v2 HSV2RGB changed
// v3 added smooth iteration value, which is needed for future 3D conversion. 2017-10-02 @hintz
//
// What about to go 3D like http://www.josleys.com/show_gallery.php?galid=338 ?

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float deltax = 12.0 + sin(time*0.4) * 10.0;
float deltay = resolution.y / resolution.x * deltax;

float theta = time*0.1;
float cosThetaPi = cos(theta);
float sinThetaPi = sin(theta);

// for pretty colors: Hue-Saturation-Value to Red-Green-Blue
vec4 hsvToRgb(vec3 hsv) 
{
    vec3 rgb = ((clamp(abs(fract(hsv.x +vec3(0.,2./3.,1./3.))*2.-1.)*3.-1.,0.,1.)-1.)*hsv.y+1.)*hsv.z;
  
    return vec4 (rgb,1.0);
}

// complex number multiplication: a * b
vec2 mul(vec2 a, vec2 b)
{
    return vec2(a.x*b.x - a.y*b.y, a.y*b.x + a.x*b.y);
}

// complex number division: a / b 
vec2 div(vec2 a, vec2 b)
{
    return vec2((a.x*b.x + a.y*b.y) / (b.x*b.x + b.y*b.y), (a.y*b.x - a.x*b.y) / (b.x*b.x + b.y*b.y));
}

//     1 - z^3
// z - -------
//     3 * z^2
vec2 znext(vec2 z)       
{                        
    vec2 z2 = mul(z,z);    
    
    return z - div(vec2(1.0,0.0)+mul(z2,z),3.0*z2);
}

vec2 newtonfractal(vec2 z)
{
    for (int n=0; n<1000; n++)
    {
        vec2 old = z;
        z = znext(z);
            float d = length(z - old);
        
            if (d < 0.01)
            {
            float u = float(n) + log2(log(0.01)/log(d));
      
            return vec2(z.x + z.y + time*0.1, u*0.03);
        }
    }
    
    return z;
}

void main(void)
{
  float real = deltax * (gl_FragCoord.x / resolution.x - 0.5);
  float imag = deltay * (gl_FragCoord.y / resolution.y - 0.5);
 
  float realR = real*cosThetaPi - imag*sinThetaPi;
  float imagR = real*sinThetaPi + imag*cosThetaPi;
    
  vec2 results = newtonfractal(vec2(realR, imagR));

  vec3 hsv = vec3(results.x + results.y, 0.8, 1.0 - results.y);
    
  glFragColor = hsvToRgb(hsv);
}
