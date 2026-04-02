#version 420

// original https://www.shadertoy.com/view/Wty3Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 p, float r, float blur)
{
    float d = length(p-vec2(0));
    float m = smoothstep(-blur, blur, r-d);
    m *= smoothstep(blur, -blur, r-d - 0.03);
    return m;
}

float circle_layer(vec2 uv) 
{
    uv = fract(uv) - 0.5;        
    float m = circle(uv, 0.1, 0.005);
    return m;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    
    uv.x += sin(time * 0.6) * 0.4;
    uv.y += cos(time * 0.2) * 0.4;
    
    float layers = 42.;
    float m = 0.;
    for(float j = 0.; j < layers; j++)
    {
        float i = j / layers;
        
        float z = fract(i + time * 0.1);
        float size = mix(30. + sin(time) * 10. , 1., z);
        float a = mix(0., 2.*3.14159265, z);
        
        float fade = smoothstep(0., 0.99, z) * smoothstep(1.0, .9, z);

        vec2 suv = uv * size;
        suv.x += sin(z * 3. + time) * 0.4;
        suv.y += cos(z * 7. + time) * 0.2;
        
        m += circle_layer(suv) * fade * 0.7;
    }
    
    col += m * (sin(vec3(0.23, 0.43, 0.67)*time) * 0.4 + 0.6);
    glFragColor = vec4(col, 1.0);
}
