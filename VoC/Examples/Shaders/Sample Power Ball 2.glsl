#version 420

// original https://www.shadertoy.com/view/wtX3zj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy) / min(resolution.x,resolution.y);

    vec2 uvo=uv;
    uv /= .7+0.35*sin(t);                           // zoom
    uv /= .7 + abs(.7-length(uv));                  // ball
    uv += 0.3*tan(t/5.)*cos(t/19.9*vec2(.77,2.22)); // pattern slide
    uv *= 0.54+.5*sin(t/3.2);                       // pattern zoom

    vec3 c = cos(uv.x*20.)*cos(uv.y*20.) + sin(t*vec3(1.,1.1,1.11));
    uv = uvo;

    uv /= .97+0.35*sin(-t*1.11);                           // zoom
      uv /= .7 + abs(.7-length(uv));                  // ball
    c+= cos(uv.x*20.)*cos(uv.y*20.) + sin(t*1.3*vec3(1.,1.1,1.11));

    c = c*c/8.;                                     // colour fold and spiff
    
    glFragColor=vec4( c, .0 );
}
