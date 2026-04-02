#version 420

// original https://www.shadertoy.com/view/fsKyDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

float bwave(vec2 uv, float sc, float r) {
    uv *= sc;
    float fx = fract(uv.x) - 0.5;
    float ix = floor(uv.x) + 0.5;
    
    float wave = thc(2., uv.x + time);
    float wave2 = thc(2., ix + time);
    
    float d = uv.y - wave;
    d = smin(d, length(vec2(fx, uv.y - wave2)) - r, 0.25);
    
    float k = sc / resolution.y;
    return smoothstep(-k, k, -d);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
   
    float time = time + 1500.;
   
    float sc = 12. + 4. * thc(1.5, 0.5 * time + 0.75 * uv.x);
    uv.x += 0.2 * time / sc;
    uv.y -= 0.05 * thc(0.5, 0.5 * time + 0.75 * uv.x);
    
    vec3 col = vec3(0,48,59)/255.,
         col1 = vec3(255,119,119)/255.,
         col2 = vec3(255,206,150)/255.,
         col3 = vec3(241,242,218)/255.;

    float o = 2. * pi / 3.;

    float t = uv.x + time;
    float r1 = 0.35 + 0.15 * thc(3., t);
    float r2 = 0.35 + 0.15 * thc(3., t + o);
    float r3 = 0.35 + 0.15 * thc(3., t - o);
    
    float x1 = 0.125 + 0.075 * thc(1., time + uv.y);
    float x2 = 0.25  + 0.075 * thc(1., time + uv.y + o);
    float x3 = 0.375 + 0.075 * thc(1., time + uv.y - o);
    
    float y1 = 0.25/sc - 0.22 + 0.075 * cos(t);
    float y2 = 0.25/sc - 0.   + 0.075 * cos(t + o);
    float y3 = 0.25/sc + 0.22 + 0.075 * cos(t - o);
    
    float w1 = bwave(uv + vec2(x1, y1), sc, r1);
    float w2 = bwave(uv + vec2(x2, y2), sc, r2);   
    float w3 = bwave(uv + vec2(x3, y3), sc, r3);
    
    col = mix(col, col1, w1);              
    col = mix(col, col2, w2);              
    col = mix(col, col3, w3);
                
    glFragColor = vec4(col,1.0);
}
