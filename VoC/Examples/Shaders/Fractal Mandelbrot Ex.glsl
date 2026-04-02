#version 420

// original https://www.shadertoy.com/view/3dt3zj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define JULIA 1
#define POLYNOMIAL_DEGREE 4

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    float scale = 2.0;
    float zoom = exp(-scale*mouse.x);
    float aTime = time*0.5;
    uv = vec2( uv.x*sin(aTime)-uv.y*cos(aTime), 
             uv.x*cos(aTime)+uv.y*sin(aTime) );
    vec2 c = vec2(0.0);
    vec2 z = vec2(0.0);
#if JULIA==0
    c = uv*zoom*scale;
    z = vec2(0.1*cos(aTime), 0.1*sin(aTime)) + mouse;
#else
    c = vec2(sin(aTime), cos(aTime)) + mouse ;
    z = uv*zoom*scale;
 
#endif
    float iter = 0.0;
    vec3 col = vec3(0.0);
    const float MAX_STEP = 200.0;
    float pl = 0.0;
    float dist = 0.0;
    vec2 rst = vec2(0.0);
    for (float i = 0.0; i < MAX_STEP; i++)
    {
        
#if POLYNOMIAL_DEGREE==3
        //(a+bi)^3
        z = c + vec2(z.x*z.x*z.x-3.0*z.x*z.y*z.y, 
                 3.0*z.x*z.x*z.y-z.y*z.y*z.y);
#elif POLYNOMIAL_DEGREE==4        
        //(a+bi)^4
        z = c + vec2( z.x*z.x*z.x*z.x-6.0*z.x*z.x*z.y*z.y+z.y*z.y*z.y*z.y,
                      4.0*z.x*z.x*z.x*z.y-4.0*z.x*z.y*z.y*z.y );
#else
        //(a+bi)^2
        z = c + vec2(z.x*z.x-z.y*z.y, 2.0*z.x*z.y);
#endif
        dist = dot(z,z);
        if ( dist>4.0 ) break;
        
        pl = iter/MAX_STEP;
        col += vec3( pl, 0.0, pow(0.1,dist) );
        iter++; 
    }
    
    glFragColor = vec4(col,1.0);
}
