#version 420

// original https://www.shadertoy.com/view/WdX3DH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float modValue = 512.0f;

float permuteX(float x)
{
    float t = ((x * 67.0) + 71.0) * x;
    return mod(t, modValue);
}

float permuteY(float x)
{
    float t = ((x * 73.0) + 83.0) * x;
    return mod(t, modValue);
}

float permuteZ(float x)
{
    float t = ((x * 103.0) + 109.0) * x;
    return mod(t, modValue);
}

float shiftX(float value)
{
    return fract(value * (1.0 / 73.0));
}

float shiftY(float value)
{
    return fract(value * (1.0 / 69.0));
}

float shiftZ(float value)
{
    return fract(value * (1.0 / 89.0));
}

vec3 rand(vec3 v)
{
    v = mod(v, modValue);
    float rX = permuteX(permuteX(permuteX(v.x) + v.y) + v.z);
    float rY = permuteY(permuteY(permuteY(v.x) + v.y) + v.z);
    float rZ = permuteZ(permuteZ(permuteZ(v.x) + v.y) + v.z);
    return vec3(shiftX(rX), shiftY(rY), shiftZ(rZ));
}

vec3 worleyNoise(vec3 uvw, float worleyNoise)
{
    vec3 p = floor(uvw);
    vec3 f = fract(uvw);
    
    float dis = 1e9f;
    float result;
    int range = 1;
    for(int i = -range; i <= range; i++)
    {
        for(int j = -range; j <= range; j++)
        {
            for(int k = -range; k <= range; k++)
            {
                vec3 b = vec3(i, j, k);
                vec3 r = rand(p + b);
                
                //vec3 m = b - f + r * worleyNoise;
                vec3 m = abs(b - f + r * worleyNoise);
                
                //float len = length(m);
                //float len = dot(m, m) + m.x * m.y + m.x * m.z  + m.y * m.z;
                float tolerance = 0.0f;
                float powVal = 2.0f;
                float len = pow(pow(m.x, powVal) + pow(m.y, powVal) + pow(m.z, powVal), 1.0f / powVal) - tolerance;
                
                if (dis > len)
                {
                    dis = len;
                    //result = r.x;
                    result = dis;
                }
            }
        }
    }
    
    return vec3(1.0f - result);
}

vec3 noise_sum(vec3 p, float worleyScale, int depth, float scale, float spread)
{
    vec3 f = vec3(0.0);
    for(int i = 0; i < depth; i++)
    {
        f += scale * worleyNoise(p, worleyScale); 
        p.z += 50.0f * f.x; // 关键语句 WTF？
        p *= spread;
        scale *= 0.5f;
    }
    
    return f;
}

void main(void)
{
    // Normalized pixel coordinates (fro m 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xx;
    
    vec3 col = worleyNoise(vec3(uv * 12.0f, time * 0.2), 1.0f);
    //col = worleyNoise(vec3(col * 0.5f), length(col));
    
    col = noise_sum(vec3(uv * 12.0f, time * 0.2), 1.0f, 5, 0.5f, 2.0f);

    // Output to screen
    glFragColor = vec4(col, 1.0f);
} 
