#version 420

// original https://www.shadertoy.com/view/tdSyWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(float x) {
    return mod(sin(x * 1267.123 + 2346.723) * 13212.32 , 1.);
}
float noise(vec2 pos) {
    //return noise(sin(pos.x * 1823.213 + 71322.123) * 381237. + sin(pos.y  *46372.123 + 6721.12) * 21973.213);
    return noise(noise(pos.x) * 7821.23 + noise(pos.y) * 13798.321);
}
float noise(vec3 pos) {
    return noise(noise(pos.xy * 1239.2136 + 213.21) * 2678.213 + noise(pos.xz * 1387. + 2137.) * 7312.321 + noise(pos.yz * 168. + 1237.) * 123.321);
}
vec2 pixelate(vec2 pos, vec2 cell) {
    return floor(pos / cell) * cell;
}

float perlin(vec2 p)
{
    vec2 fl = floor(p);
    vec2 fr = fract(p);
    
    fr.x = smoothstep(0.0,1.0,fr.x);
    fr.y = smoothstep(0.0,1.0,fr.y);
    
    float a = mix(noise(fl + vec2(0.0,0.0)), noise(fl + vec2(1.0,0.0)),fr.x);
    float b = mix(noise(fl + vec2(0.0,1.0)), noise(fl + vec2(1.0,1.0)),fr.x);
    
    return mix(a,b,fr.y);
}
float perlin(vec3 p) {
    vec3 fl = floor(p);
    vec3 fr = fract(p);
    
    fr = smoothstep(0.,1.,fr);
    
    float a = noise(fl + vec3(0., 0., 0.)),
          b = noise(fl + vec3(1., 0., 0.)),
          c = noise(fl + vec3(1., 1., 0.)),
          d = noise(fl + vec3(0., 1., 0.)),
          e = noise(fl + vec3(0., 0., 1.)),
          f = noise(fl + vec3(1., 0., 1.)),
          g = noise(fl + vec3(1., 1., 1.)),
          h = noise(fl + vec3(0., 1., 1.));
    float ab = mix(a, b, fr.x),
          dc = mix(d, c, fr.x),
          ef = mix(e, f, fr.x),
          hg = mix(h, g, fr.x);
    float abef = mix(ab, ef, fr.z), dchg = mix(dc, hg, fr.z);
    return mix(abef, dchg, fr.y);
}
mat2x2 rotate(float a) {
    return mat2x2(cos(a), -sin(a), sin(a), cos(a));
} 
float fbm(vec2 p)
{
    float result = 0.;
    float gain = .5, lacunarity = 2.;
    
    float cur_gain = 1.;
    int iterations = 5;
    for(int i = 0;i < iterations; i++)
    {
        result += perlin(p) * cur_gain;
        p = rotate(1.3) * p * lacunarity;
        cur_gain *= gain;
    }
    result /= (pow(gain, float(iterations)) - 1.) / (gain - 1.);
    return result;
}
float fbm(vec3 p)
{
    float result = 0.;
    float gain = .5, lacunarity = 2.;
    
    float cur_gain = 1.;
    int iterations = 2;
    for(int i = 0;i < iterations; i++)
    {
        result += perlin(p) * cur_gain;
        p = p * lacunarity;
        cur_gain *= gain;
    }
    result /= (pow(gain, float(iterations)) - 1.) / (gain - 1.);
    return result;
}
float fbm(vec2 p, float height)
{
    return fbm(vec3(p, height));
}

const vec3 red = vec3(255., 0., 0.) / 256.;
const vec3 orange = vec3(255., 127., 0.) / 256.;
const vec3 yellow = vec3(255., 255., 0.) / 256.;
const vec3 green = vec3(0., 255., 0.) / 256.;
const vec3 blue = vec3(80., 80., 255.) / 256.;
const vec3 purple = vec3(129., 0., 127.) / 256.;
const vec3 pink = vec3(255., 192., 203.) / 256.;

float between(float left, float right, float x) {
    return step(left, x) * step(x, right);
}

void main(void)
{
    // Pixelated coordinates
    vec2 uv = gl_FragCoord.xy/min(resolution.x, resolution.y);
    //uv = pixelate(uv, vec2(0.01, 0.01));

    // Assigning color depending on value
    float level = clamp(length(uv + fbm(vec3(uv * 8. + time, time)) / 6.) / 2.2, 0., 1.);
    vec3 col = vec3(0.);
    col += between(0., .14, level) * pink;
    col += between(.14, .28, level) * purple;
    col += between(.28, .42, level) * blue;
    col += between(.42, .56, level) * green;
    col += between(.56, .68, level) * yellow;
    col += between(.68, .8, level) * orange;
    col += between(.8, 1., level) * red;
    
    // Adding noise (idk why)
    //col = col * (50. + noise(pixelate(uv, vec2(0.01)) + time)) / 51.;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
