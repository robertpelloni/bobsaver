#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 getWaveColor(vec2 uv, float waveFactor, float timeFactor, float heightFactor, float smoothFactor, vec3 topColor, vec3 bottomColor)
{
    float time = time * timeFactor;
    
    float value = sin(uv.x * waveFactor + time);
    
    value += cos(uv.x * waveFactor * 2.0 + time * 2.0) * 0.5;
    value += sin(uv.x * waveFactor * 4.0 + time * 4.0) * 0.2;
    
    value = (value + 1.7) / 3.4;

    float height = uv.y * heightFactor;
    
    float alpha = smoothstep(height, height + smoothFactor, value);

    float colorHeight = height * 1.1;
    
    float colorAlpha = 1.0 - smoothstep(colorHeight, colorHeight + 1.0, value);
    
    vec3 color = mix(topColor, bottomColor, colorAlpha);
    
    return vec4(color, alpha);
}

void main( void )
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy);

    vec3 color = mix(
        vec3(0.3, 0.2, 0.2),
        vec3(0.5, 0.6, 1.0),
        uv.y );
    
    vec4 hill;
    
    hill = getWaveColor(
        uv, 
        10.0,
        0.4,
        1.3,
        0.01,
        vec3(0.3, 0.3, 0.1), 
        vec3(0.8, 0.8, 0.8));
    
    color = mix(color, hill.rgb, hill.a);

    hill = getWaveColor(
        uv, 
        4.0,
        0.25,
        2.0,
        0.01,
        vec3(0.1, 0.3, 0.2), 
        vec3(0.2, 0.4, 0.3));
    
    color = mix(color, hill.rgb, hill.a);

    hill = getWaveColor(
        uv, 
        8.0,
        1.1,
        5.0,
        0.01,
        vec3(0.1, 0.5, 0.3), 
        vec3(0.2, 0.6, 0.4));
    
    color = mix(color, hill.rgb, hill.a);

    hill = getWaveColor(
        uv, 
        6.0,
        2.0,
        3.0,
        0.01,
        vec3(0.0, 0.6, 0.3), 
        vec3(0.0, 0.8, 0.5));
    
    color = mix(color, hill.rgb, hill.a);

    glFragColor = vec4(color,1.0);
}
