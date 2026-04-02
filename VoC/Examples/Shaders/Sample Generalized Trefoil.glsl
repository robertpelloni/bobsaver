#version 420

// original https://www.shadertoy.com/view/lsBcW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//--------------------------------------------------------------------------
#define TWOPI             (2.0*3.1415926535)
#define ROTATION(alpha) mat2(cos(alpha),-sin(alpha),sin(alpha),cos(alpha))
#define COLORIZATION(h)    clamp(abs(fract(h+vec4(3.0,2.0,1.0,0.0)/3.0)*6.0-3.0)-1.0,0.0,1.0)

//--------------------------------------------------------------------------
vec3 trefoil_point(float p,float q,float phi)
{
    float cp = cos(p*phi);
    float sp = sin(p*phi);
    float cq = cos(q*phi);
    float sq = sin(q*phi);
    return vec3((2.0+cq)*cp,(2.0+cq)*sp,-sq);
} // trefoil_point()

//--------------------------------------------------------------------------
// treefoil (p,q)
// ray is defined by point P and direction d
vec4 compute(in float p,in float q,in vec3 P, in vec3 d)
{
    d = d/dot(d,d);
    int     i;
    int     nb         = 1000;
    float     t_min     = 1000.0;
    float   phi_min;
    float     r2         = 0.2; // radius of the torus
    for(i=0;i<nb;i++)
    {
        float phi     = TWOPI*float(i)/float(nb);
        vec3  A     = trefoil_point(p,q,phi);
        float t     = -dot(P-A,d);
        vec3  M     = P+t*d;
        vec3  diff     = M-A;
        if(t > 0.0 && t < t_min && dot(diff,diff) < r2)
        {
            t_min     = t;
            phi_min = phi;
        }
    } // for()
    
    if(t_min < 1000.0)
    {
         return COLORIZATION(phi_min/TWOPI);
    }
    else
    {
        return vec4(0.0,0.0,0.0,1.0);
    }
} // compute()

//--------------------------------------------------------------------------
void main(void)
{
    float m         = min(resolution.x,resolution.y);
    vec2 uv         = (gl_FragCoord.xy / m - vec2(0.9,0.5))*10.0;
    vec3 P             = vec3(uv,-5.0);
    vec3 d          = vec3(0.0,0.0,1.0);
    float alpha1    = time*TWOPI/13.0;
    float alpha2    = time*TWOPI/5.0;
    P.zx           *= ROTATION(alpha1);
    P.xy           *= ROTATION(alpha2);
    d.zx            *= ROTATION(alpha1);
    d.xy           *= ROTATION(alpha2);
    
    float i = mod(time/3.0 /* change every 3 seconds */,16.0);
    float p,q;
    if(i <= 1.0)         {p=2.0;q=3.0;}
    else if(i <= 2.0)    {p=2.0;q=5.0;}
    else if(i <= 3.0)    {p=2.0;q=7.0;}
    else if(i <= 4.0)    {p=3.0;q=2.0;}
    else if(i <= 5.0)    {p=3.0;q=4.0;}
    else if(i <= 6.0)    {p=3.0;q=5.0;}
    else if(i <= 7.0)    {p=3.0;q=7.0;}
    else if(i <= 8.0)    {p=4.0;q=3.0;}
    else if(i <= 9.0)    {p=4.0;q=5.0;}
    else if(i <= 10.0)    {p=4.0;q=7.0;}
    else if(i <= 11.0)    {p=5.0;q=2.0;}
    else if(i <= 12.0)    {p=5.0;q=3.0;}
    else if(i <= 13.0)    {p=5.0;q=4.0;}
    else if(i <= 14.0)    {p=5.0;q=6.0;}
    else if(i <= 15.0)    {p=5.0;q=7.0;}
    else                {p=6.0;q=5.0;}
        
    glFragColor = compute(p,q,P,d);
}
