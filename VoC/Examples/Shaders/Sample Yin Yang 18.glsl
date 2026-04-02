#version 420

// original https://www.shadertoy.com/view/wltczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rot( in vec2 p, in float an )
{
    float cc = cos(an);
    float ss = sin(an);
    return mat2(cc,-ss,ss,cc)*p;
}

float bump(float x)
{
    return smoothstep(-1., 0., x) - smoothstep(0., 1., x);
}

float smoothbump(float r, float dr, float d)
{
    return smoothstep(r-dr/2., r, d) - smoothstep(r, r+dr, d);
}

float circle(in vec2 uv, in vec2 uv0, in float r, in float w) 
{
    return smoothbump(r, w, length(uv - uv0));
}

float unit(in float x) 
{
    return clamp(0.,1.,x);
}

float yinyang(in vec2 uv, in vec2 uv0, in float dr) 
{  
    // double circles enclosing
    float t = 0.;//circle(uv, vec2(0.,0.), 1.+dr*2., dr)
       // + circle(uv, vec2(0.,0.), 1.1, dr);
        
    // positions and distances of the circles
    vec2 uv1 = uv - vec2(.5,0.);
    vec2 uv2 = uv - vec2(-.5,0.);
    float d0 = length(uv);
    float d1 = length(uv1);
    float d2 = length(uv2);
   
    // use atan to determine if we are in the top or bottom half of the circle
    float a1 = atan(uv1.y, uv1.x);
    
    float d3 = 10.;
    if (a1 < 0.) {
        // trace the enclosing circle in the top half
        d3 = d0;
    } 
    // the tail
    float t7 = -smoothstep(1.-dr,1.+dr, d3); 
    
    // add and substract the two circles
    float t5 = 0.;
    float t6 = 0.;
    if (a1 >=0.)
    {
        t5 = 1. - smoothstep(.5-dr, .5+dr, d1) ;
    }
    else
    {
        t6 = smoothstep(.5-dr, .5+dr, d2) - 1.;
    }

    // left eye
    float t4 = smoothstep( .1 - dr, .1 + dr, d1);

    // right eye
    float t2 = 1. - smoothstep( .1 - dr, .1 + dr, d2);

    float h = t + t2 + t4 + t5 + t6 + t7;
    return h;
}

float petals(in vec2 uv, in vec2 uv0, in float dr)
{
    // double circles enclosing
    float r0 = 1.;
    float t = 0.;
    
    float c0 = 2.*smoothstep(r0,r0+dr, length(uv-uv0));
    float t1 = 0.;
    float t2 = 0.;
    float t3 = 0.;
    float t4 = 0.;
    vec2 uv1 = vec2(1.,0.);
    float alt = 1.;

    float d = length(uv-uv0);
    if (d > r0) // && d < r2) 
    {
        float r = sqrt(.5*.5*2.);
        float petals = 6.*6.;
        for (float a=0.;a<petals;a+=1.) 
        {
        
            float b = mod(a,4.);
            float c = circle(uv, uv1, r, dr);
            float d = length(uv - uv1);
            float step = 1. - smoothstep(r,r+dr,d);
            {
                t3 += b*step;
            }
            uv1 = rot(uv1, radians(360./petals));
            alt *= 1.;
        }
    }
    
    float h = t + t1 + t2 + t3 + t4;
    if (h > 10.)
    {
        return 1.;
    }
    else
    {
        return 0.;
    }
}

void main(void)
{
    // normalize aspect
    vec2 R = resolution.xy;
    vec2 uvR = ( R - 2.*gl_FragCoord.xy ) / R.y;
    
    // rotate the frame
    float z = 2.2;
    //vec2 uv = rot(uvR*z,radians(45.));
    vec2 uv = uvR*z;
    vec2 uv1 = rot(uv, radians(time*5.));
    
    vec3 colx = 0.5 + 0.5*cos(time+uvR.xyx+vec3(0,2,4));
    vec3 col0 = vec3(.0);
    vec3 col1 = vec3(.5,.0,.0);
    vec3 col2 = vec3(.0,.5, 0.);
    vec3 col3 = vec3(.3,.1,.5);
   
    float dr = 20./R.x;    

    vec2 uv0 = vec2(0.,0.);
    float h1 = petals(uv, uv0, dr);
    float h2 = petals(rot(uv,radians(360./6.)), uv0, dr);
    float h3 = yinyang(uv1*1.04, uv0, dr);
    
    float r2 = 1.5;
    float r1 = 0.9;
    float t1 = 0.*circle(uv, uv0, r1, dr) + circle(uv, uv0, r2, dr);

    vec3 col = colx*h2 + colx*h1 + colx*t1 + colx*h3;   
    glFragColor = vec4(col/2., 1.);
}
