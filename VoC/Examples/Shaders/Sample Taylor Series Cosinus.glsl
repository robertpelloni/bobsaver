#version 420

// original https://www.shadertoy.com/view/WdlBD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Thanks to mla for the smooth plotting function! 

// Taylor Series

// This version is defined for cos()
// Check the other version for any function as input: https://www.shadertoy.com/view/wdlBWj
// This one is better for learning how it works

// j = 0.
// f(j) = cos(j)
// T(x) = f(j) + x*f(j)'/1! + x^2*f(j)''/2! + x^3*f'''/3! +  x^4*f''''/4! ... etc

// This is a series, which approximates a given function around a point
// by matching its value and derivatives at that point.

// The derivatives are measured at the point, then scaled by x^n and divided by n! 
// This is done, so you negate the extra terms you get when deriving the equation.

// Thanks to 3blue1brown for his video from which I learned this! 
// https://www.youtube.com/watch?v=3d6DsjIBzJ4&t=691s

// You can change the amount of derivatives in the taylor(function)
// Uncomment around line 78 to plot the derivatives

float factorial(float x){float res = 1.;for(float i = 1.; i <= x;i++){res*=i;}return res;}

#define offs         (time)

#define fn(j)         cos(j+offs)

#define deriv(j)     -sin(j+offs)
#define deriv2(j)     -cos(j+offs)
#define deriv3(j)     sin(j+offs)

float taylor(float j){
    float res = 0.;
    
    res += fn(0.);
    res += deriv(0.)  *j         / factorial(1.);
    res += deriv2(0.) *j*j         / factorial(2.);
    res += deriv3(0.) *j*j*j     / factorial(3.);
    res += fn(0.)     *j*j*j*j     / factorial(4.); // cos(x) is the 4th derivatine of cos(x)
    
    return res;
}

// Plotting width
const float W = 0.03; 
// Plots a fn
const float eps = 0.01;
vec3 graph(float y, float fn0, float fn1, vec3 col, float width){
  return smoothstep(W*width*1.,dFdy(y)*W*width, 
                    abs(fn0-y)/length(vec2((fn1-fn0)/eps,0.5)))*col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y*5.;

    vec3 col = vec3(0);
    
    // functions 
    col += graph( uv.y, fn(uv.x),      fn(uv.x+eps),     vec3(0.,0.2,0.1), 1. );
    col += graph( uv.y, deriv(uv.x),  deriv(uv.x+eps),  vec3(0.0,0.02,0.0), 1. );
    col += graph( uv.y, deriv2(uv.x), deriv2(uv.x+eps), vec3(0.02,0.0,0.0), 1. );
    col += graph( uv.y, deriv3(uv.x), deriv3(uv.x+eps), vec3(0.0,0.0,0.04), 1. );
    col += graph( uv.y, taylor(uv.x), taylor(uv.x+eps), vec3(0.9,0.1,0.1), 1. );
    
    
        
    
    
    // plotlines
    
    float pi = acos(-1.);
    float uvxmod = abs( (fract((uv.x+offs+pi/3.)*2./3.14) -pi/5.)*pi/2.  );
    col += graph(uvxmod + eps,0.01,0.02,vec3(1,1,1)/2.,1.)*smoothstep(W,W*0.003,abs(uv.y)-0.1);
    col += graph(abs(uv.y),0.,dFdx(uv.x),vec3(1,1,1)/2.,0.5);
    
    
    // gamma correction
    col = pow(col,vec3(0.454545));
    
    glFragColor = vec4(col,1.0);
}
