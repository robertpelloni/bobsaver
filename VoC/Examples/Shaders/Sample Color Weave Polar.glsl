#version 420

// original https://www.shadertoy.com/view/wsGcWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Color Weave" by BackwardsCap. https://shadertoy.com/view/tlKGRc

float rand (vec2 p)
{
    return fract(sin(dot(p.xy,vec2(12389.1253,8941.1283)))*12893.128933);
}

void main(void) //WARNING - variables void ( out vec4 c, in vec2 f ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y/1.5;
    uv = vec2(atan(uv.x,uv.y),length(uv));
    uv.y-=.4+(.25*sin(time*.1));
    vec3 o = vec3(0);
    
    uv.x+=time;
    
    for(float i=-5.,id=0., T=time*.075;i<5.;i+=.15,id++)
    {
        uv.y *= 1.025;
        uv.x -= .35*T;
        float l = abs(uv.y + sin(uv.x+T)/1.-sin(cos(uv.x+T/50.))/2.);
        o += smoothstep((20.+i*1.)/resolution.y,0.,l);
        o *= 1.2 * vec3((0.5+(0.5*rand(vec2(1.,id)))),
                        (0.5+(0.5*rand(vec2(id+i/2.0,id)))),
                        (0.5+(0.5*rand(vec2(id-i,10.5)))));
    }
    
    
    glFragColor.rgb = (o+pow(o.b,2.0)*.2);
}
