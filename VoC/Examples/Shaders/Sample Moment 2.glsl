#version 420

// original https://www.shadertoy.com/view/dd2GWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 checkerboard(vec2 coord, vec2 scale)
{

    coord *= scale;
    
    vec2 floored = round(coord);
    
    float d = distance(coord, floored);
    
    vec4 color = vec4(.5, 1, .4, 1);
    
    if (mod(floored.x, 2.0) == mod(floored.y, 2.0))
        color = vec4(.4, .6, .1, 1);
    
    
    if (d > 0.5)
        return vec4(1, 1, 1, 1) / (d * 10.0);
    else
        return (1.0 - color * d * d * 4.0);

}

vec2 convert(vec2 coord)
{

    float d = length(coord);
    float a = atan(coord.y, coord.x);
    //a += pow(d, 1.0 + time * sin(time / 100.0));

    float cosa = cos(a);
    float sina = sin(a);

    vec2 converted = vec2(cosa + (sina * cos(time)), sina + (cosa * sin(time))) / (d / time);
    converted = coord * d + converted * (1.0 - d);
    
    vec2 other = coord / (d * time);

    return converted * d + other * (1.0 - d);
    

}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv *= 2.0;
    uv -= 1.0;
    uv.x *= resolution.x / resolution.y;

    glFragColor = checkerboard(convert(uv), vec2(1, 1) / (1.0 + sin(time / 100.0)));
}
