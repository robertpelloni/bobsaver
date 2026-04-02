#version 420

#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_bit_encoding : enable

// original https://www.shadertoy.com/view/7s2GDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAXSTEPS 990
#define MINDIST .01

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

vec3 randColor(vec3 center) {
    return vec3(random(center*vec3(5)), random(center*vec3(15)+vec3(50)), random(center*vec3(35)+vec3(90)));
}

vec3 cameraMovement() {
    return vec3(sin(time*1.0)*5.8,-0.5*time,time*2.8);
}

float DistanceEstimator(vec3 pos, vec3 cameraPos, out vec3 center, out vec3 normal) {
    
    // translate
    //pos = pos + cameraMovement();
    
    center = floor(pos/2.0)*2.0+1.;
    float rand = random(center*30.);
    float randRad = random(center*20.+44.)*0.5+0.5;
    vec3 offsCenter = center + vec3(sin(time*4.0+rand*27.0)*0.3,sin(time*5.0+rand*9.0)*0.3,0);
    normal = normalize(pos - offsCenter);

    float d1 = distance(mod(pos, 2.), mod(offsCenter, 2.))-.42321 * randRad;
    
    return d1;
}

vec3 trace(vec3 from, vec3 direction) {
    float totalDistance = 0.0;
    int steps;
    vec3 lastP = vec3(0);
    vec3 lastCenter = vec3(0);
    vec3 lastNormal = vec3(0);
    for (steps=0; steps < MAXSTEPS; steps++) {
        vec3 p = from + totalDistance * direction;
        float dist = DistanceEstimator(p, from, lastCenter, lastNormal);
        totalDistance += dist;
        lastP = p;
        if (dist < MINDIST) break;
    }
    //lastP += cameraMovement(); 
    vec3 center = lastCenter;
    vec3 normal = lastNormal;
    float light = dot(normal, normalize(vec3(0.6,1,-0.2)));
    vec3 amb = pow(light*0.5+0.5, 0.8) * vec3(0.3, 0.45, 0.6);
    return (amb + clamp(light, 0., 1.)*vec3(1.5, 1.3, 0.8)) * randColor(center);
}

vec3 aces_tonemap(vec3 color){    
    mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
    );
    mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
    );
    vec3 v = m1 * color;    
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));    
}

void main(void) {
    
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    vec3 camPos = vec3(0, 2, 0) + cameraMovement();
    vec3 camViewDir = normalize(vec3(uv.xy, 1));
    
    vec3 dist = trace(camPos, camViewDir);
    
    glFragColor = vec4(aces_tonemap(dist), 1.0);
}
