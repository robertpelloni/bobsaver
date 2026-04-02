#version 420

// S m o k e
// by Matteo Basei
// http://www.matteo-basei.it
// https://www.youtube.com/c/matteobasei

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

vec4 permute(vec4 value)
{
    return mod(value * (1.0 + 42.0 * value), 317.0);
}

vec3 sigmoid(vec3 value)
{
    return value * value * (3.0 - 2.0 * value);
}

float noise(vec3 point)
{
    const vec4 vec0011 = vec4(0, 0, 1, 1);
    
    vec3 floorPoint = floor(point);
    vec3 fractPoint = point - floorPoint;
    vec3 sigmoidPoint = sigmoid(fractPoint);
    
    vec4 a = mod(floorPoint.xyxy + vec0011, 317.0);
    vec4 b = permute(permute(a.xzxz) + a.yyww) + vec4(floorPoint.z);
    vec4 c = fract(permute(b.xzxz + vec0011) / 42.0);
    vec4 d = fract(permute(b.ywyw + vec0011) / 42.0);
    vec4 e = mix(c, d, sigmoidPoint.x);
    vec2 f = mix(e.xz, e.yw, sigmoidPoint.y);

    return 2.0 * mix(f.x, f.y, sigmoidPoint.z) - 1.0;
}

float lowFractalNoise(vec3 point, float amplitude, float frequency)
{
    float result = 0.0;
    point *= frequency;
    for (int i = 0; i < 5; ++i)
    {
        result += amplitude * noise(point);
        point *= 2.0;
        amplitude /= 2.0;
    }
    return result;
}

float highFractalNoise(vec3 point, float amplitude, float frequency)
{
    float result = 0.0;
    point *= frequency;
    for (int i = 0; i < 10; ++i)
    {
        result += amplitude * noise(point);
        point *= 2.0;
        amplitude /= 2.0;
    }
    return result;
}

void main()
{
    vec3 ambient = vec3(0.5, 0.8, 0.9);
    vec3 position = ambient + vec3(0.0, 0.0, 0.25 * time);
    
    vec2 direction = 2.0 * mouse.xy - 1.0;
    vec2 pixel = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    
    vec3 point = normalize(vec3(direction + pixel, 1.0));
    vec3 turbolence = point + highFractalNoise(position + point, 0.1, 2.0);
    vec3 final = position + turbolence;
    
    vec3 color = ambient;
    color.r += lowFractalNoise(final + 1.0, 0.1, 3.0);
    color.g += lowFractalNoise(final + 2.0, 0.1, 3.0);
    color.b += lowFractalNoise(final + 3.0, 0.1, 3.0);
    
    float value = clamp(1.0 + highFractalNoise(final, 0.5, 2.0), 0.0, 1.0);
    
    glFragColor = vec4(vec3(0.75) - color * value, 1.0);
}
