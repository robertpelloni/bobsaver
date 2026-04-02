#version 420

// original https://www.shadertoy.com/view/MsjcDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWOPI (2.0*3.1415926535) 
//--------------------------------------------------------------------------
vec4 hsv(float h,float s,float v)
{
    vec3 X = abs(fract(vec3(h,h,h)+vec3(1.0,2.0/3.0,1.0/3.0))*6.0-vec3(3.0,3.0,3.0));
    vec3 C = v*mix(vec3(1.0,1.0,1.0),clamp(X-vec3(1.0,1.0,1.0),0.0,1.0),s);
    return vec4(C.xyz,1.0);
} // hsv()
//--------------------------------------------------------------------------
vec4 compute(vec2 z0)
{
    float t = time/5.0*TWOPI;
        
    // Define the polynomial X^5 + exp(i*t/3)*X^3 + 0.05*exp(i*t/2)*X + exp(i.t)
    // The five roots will vary with time.
    vec2 polynomial[6];
    polynomial[0].x     = sin(t);
    polynomial[0].y     = cos(t);
    polynomial[1].x     = 0.05*cos(t/2.0);
    polynomial[1].y     = 0.05*sin(t/2.0);
    polynomial[2].x     = 0.0;
    polynomial[2].y     = 0.0;
    polynomial[3].x     = cos(t/3.0);
    polynomial[3].y     = sin(t/3.0);
    polynomial[4].x     = 0.0;
    polynomial[4].y     = 0.0;
    polynomial[5].x     = 1.0;
    polynomial[5].y     = 0.0;
    
    // do the Newton's iteration
    vec2 z = z0;
    int i;
    for(i=0;i<50;i++) // do only 50 iterations
    {
        // compute P(z) and its derivative P'(z)
        vec2 P             = vec2(0.0,0.0);
        vec2 dP         = vec2(0.0,0.0);
        vec2 z_power_d     = vec2(1.0,0.0); // z^d
        vec2 z_power_d1 = vec2(0.0,0.0); // z^(d-1)
        int d;
        float x,y;
        for(d=0;d<=5;d++)
        {
            x     = polynomial[d].x*z_power_d.x-polynomial[d].y*z_power_d.y;
            y     = polynomial[d].x*z_power_d.y+polynomial[d].y*z_power_d.x;
            P  += vec2(x,y);

            x     = polynomial[d].x*z_power_d1.x-polynomial[d].y*z_power_d1.y;
            y     = polynomial[d].x*z_power_d1.y+polynomial[d].y*z_power_d1.x;
            dP += float(d)*vec2(x,y);
            
            z_power_d1     = z_power_d;
            x             = z_power_d.x*z.x-z_power_d.y*z.y;
            y             = z_power_d.x*z.y+z_power_d.y*z.x;
            z_power_d     = vec2(x,y);
        } // for()
        
        // compute P/dP
        float r2     = dP.x*dP.x+dP.y*dP.y;
        x             = P.x*dP.x+P.y*dP.y;
        y             = P.y*dP.x-P.x*dP.y;
        // Newton's iteration new_z = z - P/dP
        if(r2 < 1.0e-12)
        {
            break;
        }

        z.x -= x/r2;
        z.y -= y/r2;

    } // for()
    
    if(50 == i) // if everything goes well
    {
        float h = atan(z.y,z.x)/TWOPI;
        float s = 1.0;
        float v = 1.0;
        return hsv(h,s,v);
    }
    else // divide by 0 should have been avoided
    {
        return vec4(0.0,0.0,0.0,1.0);
    }
    
} // compute()

//--------------------------------------------------------------------------
void main(void)
{
    // Get min/max of the resolution (in most case the width).
    float m     = min(resolution.x,resolution.y);
    float M     = max(resolution.x,resolution.y);
    vec2 uv     = ((gl_FragCoord.xy-0.5*resolution.xy) / m)*2.5;
    glFragColor     = compute(uv);
    
    // draw axis and unit circle in white on top of everything
    float width = 0.01;
    if(abs(sqrt(uv.x*uv.x+uv.y*uv.y)-1.0)<width)
        glFragColor = vec4(1.0,1.0,1.0,1.0);
    if(abs(uv.x)<width)
        glFragColor = vec4(1.0,1.0,1.0,1.0);
    if(abs(uv.y)<width)
        glFragColor = vec4(1.0,1.0,1.0,1.0);
}
