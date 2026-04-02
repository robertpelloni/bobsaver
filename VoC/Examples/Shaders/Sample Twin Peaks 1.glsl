#version 420

// original https://www.shadertoy.com/view/MtBczD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // RGBA
    vec4 color = vec4(.55, .4, 0.0, 1.0);
    
    // pixel position
    vec2 pixel = gl_FragCoord.xy / resolution.xy;
    
    // center origin point 
    pixel = (pixel - 0.5) * 2.0 ;
   
    pixel.x *= resolution.x / resolution.y;
    // time elapsed
    float time = time;
   
    float rido = 1.;
    rido *= sin(10./pixel.x+cos(time))*0.5+0.5 ;
    float rido2 =0.;
    color.r = rido + rido2;
    color.g = 0.0*rido+rido2;
    color.b = 0.2*rido+ rido2;
    
    //sol
    float hSol = 1.7;
    float maskSol = (smoothstep(3.*pixel.x+4.*pixel.y+hSol, 3.*pixel.x+4.*pixel.y+hSol+0.4, pixel.x*.3)) * (smoothstep(-3.*pixel.x+4.*pixel.y+hSol -0.4, -3.*pixel.x+4.*pixel.y+hSol,pixel.x*.3));
     float y = 3.*log(abs(pixel.y));
    float x = (pixel.x)*abs(y-1.5)*1.6;
   
    float h = 0.1;
    float t = h*5.;
    
    float m = 3.9;
    float a = (m*h/t)*(step(mod(x,t),t/2.) - step(t/2.,mod(x,t))); 

       float parquet = step(0.2, mod(y + a*x, m/10.)) ;
    
    color.r = .85*maskSol*(1.-parquet) + color.r*(1.-maskSol);
    color.g = 0.77*maskSol*(1.-parquet) + color.g*(1.-maskSol);
    color.b = .6*maskSol*(1.-parquet) + color.b*(1.-maskSol);

    // light circle
    float radius = 0.7;
    float smoothCircle = 1.0 - smoothstep(0., radius+1., length(pixel));
    color.rgb *= smoothCircle;
 
    glFragColor = color;
}
