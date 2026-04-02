#version 420

// original https://www.shadertoy.com/view/WscSz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 to_ss(vec2 p)
{
    return p * vec2(resolution.x / resolution.y, 1.0);
}

float paraboloid(vec2 x, vec2 x0, vec2 scale)
{
    return pow((x.x - x0.x) / scale.x, 2.0)  + pow((x.y - x0.y) / scale.y, 2.0);
}

vec3 lerp(float t, vec3 c1, vec3 c2)
{
    return (1.0-t) * c1 + t * c2;
}

vec3 palm_leaves(vec3 col, vec2 p)
{
    float r = 0.2 + 0.12 * cos( atan(p.y, p.x) * 10.0 + 20.0 * p.x * (1.0+0.07*sin(time * 2.0)) + 1.0 );   
    vec3 c = lerp(r, vec3(0.1, 0.3, 0.0), vec3( 0.1, 0.1, 0.0 ));
    
    float t = smoothstep( r, r + 0.01, length(p) );
    return c + (col - c) * t;
}

vec3 palm_trunk(vec3 col, vec2 p)
{
    float k = sin( 120.0 * p.y );
    float r = 0.015 + 0.002 * k - p.y * 0.03;
    vec3 c = lerp(k, vec3(0.08, 0.06, 0.0), vec3(0.17, 0.08, 0.0));
    
    float t = 1.0 - ( 1.0 - smoothstep( r, r + 0.002, abs( p.x - 0.26 * sin( 2.0 * sin( p.y ))))) * smoothstep( 0.0, 0.05, 0.02-p.y);
    return c + (col - c) * t;
}

vec3 front_dune(vec3 col, vec2 p)
{
    float t = smoothstep(0.01, 0.0105, paraboloid(to_ss(p), vec2(0.0, 0.0), vec2(20., 1.8)));
    vec3 c = vec3(0.8, 0.6, 0.0);
    
    return c + (col - c) * t;
}

vec3 sun(vec3 col, vec2 p)
{
    float r = 0.2;
    vec2 pos = vec2(0.74, 0.3);
    
    float t = sin(3.0 * p.y - 0.8);
    vec3 c = lerp(t, vec3(0.97, 0.3, 0.0), vec3(1.0, 1.0, 0.0));
    
    pos = to_ss(pos - p);
    return c + (col - c) * smoothstep( 0.01, 0.011, (pow(pos.x, 2.0) * 0.9 + pow(pos.y, 2.0)) - pow(r, 2.0));
}

vec3 sea(vec3 col, vec2 p)
{
    float t = time;
    float k = min(1.0, 1.0 + 0.4 * sin(8000.0 * pow(p.y, 4.) + t) * sin(100.0 * p.y * p.x + t));
    
    vec3 c = lerp(k, vec3(0.1, 0.1, 0.8), vec3(0.4, 0.3, 0.8));
    
    return col = c + (col-c) * smoothstep(0.01, 0.015, p.y-0.25);
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;
    
    float t = paraboloid(p, vec2(0.74, 0.3), vec2(1.4, 1.0));
    vec3 col = lerp(t, vec3(0.95, 0.55, 0.2), vec3(0.1, 0.05, 0.2));
    
    col = sun(col, p);
    col = sea(col, p);
    
    vec2 palm_pos = p - vec2(0.34, 0.7);
    col = palm_leaves(col, palm_pos);
    col = palm_trunk (col, palm_pos);
    
    col = front_dune(col, p);
    
    glFragColor = vec4(col, 1.0);
}
