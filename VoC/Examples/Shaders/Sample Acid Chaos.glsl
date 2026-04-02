#version 420

// original https://www.shadertoy.com/view/NstSzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float timeRatio = .3;
    float timeFlow = time * timeRatio;
    float acidRatio = 5.;
    
    vec3 position = vec3(timeFlow, timeFlow, timeFlow);
    vec3 color = vec3(acidRatio, acidRatio, acidRatio);
    
    for (int i = 0; i < 25; i++) 
    {
        position += vec3(-sin(uv), sin(uv) - cos(uv));
        
        color += vec3(
            -sin(color.g + sin(position.y)), 
            -sin(color.b + sin(position.z)), 
            -sin(color.r + sin(position.x)) 
        );
    }
    
    color *= color * .005;
    
    glFragColor = vec4(color, 1.);
}
