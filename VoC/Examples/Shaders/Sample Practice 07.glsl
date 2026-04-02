#version 420

// original https://www.shadertoy.com/view/3ds3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float box(vec2 st,float size)
{
    st = smoothstep(0.,15./resolution.y, size-.5 - abs(st-.5));
       return st.x*st.y;
}

float wave(vec2 st,float n)
{
    st=(floor(st*n)+0.5)/n;
    float d=length(0.-st);
    return (1.+sin(d-time*2.))*0.5;
}

float boxWave(vec2 uv,float n)
{
     vec2 st=fract(uv*n);
    float size=wave(uv,n);
    return box(st,size);
}

void main(void)
{
    vec2 p=(gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
      glFragColor=vec4(boxWave(p,2.),boxWave(p,4.),boxWave(p,8.),1.);
}
