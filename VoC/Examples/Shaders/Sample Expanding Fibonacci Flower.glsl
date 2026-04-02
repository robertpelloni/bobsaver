#version 420

// original https://www.shadertoy.com/view/wllyzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// OG based of"fibonacci flower" by Derzo. https://shadertoy.com/view/ttjGzR

float fib(in vec2 uv)
{
    float m = 1e6;
    for (int x=0; x<200; x++)  
    {
    vec2 p;
    float a = float(x)*radians(132.165);
    a += (time)*.5;
    float r = float(x-int((sin(time)*.5+.5)*190.));
    if (r<0.) continue;
    r = .066*sqrt(r);
    m = min( m,  length(r*vec2(cos(a),sin(a)) - uv) - max( abs(uv).x, abs(uv).y)*0.06) ;  
    }
    return m;
}

void main(void)
{
    vec2 uv =(2.*gl_FragCoord.xy-resolution.xy) / resolution.y;
    glFragColor = vec4(0,1,abs(uv.y),1) * smoothstep(1.5/resolution.y,-1.5/resolution.y,fib(uv) );
}
