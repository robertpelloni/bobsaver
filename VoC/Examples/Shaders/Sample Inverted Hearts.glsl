#version 420

// original https://www.shadertoy.com/view/NlSSD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int COLORS_SIZE = 4;
const vec3 ERR_COLOR = vec3(0.0, 0.0, 0.0);

const int SAMPLES_S = 4;
const int N_SAMPLES = SAMPLES_S * SAMPLES_S;

const float M_PI = 3.1415926535897932384626433832795;

float function(float x, float y, float t)
{
    float t2 = t / 2.0;
    float t5 = t / 4.0;
    float st2 = sin(t2);
    float st5 = sin(t5);
    float ct5 = cos(t5);
    float tt5 = tan(t5);
    
    //return (x - st5 * 1.5*y) / (sin(st2 * x + y) * tan(st5 * x - y) + 3.0*sin(ct5 * x + y) + 0.1*st2*y);
    //return (x - st5 * y) / (sin(x + st2 * y) * tan(st5 * x - y) + 4.0*sin(x + y) + 0.1*st2*y);
    //return (x - y) / (sin(x + y) * tan(t7 * x - y) + 4.0*sin(x + y) + 0.1*t2 * y);
    
    //return (x - y) / (sin(x + y) * tan(x - y) + 4.0*sin(x + y) + 0.1*y);
    //return (x - y) / (sin(t2 + x + y) * tan(x - y) + 4.0*sin(x + y) + 0.1*y);
    return (tt5 + x - st5 * 1.5*y) / (sin(t2 + x + y) * tan(st5 * x - y) + 4.0*sin(x + y) + 0.1*st2*y);
    //return tt5 * (x - 1.5*y) / (sin(x + y) * tan(x - y) + st5 * 3.0*sin(x + y) + 0.1*y);
}

vec2[N_SAMPLES] supersampling(vec2 coord, float pixSize)
{
    float sampleSize = pixSize / float(SAMPLES_S);
    vec2 leftUp = coord - pixSize / 2.0 + sampleSize / 2.0; 
    
    vec2 samples[N_SAMPLES];
    for (int i = 0; i < SAMPLES_S; i++)
    {
        for (int j = 0; j < SAMPLES_S; j++)
        {
            vec2 sampl = leftUp + vec2(sampleSize * float(j), sampleSize * float(i)); 
            samples[i * SAMPLES_S + j] = sampl;
        }
    }
    return samples;    
}

float atan2(float y, float x)
{
    if (x > 0.0)
    {
        return atan(y / x);
    }
    else if (x < 0.0 && y >= 0.0)
    {
        return atan(y / x) + M_PI;
    }    
    else if (x < 0.0 && y < 0.0)
    {
        return atan(y / x) - M_PI;
    }
    else if (x == 0.0 && y > 0.0)
    {
        return M_PI / 2.0;
    }
    else if (x == 0.0 && y < 0.0)
    {
        return -M_PI / 2.0; 
    }
    return 0.0; // undefined
}

// transform classic uv into carthesian coordinates and use defined domains
vec2 uvToCarthesian(vec2 uv, vec2 xDomain, vec2 yDomain)
{
    float x = xDomain.x + uv.x * (xDomain.y - xDomain.x);
    float y = yDomain.x + uv.y * (yDomain.y - yDomain.x);
    return vec2(x, y);
}

// transform quadrants into polar coordinates and use defined domains
vec2 quadToPolar(vec2 quad, vec2 rDomain, vec2 phiDomain)
{   
    float r = sqrt(dot(quad, quad));
    float extR = r * (rDomain.y - rDomain.x) + rDomain.x;
    // Normalize phi and revert
    float phi = 1.0 - abs(atan2(quad.y, quad.x)) / M_PI; 
    float extPhi = phi * (phiDomain.y - phiDomain.x) + phiDomain.x;
    return vec2(extR, extPhi);
}

vec3 getColor(float value, vec2 range, vec4 colors[COLORS_SIZE])
{
    // Clamp to range
    value = clamp(value, range.x, range.y);
    
    float len = range.y - range.x; 
    float norm = (value - range.x) / len;
    
    // Get two closest colors
    vec3 color = ERR_COLOR;
    for (int i = 0; i < COLORS_SIZE-1; i++)
    {
        vec4 curr = colors[i];
        vec4 next = colors[i+1];
        if (curr.w <= norm && norm <= next.w)
        {
            float btw = (norm - curr.w) / (next.w - curr.w);
            color = mix(curr.xyz, next.xyz, btw);
            break;
        }
    }
    return color;
}

void main(void)
{
    // Function domain
    const vec2 xDomain = vec2(0.0, 50.0);
    const vec2 yDomain = vec2(-0.5, 22.0);
    
    // Function range
    const vec2 range = vec2(-10.0, 1.75);
    
    // Colors
    vec4 colors[COLORS_SIZE] = vec4[](
        vec4(0.0, 0.0, 0.0, 0.0),
        vec4(0.95, 0.01, 0.218, 0.15),
        vec4(0.45, 0.0, 0.8, 0.65),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
    
    // uv - normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.y = 1.0 - uv.y;
    
    // maxUv - one coordinate with maximal resolution is normalized other is trimmed
    // quadrants - derived from maxUv - point (0.0, 0.0) is in the middle of the picture
    float maxRes = max(resolution.x, resolution.y);
    vec2 qRes = resolution.xy / maxRes;
    vec2 maxUv = gl_FragCoord.xy / maxRes;
    maxUv.y = qRes.y - maxUv.y;
    vec2 quadrants = 2.0 * maxUv - qRes;
    float quadPixSize = 2.0 / maxRes;
    
    // Supersampling
    vec2 samples[] = supersampling(quadrants, quadPixSize);
    
    vec3 totalColor = vec3(0.0);
    for (int i = 0; i < N_SAMPLES; i++)
    {
        // Calculate coord
        vec2 coord = quadToPolar(samples[i], xDomain, yDomain);

        float value = function(coord.x, coord.y, time);

        totalColor = totalColor + getColor(value, range, colors);
    }
    vec3 avgColor = totalColor / float(N_SAMPLES);    

    // Output to screen
    glFragColor = vec4(avgColor, 1.0);
}
