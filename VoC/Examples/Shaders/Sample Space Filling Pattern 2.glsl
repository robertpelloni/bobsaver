#version 420

// original https://www.shadertoy.com/view/tdyBWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y; // Normalized pixel coordinates (from 0 to 1)
    vec3 col = vec3(0.);
    uv.x= 0.5*sin(1.*cos(uv.x+0.2)-3.14/2.);
 uv.y= 0.5*sin(cos(uv.y)-3.14/2.);//   uv.x* = 10.*sin(uv.x*2.);
   // uv.y = 20.*tan(uv.y*2.);
    uv *= (6.*time-2.0);
    //uv -= 6.;
    vec2 id = floor(uv); 
    float num = rand(id);
    
    vec2 gv = fract(uv)-0.5;
    if(num<0.5)
        gv.x*=-1.;
    float mask = smoothstep(0.2, 0.,abs(abs(gv.x+gv.y)-0.5));
    col += mask;
    
    // mask = 15.*sin(gv.x*gv.y);
    //col+=mask;
    //uv.x *=2.;
    glFragColor = vec4(col,0.);
}

