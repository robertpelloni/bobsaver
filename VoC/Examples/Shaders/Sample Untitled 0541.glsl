#version 420

// original https://www.shadertoy.com/view/3dlyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(in vec2 _st, in float _radius) {
    vec2 l = _st-vec2(0.5);
    return smoothstep(_radius+9./resolution.y,
                         _radius-9./resolution.y,
                         dot(l,l)*4.0);
}

float circlePattern(vec2 st, float r) {
    return  circle(st+vec2(0.,-.5), r)+
            circle(st+vec2(0.,.5), r)+
            circle(st+vec2(-.5,0.), r)+
            circle(st+vec2(.5,0.), r);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;

    uv *= 4.0;
    uv = fract(uv);

    glFragColor = vec4(0.9529411765,0.8117647059,0.7803921569,1.0) * circlePattern(uv, 1.0 * sin(time) * 0.5 + 0.5);
}
