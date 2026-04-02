#version 420

// original https://www.shadertoy.com/view/3lXGDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rect(vec2 uv, float left, float right, float up, float down, float blur)
{
    float l1 = smoothstep(uv.x, uv.x-blur, left);
    float r1 = smoothstep(uv.x, uv.x+blur, right);
    float u1 = smoothstep(uv.y, uv.y+blur, up);
    float d1 = smoothstep(uv.y, uv.y-blur, down);
    float result = l1*r1*u1*d1;
    return result;
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    float x = uv.x;
    float y = uv.y;
    float m = 0.2*sin(19.0*time + x*22.0);
  
    y = y-(m*(uv.x-0.3)/2.0);

    float col = rect(vec2(x,y), -0.3, 0.3, 0.1+uv.x, -0.2, 0.01);

    // Output to screen
    glFragColor = vec4(vec3(col),1.0);
}
