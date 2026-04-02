#version 420

// original https://www.shadertoy.com/view/3dX3zn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float speed = 2.0;
float brightness = 1.7;

float rand(in vec2 p, float speed)
{
    float t = speed > 0.0 ? floor(time * speed) : 1.0;
    return fract(
        sin(
            dot(p, vec2(t * 67.0, t * 76.0))
        ) * 67.76
    );
}

float noise(in vec2 uv, float block)
{   
    vec2 fr = fract(uv);
    vec2 op = floor(uv);

    // here you don't have to add vec2(0,0) but... consistency
    float a = rand(op+vec2(0,0), block);
    float b = rand(op+vec2(1,0), block);
    float c = rand(op+vec2(0,1), block);
    float d = rand(op+vec2(1,1), block);

    // u = step(block, lv);
    // you can use step above if you want complete blockiness.
    vec2 u;
    if ( block > 0.0 )
        u = smoothstep(0.0, 1.0 + block, fr);
    else
        u = fr * fr * (3.0 - 2.0 * fr);

    // just mix a bunch of values up.
   return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

// Fractal Brownian Motion
float fbm(vec2 uv, int octaves, float block)
{
    // In this case just how narrow do you want the glitch lines.
    float lacunarity = 10.0;
    
    // how much increase in amplitude each octave
    float gain = 0.5;

    // our ending value, and amplitude
    float v = 0.0;
    float amp = 0.5;

    // loop for octaves
    for ( int i = 0; i < octaves; i++ ) 
    {
        v += amp * noise(uv, block);
        amp *= gain;
        uv *= lacunarity;    
    }
    
    return v;
}

float getTime() { return time * 0.5 * speed; }

float fbm2(in vec2 uv, int octaves)
{
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(22.0);
    
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(uv, -2.0);
        uv = rot * uv * 2.0 + shift;
        a *= 0.5;
    }
    
    return v;
}

// Noise inception
vec4 smoke(vec2 uv2, int octaves)
{
    vec3 color = vec3(0.0);
    vec2 q = vec2(0.);
    vec2 r = vec2(0.);
    
    // first fbm vec
    q.x = fbm2(uv2 + 0.01 * getTime() * vec2(0.10), octaves);
    q.y = fbm2(uv2 + 0.1 * getTime() * vec2(-0.50) , octaves);

    // 2nd fbm vec + 1 fbm vec
    r.x = fbm2(uv2 + 2.1*q + vec2(0.0, 1.0) * 0.1*sin(getTime()), octaves);
    r.y = fbm2(uv2 + 3.0*q + vec2(1.0, 0.0) * 0.1*sin(getTime()), octaves);

    // float of an 2nd fbm vec containing 1st fbm vec
    float f = fbm2(uv2+r, octaves);

    vec3 c1 = vec3(1.0, 0.2, 0.4);
    vec3 c2 = vec3(0.0, 0.0, 0.3);
    vec3 c3 = vec3(0.0, 0.5, 0.45);
    vec3 c4 = vec3(0.4, 0.4, 0.4);

    color = mix(c2,
                c1,
                clamp((f*f),0.0,1.0));

    color = mix(color,
                c3,
                clamp(length(q),0.0,1.0));

    color = mix(color,
                c4,
                clamp(length(r.x),0.0,1.0));

    return vec4((f*f*f+.6*f*f+.5*f)*color,1.);

}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x / resolution.y;
    vec2 a = vec2(uv.x * aspect , uv.y);
    vec2 uv2 = vec2(a.x / resolution.x, exp(a.y));
    
    glFragColor = vec4(0.1, 0.1, 0.1, 1.0);
    // glFragColor = glitch(uv, uv2);
    
    glFragColor = glFragColor + smoke(uv*2.5, 3) * brightness;
    
    glFragColor = 2.0 * brightness * smoke(uv*2.5, 5) - glFragColor;
    
    glFragColor = glFragColor - smoke(uv *2.5, 10) * vec4(0.0, 0.05, 0.1, 1.0) * brightness * brightness;
}
