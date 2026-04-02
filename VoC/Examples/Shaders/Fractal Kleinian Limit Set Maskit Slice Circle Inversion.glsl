#version 420

// original https://www.shadertoy.com/view/llKXRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//by Jos Leys

vec3  background1Color=vec3(1.0,1.0,1.0);
vec3  color3=vec3(0.6,0.0,0.2);

float KleinR =0.;
float KleinI =0.;

float box_size_x=1.;

//circle inversion
bool SI=true;
vec2 InvCenter=vec2(0.,-1.);
float rad=1.;

float wrap(float x, float a, float s){
    x -= s; 
    return (x-a*floor(x/a)) + s;
}

void TransA(inout vec2 z, float a, float b){
    float iR = 1. / dot(z,z);
    z *= -iR;
    z.x = -b - z.x; z.y = a + z.y; 
    
}

float  JosKleinian(vec2 z)
{
    vec2 lz=z+vec2(1.), llz=z+vec2(-1.);
    float flag=0.;
        KleinR = 1.958591;
        KleinI = 0.011278;
       float d=0.; float d2=0.;
         z=z-InvCenter;
        d=length(z);
        d2=d*d;
        z=(rad*rad/d2)*z+InvCenter; 

    float a = KleinR;
    float b = KleinI;
    float f = sign(b)*1. ;     
    for (int i = 0; i < 100 ; i++) 
    {
                z.x=z.x+f*b/a*z.y;
        z.x = wrap(z.x, 2. * box_size_x, - box_size_x);
        z.x=z.x-f*b/a*z.y;
                       
        //If above the separation line, rotate by 180° about (-b/2, a/2)
        if  (z.y >= a * 0.5 + f *(2.*a-1.95)/4. * sign(z.x + b * 0.5)* (1. - exp(-(7.2-(1.95-a)*15.)* abs(z.x + b * 0.5))))    
        {z = vec2(-b, a) - z;}
        
        //Apply transformation a
        TransA(z, a, b);
        
        //
        //If the iterated points enters a 2-cycle , bail out.
        if(dot(z-llz,z-llz) < 1e-5) {break;}
        //if the iterated point gets outside z.y=0 and z.y=a
        if(z.y<0. || z.y>a){flag=1.; break;}
        //Store previous iterates
        llz=lz; lz=z;
    }

    return flag;
}

void main(void)
{
    
       vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float zoom=1.-0.9*abs(sin(time*0.1)); 
    uv = zoom*uv-vec2(zoom*0.5,0.5*(1.+zoom));
    uv.x *= resolution.x/resolution.y;
    float hit=JosKleinian(uv);
      vec3 c =(1.-hit)*background1Color+hit*color3;
   
    glFragColor = vec4(c, 1.0);
    
}

