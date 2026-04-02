#version 420

// original https://www.shadertoy.com/view/ftdBRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 pos, vec2 o, float r)
{
    return step(length(pos - o), r);
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0,4,2),6.)-3.)-1., 0., 1.);

    return c.z * mix( vec3(1), rgb, c.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    uv *= 20.;
    uv.y += time;
    
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float pct = 0.;
    
    for (int x = -2; x < 3; x++)
    {
        for (int y = -2; y < 3; y++)
        {
            vec2 c = i + vec2(x,y);
            pct += circle(uv, c,sin(time*.3+(c.x-c.y)*.2)*.5+1.);
        }
    }

    //pct = circle(uv,vec2(0),1.);

    // Time varying pixel color
    vec3 col = vec3(hsv2rgb(vec3(pct*.1,1,sin((i.x + i.y+ time)*1. + sin(i.y - i.x)*1.)*.5+.6)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
