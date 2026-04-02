#version 420

// original https://www.shadertoy.com/view/WsdSDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Thank you Dave_Hoskins for the hash! <3
vec2 hash22(vec2 p)
{
    uvec2 q = uvec2(ivec2(p))*uvec2(1597334673U, 3812015801U);
    q = (q.x ^ q.y) * uvec2(1597334673U, 3812015801U);
    return vec2(q) * (1.0 / float(0xffffffffU));
}

float worley(vec2 uv)
{
    uv *= 5.;
    uv += time*.25;
    
    vec2 id = floor(uv);
    vec2 gv = fract(uv);
    
    float minDist = 100.;
    for (float y = -1.; y <= 1.; ++y)
    {
        for(float x = -1.; x <= 1.; ++x)
        {
            vec2 offset = vec2(x, y);
            vec2 h = hash22(id + offset) * .8 + .1; // .1 - .9
            h = (((sin(h*time)+1.)*.5)*.8+.1) + offset;
            float p = length(gv - h);
            if (p < minDist)
            {
                minDist=p;
            }
        }
    }
    
    return minDist;
}

void main(void)
{
    float aspectRatio = resolution.x/resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= aspectRatio;
    
    vec3 col = vec3(0.);
    float w = worley(uv);
    col += 1.-w;
    col.r *= smoothstep(1.7, .0, length(uv-(sin(vec2(.7, .5)+time)+1.)*.5));
    uv.x = 1.2-uv.x;
    col.g *= smoothstep(1.7, .0, length(uv-(cos(.5+time)+1.)*.5));
    col.b *= 1.-sin(col.r+col.g);
    
    glFragColor = vec4(col, 1.0);
}
