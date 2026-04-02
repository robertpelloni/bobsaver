#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tllyD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI  3.14159265359
#define TWO_PI (2.0*PI)
#define HALF_PI (0.5*PI)

float thresh(float base, float val, float blur)
{
    return smoothstep(val+(blur/2.), val-(blur/2.), base);
}

vec4 circle(vec2 uv, vec2 coord, float r, float col)
{
    // returns the circlke in alpha
    float mask = thresh(length(coord - uv), r, .005);
    
    // black has no border, just return mask in alpha
    if (col < 0.5)
        return vec4(vec3(0), mask);
    else
    {
        float border = thresh(length(coord - uv), r-.001, .005);
        return vec4(vec3(border), mask);
    }
}

void main(void)
{
    vec2 R = resolution.xy, UV = (gl_FragCoord.xy - .5 * R) / R.y;
    vec3 col = vec3(0.);
   
    int amount = 40; // nr of circles
    float maxSize = 1.4; // size of largest circle
    float speed = 3.; // speed
    
    for(int i=0; i < amount; i++)
    {
        float norm = float(i) / float(amount); // 0 - 1 range
        float size = pow(1. - norm, 3.) * maxSize;
       
        float t = time - norm * speed;
        vec2 center = vec2(sin(t*1.7213),sin(t*2.12114)) * 0.25;
        vec4 circ = circle(UV, center, size, float(i % 2));

        // 'paint' using alpha channel
        col = mix(col, circ.xyz, circ.w);
    }
   
    glFragColor = vec4(col,1.0);
}
