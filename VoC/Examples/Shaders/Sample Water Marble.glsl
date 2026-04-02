#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdXyDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}
uint hash( uvec2 v ) { 
    return hash( v.x ^ hash(v.y)); 
}

float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}
float random( vec2  v ) { 
    return floatConstruct(hash(floatBitsToUint(v)));
}

float noise(vec2 uv){
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float noise( vec2 uv, float detail){
    float n = 0.;
    float m = 0.;

    for(float i = 0.; i < detail; i++){
        float x = pow(2., i);
        float y = 1./x;
        
        n += noise(uv*x+y)*y;
        m += y;
    }
    
    return n/m;
    
}
mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    
    uv *= 15.;
     
    
    float n = noise(uv,7.);
    uv *= rot(n+time*.01)*n;
    
    vec3 col = mix(vec3(0.,0.,.1),vec3(0.,1.,1.),noise(uv+time*vec2(0.,.6), 2.));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
