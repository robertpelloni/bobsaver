#version 420

// original https://www.shadertoy.com/view/wsfcDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float TAU = 2.0 * 3.14159;
    float speed = 6.0;
    float range = 30.0;
    float waveFrequency = 2.0;
    float waveSmoothness = 0.025;
    float invScale = 60.0;
    float dropletCount = 5.0;
    float octaves = 1.0;
    //float rotationSpeed = 0.1;
    
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;
    uv *= invScale;
    
    //float ct = cos(time * rotationSpeed);
    //float st = sin(time * rotationSpeed);
    //uv = vec2(ct * uv.x + st * uv.y, st * uv.x - ct * uv.y);

    float brightness = 0.0;
    for (float i = 0.0; i < dropletCount; i++) {
        float angle = TAU * i / dropletCount;
        float dist = (0.5 + 0.5 * sin(time * speed / range)) * range;
        vec2 pos = vec2(sin(angle), cos(angle)) * dist;
        float distFromDrop = length(uv.xy - pos);
        float height = 0.0;
        for (float j = 0.0; j < octaves; j++) {
            height += (0.5 + 0.5 * cos(pow(2.0, j) * waveFrequency * distFromDrop)) * pow(0.5, j);
        }
        //float height = 0.5 + 0.5 * sin(waveFrequency * distFromDrop);
        brightness += height;
    }
    brightness /= dropletCount * (2.0 - pow(0.5, octaves - 1.0));
    brightness = smoothstep(0.5 - waveSmoothness, 0.5 + waveSmoothness, brightness);
    glFragColor = vec4(brightness);
}
