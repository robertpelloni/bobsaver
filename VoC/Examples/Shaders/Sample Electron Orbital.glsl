#version 420

// original https://www.shadertoy.com/view/4dccD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi  3.14159
#define tau 6.28318
#define numRings 15.
#define scaledTime time*3.

mat2 rotate(float rads)
{
    return mat2(vec2(cos(rads), -sin(rads)), vec2(sin(rads), cos(rads)));
}

vec3 circle(vec2 p, vec2 scale, vec2 offset)
{
    p -= offset;
    p *= vec2(1. / scale.x, 1. / scale.y);
    return mix(vec3(1.), vec3(0.), smoothstep(.0, .25, length(p) - 1.));
}

float bias(float time, float bias)
{
    return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float gain(float time, float gainAmount)
{
    time = clamp(time, 0., 1.);
    if (time < 0.5)
        return bias(time * 2.0, gainAmount) / 2.0;
    else
        return bias(time * 2.0 - 1.0, 1.0 - gainAmount) / 2.0 + 0.5;
}

float ease(float time, float gainAmount, bool flip)
{
    float t = smoothstep(0., 1., time);
    return flip ? mix(gain(time * 2., gainAmount) * .5, .5 - .5 * gain(time * 2. - 1., gainAmount), t)
        : mix(gain(time * 2., gainAmount) * .5, gain(time * 2. - 1., gainAmount) * .5 + .5, t);
}

vec3 ring(vec2 p, vec2 scale, float rads)
{
    p = rotate(rads) * p;
    p *= vec2(1. / scale.x, 1. / scale.y);
    
    float easeGrow = ease(mod(scaledTime, tau * 2.) / (tau * 2.), .16, false) * 2. * tau;
    float easeBounce = ease(mod(scaledTime, tau * 2.) / (tau * 2.), .08, true) * 2.;
    
    float angle = mod(atan(p.y, p.x) + tau, tau);
    vec2 ellipsePoint = vec2(cos(angle), sin(angle));
        
    vec3 whiteDot = circle(p, vec2(.05) / mix(scale * 2. / scale.x, vec2(1.15), easeBounce), vec2(cos(-easeGrow), sin(-easeGrow)));
    float clip = step(angle, tau * 2. - easeGrow) * step(tau * 2. - easeGrow, angle + tau);
    return clip * mix(vec3(1., 0., 0.), vec3(0.), smoothstep(.02, .03, distance(p, ellipsePoint)))
        + whiteDot;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    float easeAmount = ease(mod(scaledTime, tau * 2.) / (tau * 2.), .16, true) * 2.;
    vec2 initialScale = vec2(.9 + easeAmount * .3, 1. - easeAmount * .7);
    glFragColor.rgb = vec3(.164, .114, .27);
    
    for (float i = 0.; i < numRings; i++) 
    {
        float rads = easeAmount * (-3. * pi / 4. + i * pi / 4.) + pi / 2.;
        vec2 scale = initialScale * pow(.9, i);
        glFragColor.rgb += ring(uv, scale, rads);
    }
}
