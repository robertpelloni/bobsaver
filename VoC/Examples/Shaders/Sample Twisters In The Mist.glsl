#version 420

// original https://www.shadertoy.com/view/wdfcR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 col1 = vec3(1.0, 0.4, 0.0) * 1.0;
vec3 col2 = vec3(0.5, 1.0, 0.0) * 1.0;
vec3 col3 = vec3(0.0, 0.8, 1.0) * 1.0;
vec3 col4 = vec3(0.7, 0.0, 1.0) * 1.0;

vec3 sk;

float yb(float y0, float y1, float y)
{
    //return y0 < y && y1 > y ? min(1.1, smoothstep(y0, y1, y)*1.0 + 0.7) : 0.;
    float ss = (smoothstep(y1, (y0 + y1)*0.5, y) * smoothstep(y0, (y0 + y1) * 0.5, y))*0.5;
    return y0 < y && y1 > y ? min(1.1, sqrt(sqrt(sqrt(ss)))*1.2 + ss) : 0.;
}

float st(float y0, float a, float d, float y)
{
    return yb(y0 + sin(a) * d - cos(a) * d, 
              y0 + sin(a) * d + cos(a) * d, y);
}

vec3 twister(vec3 color, float y0, float a, float d, float y, float z)
{
    float f = min(1., exp(-z * 0.00065));
    
    vec3 col = mix(color, col1, st(y0, a, d, y));
    
    a += 1.570;
    col = mix(col, col2, st(y0, a, d, y));
    
    a += 1.570;
    col = mix(col, col3, st(y0, a, d, y));
    
    a += 1.570;
    col = mix(col, col4, st(y0, a, d, y));
    
    return sk * (1. - f) + col * f;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x -= 0.5;
    
    float sy = sin(uv.y+1.57);
    sk = vec3(sy*sy * 0.3 + (1. - sy) * 0.9, sy*sy*0.7, sy*1.5);
    vec3 col = sk;
    
    float s = time * 5.;
    
    for (int i = 40 + int(s); i >= int(s); --i) {
        float ri = float(i);
        
        float a = sin(time * (cos(ri) + 1.1));
        float ax = uv.y * 7. * sin(time * cos(ri));
        
        float z = (ri - s) * 10.;
        
        if (z < 0.)
            continue;
        
        float x = ((cos(ri * 0.87) + sin(ri * 0.87)) * 45.7);
        
        if (x < 10. && x > 0.)
            x += 12.;
        
        if (x > -10. && x < 0.)
            x -= 12.;
            
        col = twister(col, x / z, a + ax + cos(ri), 3. / max(abs(z), 1.), uv.x, z);
    }
    
    glFragColor = vec4(col, 1.0);
}
