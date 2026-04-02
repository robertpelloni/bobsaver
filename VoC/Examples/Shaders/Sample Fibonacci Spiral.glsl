#version 420

// original https://www.shadertoy.com/view/WtSGz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float fibonacci(in vec2 uv)
{
    float s = 0.0;
    
    for (int n = 0; n < 2000; n++)
    {
        float numb = float(n);
        
        float angle = numb * radians(137.51+time/50.);
        float r = 0.02 * sqrt(numb*1.);
        vec2 circlePos = r * vec2(cos(angle), sin(angle));
        
        s += (1.0 - r) * smoothstep(-1.5/resolution.y, 0.0, 0.01 - length(circlePos - uv));
    }

    return s;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy  - 0.5 * resolution.xy) / resolution.y;
    
    vec3 col = vec3( fibonacci(uv) );

    glFragColor = vec4(col, 1.0);

}
