#version 420

// original https://www.shadertoy.com/view/lscSWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Weed formula http://www.wolframalpha.com/input/?i=polar+(1%2Bsin(theta))*(1%2B0.9+*+cos(8*theta))*(1%2B0.1*cos(24*theta))*(0.9%2B0.05*cos(200*theta))+from+theta%3D0+to+2*Pi
float weed(vec2 uv)
{
    float d = 1.;
    float count = 7.;
    float rad = .8;
    uv.y += .35; 
    
    float theta = atan(uv.y, uv.x);     
       float r = .2* (1.+sin(theta))*(1.+.9 * cos(8.*theta))*(1.+.1*cos(24.*theta))*(.9+.05*cos(200.*theta));
    float l = length(uv);
    
    d = clamp((l - r ), 0., 1.);
    uv.y -= .2; 

    for(float i = 0.; i < 7. ; ++i)
    {
        uv += vec2(cos(time*.2 + i / count * 6.28)*rad,sin(time*.2+ i / count*6.28)*rad);
    
        theta = atan(uv.y, uv.x);
         
            r = .1* (1.+sin(theta))*(1.+.9 * cos(8.*theta))*(1.+.1*cos(24.*theta))*(.9+.05*cos(200.*theta));
        l = length(uv);
        d = min(d,clamp((l - r ), 0., 1.));
        uv -= vec2(cos(time*0.2 + i / count * 6.28)*rad,sin(time*0.2+ i / count*6.28)*rad);
    }
    
    return 1. - smoothstep(0., 50./resolution.x,d);
}

void main(void)
{
    vec3 fColor = vec3(0.);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 2. * uv - 1.;
    uv.x *= resolution.x / resolution.y;

    float or = weed(uv+vec2(sin(time)*.02,cos(time)*.01));
    float og = weed(uv+vec2(sin(time)*.01,cos(time)*.01));
    float ob = weed(uv-vec2(sin(time)*.01,cos(time)*.01));
    float shift = clamp(0.,1.,or + og + ob);
    
    fColor += or* vec3(1.,0.,0.);
    fColor += og* vec3(0.,1.,0.);
    fColor += ob* vec3(0.,0.,1.);
    
    fColor = mix(vec3(0.),fColor,shift);
    
    
    glFragColor = vec4(fColor,1.);
}
