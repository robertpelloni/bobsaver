#version 420

// original https://www.shadertoy.com/view/Wl3XDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define amt 4.

vec2 rot(vec2 v, float a){
    float c = cos(a);
    float s = sin(a);
    return vec2(v.x*c-v.y*s, v.x*s+v.y*c);
}

vec3 thingy(vec2 uv)
{
        vec3 col;

    for(float j = 0.; j < amt; j++)
    {
        float angle = atan(uv.y, uv.x);
        float dist = length(uv);

        angle += sin(time*4.)*dist/4.;

        angle = angle*j;

        vec2 c = vec2(cos(angle), sin(angle))*dist;

        vec2 z = c;

        float itteration = 0.;

        while(length(z) < 2.*2. && itteration < 200.)
        {
            float nx = z.x*z.x-z.y*z.y;
            float ny = z.x*z.y*2.;
            z = vec2(nx, ny)+c;
            itteration += 1.;
        }
    
    
        col += vec3(itteration/200.)/amt;
    }
    return col;
}

void main(void)
{
    vec2 uv = ((gl_FragCoord.xy-0.5*resolution.xy)/resolution.y)*.5;
    uv*=4.;
    vec3 col;
    
    uv = rot(uv, time);
    uv *= 2.;
    uv.x -= cos(time);
    col = thingy(uv);
    
    glFragColor = vec4(col,1.0);
}
