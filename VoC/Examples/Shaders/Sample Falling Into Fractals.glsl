#version 420

// original https://www.shadertoy.com/view/3tS3R3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    float w = resolution.x;
    float h = resolution.y;
    
    float aspectRatio = h / w;
    
    uv.y *= aspectRatio;
    uv.y -= (aspectRatio - 1.) * .5;
    
    vec2 cUV = uv - .5;
    
    float _WaveA = .15;
    float _WaveB = 2.1;
    
    vec4 _ColorA = vec4(.5, .4, .5,  1);
    vec4 _ColorB = vec4(.1, .1, .5,  1);

    float w0 = sin(_WaveA / abs(cUV.x) + time * _WaveB);
    float w1 = sin(_WaveA / abs(cUV.y) + time * _WaveB);
    float w2 = sin(_WaveB / abs(cUV.x) + time * _WaveA);
    float w3 = sin(_WaveB / abs(cUV.y) + time * _WaveA);
    
    vec4 c = _ColorA * w0 * w1 + _ColorB * w2 * w3;
    
    // Output to screen
    glFragColor = vec4(c.xyz * clamp(c.a, 0., 1.) ,1.);
}
