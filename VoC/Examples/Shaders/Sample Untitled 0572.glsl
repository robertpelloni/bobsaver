#version 420

// original https://www.shadertoy.com/view/wtffzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float SphereSDF(vec3 p)
{
    return length(p) - 1.0;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x += (cos(uv.x) * sin(uv.y)) * sin(time);
    uv.y += (cos(uv.y) * sin(uv.x)) * cos(time);

    // Time varying pixel color
    vec3 col =sin(time * 2.0) +  0.5*cos(time*uv.xyx+vec3(0,2,4));
    float ncol = SphereSDF(col);

    // Output to screen
    
    glFragColor = vec4(col.x * sin(ncol*time),col.yz *sin(ncol*time),ncol);
}
