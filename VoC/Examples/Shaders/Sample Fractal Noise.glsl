#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/td33Rj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi2 = radians(360.);

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

// Compound versions of the hashing algorithm I whipped together.
uint hash( uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }

// Construct a float with half-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}

// Pseudo-random value in half-open range [0:1].
float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }

vec2 random_unit_vector(vec2 uv)
{
    float theta = random(uv)*pi2;    
    return vec2(cos(theta), sin(theta));
}

vec3 random_unit_vector(vec3 uv)
{
    const vec3 offset = vec3(531.2346,652.56,567.3);
    
    float theta = random(uv)*pi2;
    float phi = acos(1. - 2. * random(uv+offset));
    vec3 unit_vec;
    unit_vec.x = sin(phi) * cos(theta);
    unit_vec.y = sin(phi) * sin(theta);
    unit_vec.z = cos(phi);
    
    return unit_vec;
}

vec2 smooth_func(vec2 x)
{
    return x*x*x*((6.*x - 15.)*x + 10.);
}

vec3 smooth_func(vec3 x)
{
    return x*x*x*((6.*x - 15.)*x + 10.);
}

float value_noise(vec2 uv)
{
    vec2 lv = smoothstep(0., 1., fract(uv));
    vec2 id = floor(uv);
    
    float lb = random(id);
    float rb = random(id + vec2(1., 0.));
    float lt = random(id + vec2(0., 1.));
    float rt = random(id + vec2(1., 1.));

    return mix(mix(lb, rb, lv.x), mix(lt, rt, lv.x), lv.y);
}

float value_noise(vec3 uv)
{
    vec3 lv = smoothstep(0., 1., fract(uv));
    vec3 id = floor(uv);
    
    float lbf = random(id);
    float rbf = random(id + vec3(1., 0., 0.));
    float ltf = random(id + vec3(0., 1., 0.));
    float rtf = random(id + vec3(1., 1., 0.));
    
    float lbb = random(id + vec3(0., 0., 1.));
    float rbb = random(id + vec3(1., 0., 1.));
    float ltb = random(id + vec3(0., 1., 1.));
    float rtb = random(id + vec3(1., 1., 1.));
    
    float front = mix(mix(lbf, rbf, lv.x), mix(ltf, rtf, lv.x), lv.y);
    float back = mix(mix(lbb, rbb, lv.x), mix(ltb, rtb, lv.x), lv.y);
    return mix(front, back, lv.z);
}

float perlin_noise(vec2 uv)
{
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    vec2 lb, rb, lt, rt;
    
    lb = random_unit_vector(id);
    rb = random_unit_vector(id + vec2(1., 0.));
    lt = random_unit_vector(id + vec2(0., 1.));
    rt = random_unit_vector(id + vec2(1., 1.));
    
    float dlb = dot(lb, lv);
    float drb = dot(rb, lv - vec2(1., 0.));
    float dlt = dot(lt, lv - vec2(0., 1.));
    float drt = dot(rt, lv - vec2(1., 1.));

    lv = smooth_func(lv);

    return mix(mix(dlb, drb, lv.x), mix(dlt, drt, lv.x), lv.y)*1.41421356*0.5+0.5;
}

float perlin_noise(vec3 uv)
{
    vec3 lv = fract(uv);
    vec3 id = floor(uv);
    
    vec3 lbf, rbf, ltf, rtf, lbb, rbb, ltb, rtb;

    lbf = random_unit_vector(id);
    rbf = random_unit_vector(id + vec3(1., 0., 0.));
    ltf = random_unit_vector(id + vec3(0., 1., 0.));
    rtf = random_unit_vector(id + vec3(1., 1., 0.));
    lbb = random_unit_vector(id + vec3(0., 0., 1.));
    rbb = random_unit_vector(id + vec3(1., 0., 1.));
    ltb = random_unit_vector(id + vec3(0., 1., 1.));
    rtb = random_unit_vector(id + vec3(1., 1., 1.));
    
    float dlbf = dot(lbf, lv);
    float drbf = dot(rbf, lv - vec3(1., 0., 0.));
    float dltf = dot(ltf, lv - vec3(0., 1., 0.));
    float drtf = dot(rtf, lv - vec3(1., 1., 0.));
    
    float dlbb = dot(lbb, lv - vec3(0., 0., 1.));
    float drbb = dot(rbb, lv - vec3(1., 0., 1.));
    float dltb = dot(ltb, lv - vec3(0., 1., 1.));
    float drtb = dot(rtb, lv - vec3(1., 1., 1.));
    
    lv = smooth_func(lv);
    
    float f = mix(mix(dlbf, drbf, lv.x), mix(dltf, drtf, lv.x), lv.y);
    float b = mix(mix(dlbb, drbb, lv.x), mix(dltb, drtb, lv.x), lv.y);

    return mix(f, b, lv.z)*1.154700538*0.5+0.5;
}

float fractal_noise(vec2 uv, float octaves)
{
    float c = 0.;
    float s = 0.;
    for(float i = 0.; i < octaves; i++)
    {
        float a = pow(2., i);
        float b = 1. / a;
        c += perlin_noise(uv*a)*b;
        s += b;
    }
    
    return c / s;
}

float fractal_noise(vec3 uv, float octaves)
{
    float c = 0.;
    float s = 0.;
    for(float i = 0.; i < octaves; i++)
    {
        float a = pow(2., i);
        float b = 1. / a;
        c += perlin_noise(uv*a)*b;
        s += b;
    }
    
    return c / s;
}

float noise(vec2 uv)
{
    return fractal_noise(vec3(uv, time*0.2), 3.);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.y);

    glFragColor = vec4(hsv2rgb(vec3(noise(uv)*10., 1., 1.)), 1.);
}
