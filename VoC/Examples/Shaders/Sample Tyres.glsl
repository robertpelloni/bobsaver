#version 420

// original https://www.shadertoy.com/view/tdK3Wt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265356989
#define PI_2 6.28318530713978
#define TYRE_COLOR         vec4(0.1, 0.1, 0.1, 1.0)
#define WHEEL_BG_COLOR     vec4(0.3, 0.3, 0.3, 1.0)
#define WHEEL_COLOR        vec4(0.7, 0.7, 0.7, 1.0)
#define WHEEL_COLOR_SHADOW vec4(0.6, 0.6, 0.6, 1.0)
#define BOLT_COLOR         vec4(0.2, 0.2, 0.2, 1.0)
const mat3 m = mat3(0.00, 1.60, 1.20, -1.60, 0.72, -0.96, -1.20, -0.96, 1.28);

mat2 rotate2d(float _angle)
{
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec3 hsv(float h, float s, float v)
{
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;
    f += 0.06250*noise( p );
    return f;
}

vec4 tyre(vec2 uv, float time)
{
    vec4 color = vec4(0,0,0,0);

    // tyre & wheel
    float dist = distance(vec2(0,0), uv);
    float angle = atan(uv.y, -uv.x);
    float angleSpeed = -time;
    angle = 1.0 - (angle + PI) / (PI * 2.0);
    angle = fract(angle + angleSpeed);
    
    // tyre
    color.rgb += step(0.4, dist) * step(dist, 0.6) * TYRE_COLOR.rgb * ((dist - 0.4) / 0.3);

    // wheel
    color.rgb = mix(color.rgb, WHEEL_COLOR.rgb * (dist / 0.4), step(dist, 0.4));
    float shadowDist = distance(vec2(0.0025, 0.0), uv);
    color.rgb = mix(color.rgb, WHEEL_COLOR_SHADOW.rgb, step(shadowDist, 0.35));
    color.rgb = mix(color.rgb, WHEEL_BG_COLOR.rgb, step(dist, 0.335));

    float wheelDistance = 0.0;
    wheelDistance = abs(clamp(sin(angle * PI_2 * 8.0) + 0.0, 0.0, 1.0)) - 0.6;
    color.rgb = mix(color.rgb, WHEEL_COLOR.rgb, step(dist, wheelDistance));
    wheelDistance = abs(clamp(sin((angle + 0.05) * PI_2 * 8.0) + 0.0, 0.0, 1.0)) - 0.6;
    color.rgb = mix(color.rgb, WHEEL_COLOR.rgb, step(dist, wheelDistance));
    wheelDistance = abs(clamp(sin((angle + 0.05) * PI_2 * 36.0 * 2.0) + 0.0, 0.0, 1.0)) - 0.3;
    color.rgb = mix(color.rgb, hsv(0.2 + time * 0.25, 0.2, 0.2), step(dist, wheelDistance) * step(0.56, dist) * step(dist, 0.59));
    wheelDistance = abs(clamp(sin((angle + 0.005) * PI_2 * 36.0 * 1.0) + 0.0, 0.0, 1.0)) - 0.3;
    color.rgb = mix(color.rgb, hsv(0.2 + time * 0.25, 0.2, 0.2), step(dist, wheelDistance) * step(0.54, dist) * step(dist, 0.59));

    color.rgb = mix(color.rgb, WHEEL_COLOR.rgb, step(dist, 0.1));
    color.rgb = mix(color.rgb, WHEEL_BG_COLOR.rgb, step(dist, 0.03));
    color.rgb = mix(color.rgb, WHEEL_COLOR_SHADOW.rgb, step(0.075, dist) * step(dist, 0.09));
    
    // bolt
    const int BOLT_NUM = 5;
    for(int i=0 ; i<BOLT_NUM ; ++i)
    {
        wheelDistance = distance(vec2(0.0, 0.0 + 0.06) * rotate2d(PI_2 / float(BOLT_NUM) * float(i) - angleSpeed * PI_2), uv);
        color.rgb = mix(color.rgb, BOLT_COLOR.rgb, step(wheelDistance, 0.025));
        color.rgb = mix(color.rgb, WHEEL_COLOR.rgb, step(wheelDistance, 0.015));
    }

    // fade
    vec3 fade = vec3(1,1,1) * (distance(vec2(1, -1) * 0.75, uv));
    color.rgb *= fade.rgb;

    // draw enable
    color.a = step(dist, 0.6);
    return color;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    // bg
    vec2 gbUV = uv * 2.0;

    // wave
    vec2 wave = uv;
    wave.x += time * 0.5;
    wave = vec2(1,0) * fbm(vec3((wave) * 0.05, 0.0)) * 2.0;
    wave.y += sin(uv.x * 2.0 + time * 3.0) * 0.15;
    wave.x += sin(uv.y * 2.0 + time * 3.0) * 0.025 + wave.y;
    gbUV += wave;
    gbUV.x += time * 0.125;
    float f = mod(step(0.5, fract(gbUV.x)) + step(0.5, fract(gbUV.y)), 2.0);
    vec3 bg = mix(vec3(1.0, 1.0, 1.0), hsv(0.2 + time * 0.25, 0.2, 0.2), f);
    glFragColor.rgb += bg * (uv.y * 0.75 + 1.0);

    const int TIRE_NUM = 10;
    const int TIRE_TYPE = 3;
    for(int y=0 ; y<TIRE_TYPE ; y++)
    {
        for(int x=0 ; x<TIRE_NUM ; x++)
        {
            vec2 tireUV = uv;
            tireUV.x += 2.0 / float(TIRE_NUM) * float(x) - (1.0 + 1.0 / float(TIRE_NUM)); // 横に整列

            float tireSpeed = mix( 0.1, 1.0, rand(vec2(x,y))) * time;
            float tireScale = float(TIRE_TYPE) - float(y) * 7.0 + 5.5;
            int tireRap = int(floor(tireUV.x + 0.5 + tireSpeed));
            tireUV.x += tireSpeed;
            tireUV.y += mix(-1.0, 1.0, rand(vec2(x+1+tireRap,y+1)));
            tireUV.x = mod(tireUV.x, 2.0) - 1.0;
            
            vec4 tireColor = tyre(tireUV * tireScale, tireSpeed);
            vec3 tireFade = vec3(1,1,1) * (uv.y + 1.5) * (float(y) + 1.0) / float(TIRE_TYPE);
            tireColor.rgb *= tireFade.rgb;
            glFragColor = mix(glFragColor, tireColor, tireColor.a);
        }
    }
}
