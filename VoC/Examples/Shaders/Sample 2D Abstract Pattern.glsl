#version 420

// original https://www.shadertoy.com/view/ltfGD4

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float t = time*1.4;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    for(int i = 0; i<4; i++)
    {
        uv+=-.5;
        vec2 c = vec2(-.2+uv.x,-.1+uv.y-sin(t));
        c*=cos(t-uv);
        uv=abs(uv);
        float m=uv.x*uv.x+uv.y*uv.y;
        uv-=((uv)/m+c);
    }
    
    glFragColor = vec4((uv*.5),uv.y,1.0);
}
/*2015 Passion*/
