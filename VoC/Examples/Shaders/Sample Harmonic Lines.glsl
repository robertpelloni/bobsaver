#version 420

// original https://www.shadertoy.com/view/wdV3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float lines(vec2 uv){
    uv = uv*50.;
    float freq = smoothstep(-1.,1.,-cos(time*0.5))*0.925+0.075;
    uv.x += sin((floor(uv.y*.5+.5)*2.-1.)*freq + time*2.5)*14.;
    float phase = floor(uv.y*.5+.5)*2.-1.;
    float size = smoothstep(-1.,1.,sin(time*3. +phase*.125))*10.;
    uv.y = fract(uv.y*.5+.5)*2.-1.;
    return smoothstep(0.4,0.6,length(uv - vec2(clamp(uv.x,-size, size), 0)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv = clamp(uv,-.5,.5);
    float d = 1.-min(lines(uv*-1.),lines(uv.yx));
    vec3 col = d*(sin(vec3(1.,.5,.2)*time*10.)*.5+.5);
    glFragColor = vec4(col,1.0);
}
