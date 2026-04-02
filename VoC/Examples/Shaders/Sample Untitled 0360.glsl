#version 420

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

const float SPEED = 2.0;
const float RADIUS = 0.25;
const float BRIGHTNESS = 2.0;

vec2 random2(vec2 st)
{
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

void main()
{
    vec2 st = gl_FragCoord.xy / min(resolution.x, resolution.y);
    float color;

    st *= 10.0; //division

    vec2 ipos = floor(st);
    vec2 fpos = fract(st);

    vec2 point = random2(ipos);

    float direction = mod(ipos.x, 2.0) * 2.0 - 1.0;

    float t = time;
    point += vec2(cos(t), sin(t)) * direction;

    vec2 diff = point - fpos;
    float distance = length(diff);

    color = length(distance);
    glFragColor = vec4(vec3(color),1.0);
}
