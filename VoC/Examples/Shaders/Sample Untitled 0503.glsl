#version 420

// original https://www.shadertoy.com/view/wt3SR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define cTime floor(time) + pow(fract(time),.5 + (sin(time*10.)*.5+.5)+.1)
mat2 r(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a));}
void main(void)
{
   vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv*=r(time*.1+smoothstep(5.9,.1,length(uv)));
    
    uv = abs(uv);
   
    uv*=10.;
    uv*=sin(length(cos(uv)*.5+cTime));
    uv*=r(length(uv*.1-time*.1)+time*.12);
    vec2 id= floor(uv);
     uv = fract(uv+cTime*.13)-.5;
    float d = 0.;
       
    if(mod(id.x,2.) - mod(id.y,2.) == 0.) {
        d = min(abs(uv.x+uv.y),.1);
    } else {   
        d = min(abs(uv.y-uv.x),.1);
    }
    d = smoothstep(0.2,.09-length(uv+sin(time)*.4),d);
    vec3 col;
    if( mod(id.x,2.) - mod(id.y,2.) == 0.) {
        col = mix(vec3(.1),vec3(.9,.3,.2*(1.-d)),vec3(d));
    } else {
        col = mix(vec3(.1),vec3(.2,.3*(1.-d),.9),vec3(d));
    }
       
    glFragColor = vec4(col,1.0);
}
