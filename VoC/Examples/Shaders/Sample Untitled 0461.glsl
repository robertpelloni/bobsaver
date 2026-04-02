#version 420

// original https://www.shadertoy.com/view/WsKGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 R;
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 f = glFragColor;

    R = resolution.xy;
    vec2 uv = vec2(u.xy - .5*R.xy)/R.y;
    vec3 col = vec3(1);
   
    uv.y*=exp(abs(cos(uv.x*2.)));
    uv.y+=time*.43;
    uv.x*=3.;
    
    vec2 fuv = fract(uv*6.);
    vec2 id1 = floor(uv*3.);
    
    float rev = 2.*mod(id1.y, 2.)-1.;
    col*=min(smoothstep(.4,.9, abs(uv.x*.5 + .55))+.6,1.2);
    uv.x += mod(time*rev + id1.y*.3,2.) 
        * mod(floor(time*rev + id1.y*.3), 2.);
    
    vec2 id = floor(uv*6.);
    
    float chk = mod(id.y+id.x,2.);
   
    col*=mix(vec3(1., 0., .5), vec3(.0,.6, .2), hash12(id));
    col *= smoothstep(.7, .12,abs(fuv.y-.5))*chk;
 
    f = vec4(col, 1.)*.8;
    
    glFragColor = f;
}
