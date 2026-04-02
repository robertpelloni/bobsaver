#version 420

// original https://www.shadertoy.com/view/Mt2BWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int maxIter = 1000;
float power = 2.0;
float logEscape = log(2.0);

vec2 powc(vec2 base, float power)
{
    float r = length(base);
    float angle = atan(base.y, base.x) * power;
    
    return pow(r, power) * vec2(cos(angle), sin(angle));
}

float JuliaSet(vec2 z, vec2 c, float power)
{
    float l = length(z);
    float color = exp(-l);
    int i = 0;
    for (i; i <= maxIter; i++)
    {
        z = powc(z, power) + c;
        l = length(z);
        color += exp(-l);
        if (l >= 2.0)
            break;
    }
    
    if (i >= maxIter)
        return 1.0;
    
    return color / float(maxIter);
    
}

void main(void)
{
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    
    float minDimension = min(resolution.x, resolution.y);
    vec2 complexResolution = resolution.xy / (2.0 * minDimension);
    
    vec2 complexFragmentCoord = 4.0 * (gl_FragCoord.xy / minDimension - complexResolution);
    
    vec2 complexMousePos = 4.0 * (mouse*resolution.xy.xy / minDimension - complexResolution);
    
    glFragColor.r = JuliaSet(complexFragmentCoord, complexMousePos, power);
    glFragColor.b = JuliaSet(vec2(0, 0), complexFragmentCoord, power);
    
    if (abs(length(complexFragmentCoord) - 2.0) <= 0.01)
        glFragColor.g = 1.0;
}
