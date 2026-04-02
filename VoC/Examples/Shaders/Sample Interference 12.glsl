#version 420

// original https://www.shadertoy.com/view/3lfSD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ring(vec2 pos, float size, float width, vec2 pixel) {
    float fa = 0.1;
    return smoothstep(size + width, size + width * fa, distance(pixel, pos)) - 
           smoothstep(size - width * fa, size - width, distance(pixel, pos));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    vec3 col = vec3(0.);
    
    for(float i = 0.5; i < 15.; i++) {        
        col += ring(vec2(cos(time * 0.5), sin(time * 0.5) * sin(time)), i * 0.15, 0.05, uv);
        col += ring(vec2(sin(time - 2.), cos(time * 0.5) * sin(time)), i * 0.15, 0.05, uv);
    }
    
    vec3 mixcolor1=vec3(0.);
    mixcolor1.r = 0.5 + cos(time * 0.7) * 0.4;
    mixcolor1.g = 0.5 + sin(time * 0.5) * 0.5;
    mixcolor1.b = 0.5 + cos(time * 0.2) * 0.6;

    vec3 fcol = mix(vec3(0.), col, mixcolor1);
    glFragColor = vec4(fcol * 4. ,1.0);
}
