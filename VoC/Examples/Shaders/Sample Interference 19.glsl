#version 420

// original https://www.shadertoy.com/view/wssfR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float cx1 = uv.x-0.5+0.3*cos(time*1.6);
    float cy1 = uv.y-0.5+0.4*sin(time*1.6);
    cy1 *= 9./16.;
    
    float p1 = mod(sqrt(5e2*(cx1*cx1+cy1*cy1))-time*8.,1.);
    
    float cx2 = uv.x-0.5+0.3*cos(time*2.2-3.14);
    float cy2 = uv.y-0.5+0.4*sin(time*2.2-3.14);
    cy2 *= 9./16.;

    cx2 += sin(time/20.)*0.2*(sin(5.*uv.y-time*2.));    
    cy2 += sin(time/20.)*0.2*(sin(4.*uv.x-time*3.));

    float p2 = step(0., sin(sqrt(6e3*(cx2*cx2+cy2*cy2))));

    vec3 c1 = vec3(p1*1.2,p1,p1*1.3)*(1.-p2);
                   
    float c = ((1.-p1)*p2);
    
    vec3 col = vec3(c,c,c);
    col += c1;
    
    glFragColor = vec4(col,1.0);
}
