#version 420

// original https://www.shadertoy.com/view/4llcRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 paintHeart(vec3 col, vec3 col1, float x, float y)
{
    float r = x*x + pow((y - pow(x*x, 1.0/3.0)), 2.0);
    r -= pow(sin(time), 10.0);
    
    if (r < 1.5) {
        col = col1 * r;
    }
    return col;
}

vec3 paintSpecialHeart(vec3 col, vec3 col1, float x, float y)
{
    float r = x*x + pow((y - pow(x*x, 1.0/3.0)), 2.0);
    r -= sin(time) - 0.6;
    if ((r < 2.0 && r > 1.5) || (r < 1.0 && r > 0.6) || (r < 0.3 && r > 0.0)) {
        col = col1 * r * 1.5*(sin(time)+1.0);
        //col = col1 * r * 3.0;
    }
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = 4.0 * uv;
    
    float x = p.x - 2.0;
    float y = p.y - 1.65;
    
    vec3 col = vec3(0.0, 0.0, 0.0);
    vec3 col1 = mix(vec3(1.0,0.0,0.6), vec3(1.0,0.0,0.4), sqrt(p.y));
    vec3 col2 = mix(vec3(1.0,0.0,0.1), vec3(1.0,0.1,0.0), pow(p.y, 1.3));
    
    //col = paintHeart(col, col2, x, y);
    
    
    col = paintSpecialHeart(col, col1, x, y);
    
    glFragColor = vec4(col,1.0);
}
