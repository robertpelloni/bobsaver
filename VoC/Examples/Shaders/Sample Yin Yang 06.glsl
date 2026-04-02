#version 420

// original https://www.shadertoy.com/view/4dXcWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Do not redistribute.

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875

//-----------------UTILITY MACROS-----------------

#define time ((.125-.25*saw(float(__LINE__)*PI*GR*E)/PI/GR/E)*time+1000.0)
#define sphereN(uv) (clamp(1.0-length(uv*2.0-1.0), 0.0, 1.0))
#define clip(x) (smoothstep(0.25, .75, x))
#define TIMES_DETAILED (1.0)
#define angle(uv) (atan(uv.y, uv.x))
#define angle_percent(uv) ((angle(uv)/PI+1.0)/2.0)

#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)
#define circle(x) (vec2(cos((x)*2.0*PI),sin(2.0*PI*(x))))

#define rotatePoint(p,n,theta) (p*cos(theta)+cross(n,p)*sin(theta)+n*dot(p,n) *(1.0-cos(theta)))

float saw(float x)
{
    float f = mod(floor(abs(x)), 2.0);
    float m = mod(abs(x), 1.0);
    return f*(1.0-m)+(1.0-f)*m;
}
vec2 saw(vec2 x)
{
    return vec2(saw(x.x), saw(x.y));
}

vec3 saw(vec3 x)
{
    return vec3(saw(x.x), saw(x.y), saw(x.z));
}

vec4 saw(vec4 x)
{
    return vec4(saw(x.x), saw(x.y), saw(x.z), saw(x.w));
}

//-----------------ITERATED FUNCTION SYSTEM-----------------
    
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float gradient = uv.y;
    
        float scale = E;
    uv = uv*scale-scale/2.0;
    
    float aspect = resolution.x/resolution.y;
    
    uv.x *= aspect;
    
    float rotation = -time*PI*GR*E;
    
    vec2 uv0 = uv;
    
    int max_iterations = 4;//-int(saw(spounge)*float(max_iterations)/2.0);
    
    float antispeckle = 1.0; 
    float magnification = 1.0;
  
    vec4 color = vec4(0.0);
    float map = 0.0;
    float border = 1.0;
    vec4 final = vec4(0.0);
    float c1 = 0.0;
    
    for(int i = 0; i < max_iterations; i++)
    {
        float iteration = float(i)/float(max_iterations);
    
        float d = -cos(float(i)*PI);
        
        vec2 o = circle(time*d)*(1.0-iteration)/2.0;
        
        
        float c = smoothstep(0.0, 1.0/E/E, 1.0-length(uv));
        if(i == 0) c1 = c;
        
        
        
        vec2 uv2 = (uv+o)*(E+iteration);
        float c2 = smoothstep(1.0/E, 1.0/GR, 1.0-length(uv2)*2.0/PI)*c;
        vec2 uv3 = (uv-o)*(E+iteration);
        float c3 = smoothstep(1.0/E, 1.0/GR, 1.0-length(uv3)*2.0/PI)*c;
        
        uv = rotatePoint(vec3(uv, 0.0), vec3(0.0, 0.0, 1.0), d*rotation*2.0-PI/8.0).xy;
        uv = ((uv)*(1.0-c2)*(1.0-c3)+
            (uv2)*(c2)*(1.0-c3)+
            (uv3)*(1.0-c2)*(c3))*(antispeckle)+uv*(1.0-antispeckle)*c;
        
        
        border *= saw(1.0+c2*2.0)*saw(1.0+c3*2.0);

        float b = pow(border, iteration);
        float a = atan(uv.y, uv.x)/PI*.5+.5;
        float l = d*length(uv)*.5;
        map += smoothstep( 0.0, border*GR, GR*saw(c+c2+c3)*saw(border*saw(saw(2.0*(a+l))*saw(b*(d-c2)*(d-c3))*antispeckle)*(iteration+1.0)));
        
        antispeckle *= (clamp((c2+c3), 0.0, 1.0))*(1.0-saw(c2*2.0-c3)*saw(c3*2.0-c2));
        final += vec4(flux(map*PI+time*GR*E), 1.0);
    }
    glFragColor = vec4(uv, 0.0, 1.0);
     
    float w = smoothstep(.8, 1.0, saw(map));
 
    
    
    map = smoothstep(0.0, 1.0, map);
    glFragColor = ((w+final*(1.0-w)))*map*c1+(1.0-c1)*gradient;
}
