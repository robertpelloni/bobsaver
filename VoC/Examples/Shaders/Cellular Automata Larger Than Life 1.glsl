#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float or = 10.0; //radius of the kernel

//comment out to clamp the edges
#define LOOP

//uncomment to see the cell kernel
//#define KERNEL

vec4 get(vec2 p)
{
    #ifdef LOOP
    return texture2D(backbuffer,mod(p/resolution,1.));    
    #else
    return texture2D(backbuffer,p/resolution);
    #endif
}

float weight(float l)
{
    return smoothstep(4.,2.8,l)+(smoothstep(9.,8.0,l)-smoothstep(6.,4.5,l));        
}

float kernel(vec2 p)
{
    float w = 0.0;
    float tw = 0.0;
    for(float y = -or;y <= or;y++)
    {
        for(float x = -or;x <= or;x++)
        {
            float tmpw = weight(length(vec2(x,y)));
            w += get(p+vec2(x,y)).w*tmpw;
            tw += tmpw;
        }
    }
    return w/tw;
}

float randb(vec2 co){
    return (fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) > 0.75) ? 1.0 : 0.0;
}

void main( void ) {

    vec2 p = ( gl_FragCoord.xy );

    float c = get(p).w;
    float k = kernel(p);
    
    if(k > 0.210 && k < 0.28)
    {
        c += k;
    }
    else
    {
        c -= k;
    }
    
    
    if(length(mouse*resolution-p) < 16. )
    {
        c = 1.-randb(p+time);
    }
    
    glFragColor = vec4( vec3( c,c*0.5 , sin(k*16.0)), c );
    
    #ifdef KERNEL
    glFragColor.rgb = vec3(weight(length(p-(resolution/2.0))));
    #endif
}
