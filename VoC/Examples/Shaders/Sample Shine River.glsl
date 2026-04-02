#version 420

// original https://www.shadertoy.com/view/NdXXDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 col;
    float t = time*.5;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y+vec2(t,t*1.0);
    float factor = 2.5;
    vec2 v1;
    for(int i=1;i<12;i++)
    {
        uv *= -factor*factor;
        v1 = uv.yx/factor;
        uv += sin(v1+col+t*10.0)/factor;
        col += vec2(sin(uv.x-uv.y+v1.x-col.y),sin(uv.y-uv.x+v1.y-col.x));
    }
    glFragColor = vec4(vec3(col.x+4.0,col.x-col.y/12.0,col.x/15.0)/1.0,2.0);
}
