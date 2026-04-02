#version 420

// original https://www.shadertoy.com/view/WdXSWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
        dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float noiseAlt(vec2 uv)
{
    vec2 _uv = uv;
    uv /= 512.0;
    uv += vec2(500.0);
    float v = snoise(uv)*0.5+0.5;
    v += snoise(uv*2.0)*0.4;
    v += snoise(uv*4.0)*0.2;
    v += snoise(uv*8.0)*0.1;
    v += snoise(uv*16.0)*0.05;
    v += snoise(uv*32.0)*0.02;
    v -= 0.2;
    v = max(v, 0.0);
    v = pow(v, 2.0);
    float d = length(_uv);
    v -= pow(d/256.0, 2.0);
    v += snoise(_uv/128.0 - vec2(500.0))*0.15 + 0.7;
    //v = max(v, 0.0);
    return v;
}

float noiseMoist(vec2 uv)
{
    uv /= 512.0;
    float v = snoise(uv)*0.5+0.5;
    v += snoise(uv*2.0)*0.4;
    v += snoise(uv*4.0)*0.2;
    v += snoise(uv*8.0)*0.1;
    v += snoise(uv*16.0)*0.05;
    v += snoise(uv*32.0)*0.02;
    v += 0.1;
    v = max(v, 0.0);
    v = pow(v, 2.0);
    return v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy - resolution.xy*0.5;
    float scale = sin(time*0.5)*0.5 + 0.75;
    //scale = 1.0;
    uv += (mouse*resolution.xy.xy - resolution.xy*0.5)/scale*(1.25 - scale);
    uv.y = -uv.y;
    uv *= scale;
    vec2 p = floor(uv);
    
    float alt = noiseAlt(p);
    float moist = noiseMoist(p);
    
    vec3 c = vec3(0.0, 0.0, 152.0); // ocean
    if (alt > 0.01) {
        c = vec3(173.0, 139.0, 75.0); // sand
    }
    if (alt > 0.1) {
        c = vec3(195.0, 190.0, 142.0); // sand2
        if (moist > 0.1) {
            c = vec3(150.0, 152.0, 44.0); // grass1
        }
        if (moist > 0.2) {
            c = vec3(48.0, 60.0, 31.0); // grass2
        }
        if (moist > 0.4) {
            c = vec3(80.0, 96.0, 57.0); // grass3
        }
        if (moist > 0.6) {
            c = vec3(72.0, 147.0, 79.0); // grass4
        }
        if (moist > 0.8) {
            c = vec3(95.0, 137.0, 40.0); // grass5
        }
    }
    if (alt > 0.8) {
        if (moist < 0.6) {
            c = vec3(254.0, 254.0, 254.0); // snow
        } else {
            c = vec3(181.0, 214.0, 223.0); // ice
        }
    }
    
    float adx = alt - noiseAlt(p - vec2(1.0, 0.0));
    float ady = alt - noiseAlt(p - vec2(0.0, 1.0));
    vec3 normal = normalize(vec3(adx, ady, 0.1));
    vec3 light = normalize(vec3(1.0, 1.0, 1.0));
    float light_val = max(dot(normal, light), 0.0) + 0.4;
    
    glFragColor = vec4(c/255.0*light_val, 1.0);
}
