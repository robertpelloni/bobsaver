#version 420

// original https://www.shadertoy.com/view/wtdcW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A simple way to create color variation in a cheap way (yes, trigonometrics ARE cheap
// in the GPU, don't try to be smart and use a triangle wave instead).

// See http://iquilezles.org/www/articles/palettes/palettes.htm for more information

// ****************
// Helper functions
// ****************

// pallette 
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

#define HASHSCALE1 443.8975

// random functions lib
float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float lerp(float a, float b, float t)
{
    return a + t * (b - a);
}

float noise(float p)
{
    float i = floor(p);
    float f = fract(p);
    
    float t = f * f * (3.0 - 2.0 * f);
    
    return lerp(f * hash11(i), (f - 1.0) * hash11(i + 1.0), t);
}

float fbm(float x, float persistence, int octaves) 
{
    float total = 0.0;
    float maxValue = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for(int i=0; i<16;++i)
    {
        total += noise(x * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }
    
    return (total/maxValue);
}

void main(void)
{    
    float pi = 3.1415926;
    float res = max(resolution.x, resolution.y);
    
    // Center and normalize our coordinate system    
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / res;
    

    float r = length(uv - vec2(0.0,0.0));
    float theta = atan(uv.y, uv.x);
    float thetanorm = (theta + pi)/(2.0*pi);

    // Shift r domain for aesthetics
    r = r + 0.1;
    r *= 1.0;
    float i = floor(r*r*370.0 + 0.02) + 1.0;
    
    float at = sin(time*0.007 + 0.4) * 0.2 + 1.2;
    // Add distortion to rings  
    float rt = at*173.0 + 500.0;
    float tfbm = fbm(((theta+20.0) + 20.0), 0.54, 16)*2.0 + 0.8;
    float rfbm = fbm(r +rt, 0.54, 16)*4.0 + 0.8;
    //r *= clamp(tfbm,0.3,1.0);
    //r *= clamp(rfbm,0.8,1.0);
    r *= rfbm;
    r *= tfbm;
    
    i = floor(r*r*r*370.0) ;
    float i2 = pow(i,2.0) +1.0;
    
    float pct = fract(thetanorm*i2*2.0);
    
    // Flip 
    pct = abs(mod(i,2.) - pct);
    
    
    
    float row = floor(thetanorm*i2*2.0);    
    float k = (row+1.0)*(i+1.0)/200.0;
    // get random color for each cell
    vec3 color1 = vec3(hash11(k+1.0),hash11(k+2.0),hash11(k+3.0));
    vec3 color2 = vec3(hash11(k+5.0),hash11(k+6.0),hash11(k+7.0));
    
    float cfbm = fbm(i/4.0, 2.0, 2) + 0.5;;
    float t = sin(time*5.0 + cfbm*99.0)*0.5 + 0.5;
 
    vec3 color = mix(color1, color2, t);
    
   

    
    // Color option: Pallette blending
    // Todo change color to be picked random for each tile 
    //vec3 c1 = pal( pct, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    // vec3 c2 = pal( pct, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) );  
    // vec3 color = mix(c1,c2,t);
    // vec3 color = vec3(pct); vec3 color = vec3(hash);
    //vec3 color = 
    // Clip

    // Output to screen
    glFragColor = vec4(color*pct,.0);

}
