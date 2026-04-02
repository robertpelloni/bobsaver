#version 420

// original https://www.shadertoy.com/view/3tsGWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv_orig = (gl_FragCoord.xy - resolution.xy * 0.5) / (resolution.x);

    vec2 uv_dim = gl_FragCoord.xy / resolution.xy;

    float squsize = 0.2 + 0.15 * sin(time);
 
    float dist = (uv_orig.x*uv_orig.x + uv_orig.y*uv_orig.y)*(0.0 + sin(time*0.23)*5.0);
    float rot = 0.5 * time + dist;
    
    vec2 uv = vec2(uv_orig.x*sin(rot)+uv_orig.y*cos(rot), uv_orig.x*cos(rot)-uv_orig.y*sin(rot));
    
    // Time varying pixel color
    vec3 col = mod(uv.x, squsize) > (squsize*0.5) ^^ mod(uv.y, squsize) > (squsize*0.5) ? vec3(1.0,uv_dim.y,0.5) : vec3(0.0,1.0,uv_dim.x);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
