#version 420

// original https://www.shadertoy.com/view/7s33RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int COLORS_SIZE = 4;
const vec3 ERR_COLOR = vec3(0.0, 0.0, 0.0);

const int SAMPLES_S = 4;
const int N_SAMPLES = SAMPLES_S * SAMPLES_S;

float function(float x, float y, float t)
{
    t = t + 1.8;    
    float t2 = t / 2.0;
    float t4 = t / 4.0;
    float st2 = sin(t2);
    float ct2 = cos(t2);
    float st4 = sin(t4);
    float tt4 = tan(t4);
    
    float xr = x * cos(pow(t2, 1.01));
    float yr = y * sin(pow(t2, 1.01));
    
    return (0.4*x * cos(0.5*y)) + (tt4 * 0.6*xr * sin(xr)) + (st4 + 1.0) * pow(0.3*xr + 0.2*yr, 2.0);
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

vec2 uvToCarthesian(vec2 uv, vec2 xDomain, vec2 yDomain)
{
    float x = xDomain.x + uv.x * (xDomain.y - xDomain.x);
    float y = yDomain.x + uv.y * (yDomain.y - yDomain.x);
    return vec2(x, y);
}

vec2 getOrigin(vec2 xDomain, vec2 yDomain)
{
    float x = xDomain.x + (xDomain.y - xDomain.x) / 2.0;
    float y = yDomain.x + (yDomain.y - yDomain.x) / 2.0;
    return vec2(x, y);
}

vec2 carthesianCircleInversion(vec2 carth, vec2 o, float r)
{
    vec2 dir = carth - o;
    float x = r * r / length(dir);
    return x * normalize(dir) + o;
}

vec3 getColor(float value, vec2 range, vec4 colors[COLORS_SIZE])
{
    value = clamp(value, range.x, range.y);
    
    float len = range.y - range.x; 
    float norm = (value - range.x) / len;
    
    // Get two closest colors and mix them
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
    const vec2 xDomain = vec2(-35.0, 35.0);
    const vec2 yDomain = vec2(-25.0, 25.0);
    
    // Function range
    const vec2 range = vec2(0, 100);
    
    // Colors
    vec4 colors[COLORS_SIZE] = vec4[](
        vec4(0.0, 0.0, 0.0, 0.0),
        vec4(0.78, 0.16, 0.11, 0.34),
        vec4(0.89, 0.48, 0.21, 0.63),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
    
    vec2 origin = getOrigin(xDomain, yDomain);
    
    vec2 samples[] = supersampling(gl_FragCoord.xy, 1.0);
    vec3 totalColor = vec3(0.0);
    for (int i = 0; i < N_SAMPLES; i++)
    {
        vec2 uv = samples[i] / resolution.xy;
        uv.y = 1.0 - uv.y;
    
        vec2 coord = uvToCarthesian(uv, xDomain, yDomain);
        coord = carthesianCircleInversion(coord, origin, 22.0);

        float value = function(coord.x, coord.y, time);

        totalColor = totalColor + getColor(value, range, colors);
    }
    vec3 avgColor = totalColor / float(N_SAMPLES);    

    glFragColor = vec4(avgColor, 1.0);
}
