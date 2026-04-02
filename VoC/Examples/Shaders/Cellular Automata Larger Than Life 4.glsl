#version 420

// Mouse to bottom edge of screen to reset

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float ir = 3.0;
float or = 10.0;

float pi = 3.14159;

vec4 get(vec2 p)
{
    return texture2D(backbuffer,mod(p/resolution,1.));    
}

float weight(vec2 p,float l)
{
    return (get(p).w*smoothstep(ir,ir+1.,l)*smoothstep(or,or-1.,l));        
}

float kernel(vec2 p)
{
    float w = 0.0;
    for(float y = -10.;y < 10.;y++)
    {
        for(float x = -10.;x < 10.;x++)
        {
            w += weight(p+vec2(x,y),length(vec2(x,y)));
        }
    }
    return w/((pi*or*or)-(pi*ir*ir));
}

float rand(vec2 co){
    return (fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) > 0.75) ? 1.0 : 0.0;
}

void main( void ) {

    vec2 p = ( gl_FragCoord.xy );

    float c = get(p).w;

    float k = kernel(p);
    
    if(k > 0.362 && k < 0.549+0.06*cos(time+mouse.x))
    {
        c = c;
    }
    else
    {
        c -= .50;
    }
    
    if(k > 0.259 && k < 0.336+0.0002*sin(time*.7+mouse.y))
    {
        c += 1.;
    }
    
    if(mouse.y < 0.01 || fract(time*0.1) < 0.2)
    {
        
        if(length(p-(resolution)*.5) < 64.+12.*cos(p.y*mouse.x*0.01+length(p)*mouse.x*0.09))
        {
            c = 1.-rand(p+time);
        }
    }
    
    glFragColor = vec4( vec3( 1.-c*0.4545 , 1.-c*(1.-0.1*cos(time*1.2)), 1.-c*(1.-0.1*cos(time*0.9797))), c );
}
