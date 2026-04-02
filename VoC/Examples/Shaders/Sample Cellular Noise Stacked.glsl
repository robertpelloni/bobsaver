#version 420

// original https://www.shadertoy.com/view/wdsGRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCTAVES 4.
float rand(vec2 value)
{
    return fract(sin(dot(value, vec2(23.1245,87.2980))) * 5387.58135649);
}

vec2 rand2d(vec2 value)
{
    return fract(sin(vec2(dot(value, vec2(23.1245,87.2980)), dot(value, vec2(127.5123,39.183)))) * 5387.58135649);
}

//https://thebookofshaders.com/12/
float getCell(vec2 uv)
{
    vec2 iuv = floor(uv);
    vec2 fuv = fract(uv);
    vec3 col = (fuv).xyy;
    float mdist = 1.;
    
    // get neighbour tiles
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            vec2 n = vec2(float(x),float(y));
            
            vec2 p = rand2d(iuv + n);
            
            // animate
            p.y = 0.5 + 0.5*sin(time + 5.*p.y);
            p.x = 0.5 + 0.5*cos(time + 5.*p.x);
            
            vec2 diff = n + p - fuv;
            float dist = length(diff);
            mdist = min(mdist,dist);
        }
    }
    return mdist;
}

void main(void)
{
    
    
    vec2 vFontSize = vec2(8.0, 15.0);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    //scale
    vec2 p = uv * (resolution.xy / 100.0);
    p += 1.0;
    //tile
    
    // draw center
    //mdist += step(mdist,.02);
    
    vec3 col = vec3(0.);
    
    for(float i = 1. ; i < OCTAVES; i++)
    {
        col += vec3(getCell(p)) / i;
        p *= OCTAVES;
    }
    
    //gamma
    col = pow(col,vec3(2.2));
    // make pretty :)
    col.r *= uv.x;
    col.b *= 1.-uv.y;
    col.g *= .8 * 1.-uv.x;
    
    
    glFragColor = vec4(col,1.0);
}
