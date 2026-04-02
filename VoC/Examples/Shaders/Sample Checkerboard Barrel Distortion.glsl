#version 420

// original https://www.shadertoy.com/view/MdcSz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Reference:
// Demo 1K Raw
// http://www.webglacademy.com/courses.php?courses=9|12|24|21|13#13

#define DISTORTION 5

float f( vec2 p, float d )
{
    float t = time;
    float g = 
    
#if DISTORTION == 1 // Step 6 simple barrel distorion
    mod(floor(    p.x*    length(p)     )+floor(    p.y*    length(p)     ),2.);
#elif DISTORTION == 2 // Step 7 x
    mod(floor(    p.x*pow(length(p),-3.))+floor(    p.y*    length(p)     ),2.);
#elif DISTORTION == 3 // Step 8 x and y
    mod(floor(    p.x*pow(length(p),-3.))+floor(    p.y*pow(length(p),-3.)),2.);
#elif DISTORTION == 4 // Step 9 x and y animated
    mod(floor(  t-p.x*pow(length(p),-3.))+floor(  t-p.y*pow(length(p),-3.)),2.);
#elif DISTORTION == 5 // Step 10 x and y animated + color
    mod(floor(d-t-p.x*pow(length(p),-3.))+floor(d-t-p.y*pow(length(p),-3.)),2.);
#else
    mod(floor(p.x)+floor(p.y),2.);
#endif
    return g;
}

void main(void)
{
    vec2 p  = gl_FragCoord.xy / (resolution.xy*0.5) - vec2(1.,1.);
        
#if DISTORTION == 5 //  // Step 10 x and y animated + color
    glFragColor = vec4( f(p,0.), f(p,.3), f(p,.6), 1.);
#else // monochrome
    float g = f( p, 0. );
    glFragColor = vec4( g, g, g, 1.0 );
#endif
}

