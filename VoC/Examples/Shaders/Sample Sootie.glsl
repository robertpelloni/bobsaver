#version 420

// original https://www.shadertoy.com/view/Md3Bzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    //uvs
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float ar = resolution.y / resolution.x;
    uv = uv * 2.0 - 1.0;
    uv += vec2(sin(time), cos(time)) * sin(time) * 0.25;
    uv.y *= ar;
    
    //basic shape
    float lenUV = length(uv);
    float body = smoothstep(lenUV, lenUV + 0.35, 0.5);

    float rot = atan(uv.y, uv.x);

    //anim
    rot += sin(rot * 12.0 + time * 3.0 - lenUV * 50.0) * 0.1;
    float sinrot = sin(rot * 8.0) * 0.5 + 0.5;
    
    //arms
    float arms = sinrot * (1.0 - lenUV * 4.5) * 5.0;
    
    //eyes
    float eyeshapesL = length(uv * vec2(2.0, 1.0) + vec2(0.1, 0.0));
    float eyeshapesR = length(uv * vec2(2.25, 1.2) - vec2(0.1, -0.02));
    float pupilshapesL = length(uv * vec2(1.0, 1.0) + vec2(0.05, 0.055));
    float pupilshapesR = length(uv * vec2(1.2, 1.0) - vec2(0.05, -0.055));
    float eyes = smoothstep(eyeshapesL, eyeshapesL + 0.008, 0.1);
    eyes += smoothstep(eyeshapesR, eyeshapesR + 0.008, 0.1);
    eyes -= smoothstep(pupilshapesL, pupilshapesL + 0.005, 0.035);
    eyes -= smoothstep(pupilshapesR, pupilshapesR + 0.005, 0.035);
    
    //blinky blink
    eyes *= step(sin(time * 3.0 + cos(time * 2.0) * 2.0), 0.95);

    //comp
    float comp = arms + body;
    comp *= 3.0;
    comp = 1.0-clamp(comp, 0.0, 1.0);
    comp += eyes;
    glFragColor = vec4(comp);
}
