#version 420

// original https://www.shadertoy.com/view/XsdfWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fourier series:
// http://mathworld.wolfram.com/FourierSeriesSquareWave.html
// https://en.wikipedia.org/wiki/Fourier_series#Convergence
// ========================================
// distance formula used to plot squarewave smoothly
// d = |fx-y|/sqrt(1+(dfx/dx)^2)
// http://www.iquilezles.org/www/articles/distance/distance.htm
// ========================================

const float pi = 3.14159265359;
const float scale = 2.0;
const float thickness = 3.0*scale;

vec2 uvmap(vec2 uv)
{
    return (2.0*uv - resolution.xy)/resolution.y;
}

// color picker:
// https://www.shadertoy.com/view/ll2cDc
vec3 pickColor(float n) {
    return 0.6+0.6*cos(6.3*n+vec3(0,23,21));
}

float circle(vec2 uv, vec2 C, float r, bool fill)
{
    vec2 p = uv-C;
    float fx = length(p)-r;
    float dist = fill? fx:abs(fx);
    return smoothstep(thickness/resolution.y,0.0,dist);
}

float line(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a; 
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float dist = length(pa - ba * h);
    return smoothstep(thickness/resolution.y,0.0,dist);
}

float squarewave(float n, float x, float l, float phase){
    return 4.0/(n*pi)*sin(n*pi*x/l+phase);
}

// derivative of series terms.
float dsquarewave(float n, float x, float l, float phase){
    return 4.0/l*cos(n*pi*x/l+phase);
}

void main(void)
{
    vec2 uv = uvmap(gl_FragCoord.xy)*scale;
    float time = time/3.0;
    vec3 col = vec3(0);
    int terms = 10; // number of terms to produce
    
    float l = 1.0; // squarewave length divided by two.
    vec2 c = vec2(0); // center of the circles
    float sum = 0.0; // fourier series sum
    float dsum = 0.0; // derivative of the sum
    float tsum = 0.0; // sum for red line
    
    for(int i=0; i<terms; i++) {
        float n = float(i)*2.0+1.0;
        vec3 color = pickColor(n/float(terms*2));
        
        // calculate fourier series terms for circles
        float term = squarewave(n, time, l, 0.0);
        float cterm = squarewave(n, time, l, pi/2.0);
        vec2 r = vec2(cterm,term);
        
        // plot circles
        col += circle(uv,c,length(r),false)*color;
        col += line(uv,c, c += r)*color;
        
        // calculate fourier series terms for wave plot
        sum += squarewave(n, uv.x-time, l, 0.0);
        dsum += dsquarewave(n, uv.x-time, l, 0.0);
        tsum += term;
    }
    
    // squarewave plot
    float dist = abs(uv.y-sum)/sqrt(1.0+dsum*dsum);
    col+=smoothstep(thickness/resolution.y,0.0,dist);
    
    // red line
    col+=(line(uv,c,vec2(+l,c.y))
        + line(uv,c,vec2(-l,c.y))
        + circle(uv,vec2(+l,tsum),0.01,true)
        + circle(uv,vec2(-l,tsum),0.01,true))*vec3(1,0,0);
    
    // fill main circle
    float term = squarewave(1., time, l, 0.0);
    float cterm = squarewave(1., time, l, pi/2.0);
    col+= circle(uv,vec2(0), sqrt(term*term+cterm*cterm), true)*.2*c.y*
           vec3(sin(time), sin(time+2.*pi/3.), sin(time-2.*pi/3.));
    
    // output to screen
    glFragColor = vec4(col,1.0);
}
