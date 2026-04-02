#version 420

// original https://www.shadertoy.com/view/XdXXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float t;

float rnd(vec2 uv) { return fract(sin(5423.1*uv.x-65.543*uv.y)*1e5); }
float rnd0(vec2 uv) { return (rnd(uv)>.5) ? 1. : 0. ; }

void main(void)
{
    t = time;

    vec2 uv = (gl_FragCoord.xy -.5*resolution.xy)/ ( floor(resolution.y/64.)*64.);

    vec2 mouse = mouse.xy / resolution.xy;
        mouse.x = .5*(1.+cos(.1*t));
        mouse.y = .5*(1.+cos(t));
    
    uv *= pow(2.,2.-6.*mouse.x);
    
    vec2 v = floor(uv*16.);    
    float fv = mod(v.x+v.y,2.);                             // large checker    
    vec2 sv = mod(floor(uv*16.*4.-.5),2.);                 // for small squares
    float fsv = sv.x+sv.y + 1.-sv.x*sv.y;                   // eliminates odd rows and cols
    vec2 m = floor(uv*16.*2.);                             // for mask
    float fm = m.x+m.y;                                     // half checker
    fm += ((uv.x-1./32.)*(uv.y-1./32.)<0.) ? 1. : 0.;   // translates by 1 row

    t = mod(floor(time),2.);
    fm += t;
    // fm += rnd0(m+t);
        
    if (length(mod(v+8.,16.)-8.)>6.25) fm = 0.;
  
    fsv = mod(fsv,2.)*mod(fm,2.)*mouse.y;
    
#if 0
    fv = mod(fv+fsv,2.); 
#else
    fv =  (fv > .5) ? 1.-fsv : fsv;
#endif

    glFragColor = vec4(fv);
}
