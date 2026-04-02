#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ssl3Df

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

ivec2 square(int i, int n)
{
    if(n <= 0)
    {
        n++;  // weird
        return ivec2(0);
    }
    return clamp(abs((ivec2(0, 2*n) + i) % (8*n) - 3*n) - 2*n, -n, n);
}

void main(void)
{
    ivec2 coord = ivec2(gl_FragCoord.xy) / 10;
    ivec2 center = ivec2(resolution.xy/2.) / 10;

    vec3 col = vec3(0);
    
    int nMax = 20;
    int startI = int(3.*time);

    for(int n = 0; n <= nMax; n++)
        // for(int i = 0; i < max(8*n, 1); i++)
        for(int i = startI; i < max(8*n, 1) + startI; i += max(n, 1))
        {
            if(square(i, n) + center == coord) col = vec3(float(n + 1) / float(nMax), float(i + 1 - startI) / float(max(8*n, 1)), 1.);
        }
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
