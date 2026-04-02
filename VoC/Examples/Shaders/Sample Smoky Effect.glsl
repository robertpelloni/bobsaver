#version 420

// original https://www.shadertoy.com/view/Mldfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 light = vec3(0, 0, 0);

const mat3 m3 = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

vec3 rotateX(vec3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return vec3(p.x, ca*p.y - sa*p.z, sa*p.y + ca*p.z);
}

vec3 rotateY(vec3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return vec3(ca*p.x + sa*p.z, p.y, -sa*p.x + ca*p.z);
}

vec3 rotateZ(vec3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return vec3(ca*p.x + sa*p.y, -sa*p.x + ca*p.y, p.z);
}

//2D Noise function from user iq
float hash(vec2 p)
{
    p  = 45.0*fract( p*0.3183099 + vec2(0.71,0.113));
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

//3D Noise function from user iq
float hash(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

float rand(vec2 co){
    return 2.0*cos(fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453));
}

void main(void)
{
     //Pixel coordinate between -1 and 1
      vec2 pixel = (gl_FragCoord.xy / resolution.xy)*2.0-1.0;
    //Pixel coordinate between 0 and 1
    vec2 p = gl_FragCoord.xy / resolution.xy;
    //Pixel coordinate adapted to the resolution
    vec2 uv = p*vec2(resolution.x/resolution.y,1.0);
    
    //Setting up the light position
    vec2 mouse = (mouse*resolution.xy.xy/resolution.xy)*2.0-1.0;
    light = vec3(mouse, 0);
    
    //Computing the first fractal noise value
    float f = 0.0;
    uv *= 8.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
    f = 0.5 + 0.5*f;
    //Using the noise value to give the point a depth
    vec3 point1 = vec3(pixel, f);
    
    float a=time*0.065;
      point1 = rotateY(point1, a);
    //point1 *= 1.5+cos(time*0.05)/2.0;
    
    //Computing the second factal noise value using the point previously calculated
    vec3 q = 7.0*point1;
    float f2  = 0.5000*noise( q ); q = m3*q*2.01;
    f2 += 0.2500*noise( q ); q = m3*q*2.02;
    f2 += 0.1250*noise( q ); q = m3*q*2.03;
    f2 += 0.0625*noise( q ); q = m3*q*2.01;
   
    //Using the value to compute a new point
    vec3 point2 = vec3(pixel, f2);
    
    //Calculatinf the distance between the light and thoses points
    vec3 diff = light-point1;
    float dist = sqrt(dot(diff, diff));
    float c1 = 1.0/(dist*dist*dist*5.0);
    
    vec3 diff2 = light-point2;
    float dist2 = sqrt(dot(diff2, diff2));
    float c2 = 1.0/(0.0001+(dist2*dist2*dist2*5.0));

    //uv = p*vec2(resolution.x/resolution.y,1.0);;
    //glFragColor = (f2*c2)*texture(iChannel0, vec2(uv.x+0.05*f, uv.y+0.05*f));//*/ vec4(f, f, f, 1.0);
    
    //if(mouse*resolution.xy.w < 0.0)
        glFragColor = f*vec4(c2, c2, c2, 1);
    //else
        //glFragColor = f2*vec4(c1, c1, c1, 1);    
}
