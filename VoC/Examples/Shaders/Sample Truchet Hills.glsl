#version 420

// original https://www.shadertoy.com/view/wslcz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// v1.0.1

#define PI 3.1415
#define ITERATIONS 25.

float ran21(vec2 uv) {
    return fract(cos(dot(cos(uv.x*uv.y)-32.2,tan(uv.x/uv.y)-23.5)*1322.24)*432122.62);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    vec2 uvb = uv;

    vec3 col = vec3(0);
    for(float i=1.;i<=ITERATIONS;i++) {
        float cur = i/ITERATIONS;
        uv = uvb;
        uv *= 10.0-cur*1.1;
        uv.y += time*0.6;
    
        vec2 gv = fract(uv)-.5;
        vec2 id = floor(uv);
    
        gv.x *= (ran21(id)>.5) ? -1. : 1.;
        vec2 ruv = gv-sign(gv.x+gv.y+.001)*.5;
        float tile = smoothstep(.01,-.01,abs(length(ruv)-.5)-.1);
        float rot = atan(ruv.x,ruv.y)/PI;
    
        float mul = mod(id.x+id.y,2.)==1. ? -1. : 1.;
        float h = smoothstep(cur-.1,cur,sin((rot*4.*mul+time)*PI)*.25+.75);
        
        col = max(col,h*tile*cur);
    }
    
    glFragColor = vec4(col,1.0);
}
