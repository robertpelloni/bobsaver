#version 420

// original https://www.shadertoy.com/view/XtK3Rt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Alexander Lemke, 2016

const float     EPSILON         = 0.001;
const float     PI              = 3.14159265359;

// noise functions based on iq's https://www.shadertoy.com/view/MslGD8
float Hash(in vec2 p)
{
    return -1.0 + 2.0 * fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float Noise(in vec2 p)
{
    vec2 n = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(Hash(n), Hash(n + vec2(1.0, 0.0)), u.x),
               mix(Hash(n + vec2(0.0, 1.0)), Hash(n + vec2(1.0)), u.x), u.y);
}

float Spiral(in vec2 texCoord, in float rotation)
{   
    float spiral = sin((50.0) * (pow(length(texCoord), 0.25) - 0.02 * atan(texCoord.x, texCoord.y) - rotation));
    return clamp(spiral, 0.0, 1.0);
}

vec3 ColoredSpiral(in vec2 texCoord, in float rotation, in vec3 c0, in vec3 c1)
{
    return mix(c0, c1, Spiral(texCoord, rotation));
}

void main(void)
{
    vec2 screenCoord = (gl_FragCoord.xy / resolution.xy);
    vec4 finalColor = vec4(1.0);

    vec2 portalCenter = vec2(sin(time * 2.0), cos(time * 2.0)) * 0.025;
    vec2 portalTexCoord = portalCenter + vec2((screenCoord.x * 2.0 - 1.0) * (resolution.x / resolution.y), (screenCoord.y * 2.0 - 1.0));
    
    vec2 pushDirection = normalize(portalTexCoord + vec2(EPSILON));
    float noise = Noise(pushDirection + time) * 0.15 * length(portalTexCoord);

    portalTexCoord = portalTexCoord + (-noise * pushDirection);
    float r = length(portalTexCoord);

    vec3 portalColor = ColoredSpiral(portalTexCoord, 0.1 * time, vec3(0.0, 0.6, 0.0), vec3(0.35, 1.0, 0.0)); 
    finalColor.rgb = mix(finalColor.rgb, mix(portalColor, vec3(0.6, 1.0, 0.35), 0.01 + (r * r)), step(r, 1.0));     

    glFragColor = finalColor;
}
