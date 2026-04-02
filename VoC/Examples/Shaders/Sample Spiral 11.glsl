#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Spiral Fire    

// original https://www.shadertoy.com/view/MdlXRS by nimitz
// Somewhat inspired by the concepts behind "flow noise"
// every octave of noise is modulated separately
// with displacement using a rotated vector field

// normalization is used to created "swirls
// usually not a good idea, depending on the type of noise
// you are going for.

// Sinus ridged fbm is used for better effect.

#define time1 time*0.1
#define time2 time*0.3
#define tau 6.2831853

mat2 makem2(in float theta)
{ float c = cos(theta);
  float s = sin(theta);
  return mat2(c,-s,s,c);
}

// Noise 2D by IQ:  https://www.shadertoy.com/view/lsf3WH
float hash(vec2 p)
{
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

mat2 m2 = mat2( 0.80,  0.60, -0.60,  0.80 );

float grid(vec2 p)
{
    float s = sin(p.x)*cos(p.y);
    return s;
}

float flow(in vec2 p)
{
    float z=2.;
    float rz = 0.;
    vec2 bp = p;
    for (float i= 1.;i < 7.;i++ )
    {
        bp += time1*11.5;
        vec2 gr = vec2(grid(p*3.-time1*2.),grid(p*3.+4.-time1*2.))*0.4;
        gr = normalize(gr)*0.4;
        gr *= makem2((p.x+p.y)*.3+time1*10.);
        p += gr*0.5;
        
        rz += (sin(noise(p)*8.)*0.5+0.5) /z;
        
        p = mix(bp,p,.5);
        z *= 1.7;
        p *= 2.5;
        p*=m2;
        bp *= 2.5;
        bp*=m2;
    }
    return rz;    
}

float spiral(vec2 p,float scl) 
{
    float r = length(p);
    r = tau * mouse.x* log(r);
    float a = atan(p.y, p.x);
    return abs(mod(scl*(r-2./scl*a),tau)-1.)*2.;
}

void main( void ) 
{
    vec2 p = gl_FragCoord.xy / resolution.xy-0.5;
    p.x *= resolution.x / resolution.y;
    p*= 1. + 8. * mouse.y;
    float rz = flow(p);
    p /= exp(mod(time2,2.1));
    rz *= (6.-spiral(p,3.))*.9;
    vec3 col = vec3(.2,0.07,0.01)/rz;
    col=pow(abs(col),vec3(1.01));
    glFragColor = vec4(col,1.0);
}
