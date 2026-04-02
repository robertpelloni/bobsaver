#version 420

// original https://www.shadertoy.com/view/dtccWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// implementation of MurmurHash (https://sites.google.com/site/murmurhash/) for a 
// single unsigned integer.

uint hash(uint x, uint seed) {
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process input
    uint k = x;
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // some final mixing
    hash ^= hash >> 13;
    hash *= m;
    hash ^= hash >> 15;
    return hash;
}

// implementation of MurmurHash (https://sites.google.com/site/murmurhash/) for a  
// 3-dimensional unsigned integer input vector.

uint hash(uvec3 x, uint seed){
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process first vector element
    uint k = x.x; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // process second vector element
    k = x.y; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // process third vector element
    k = x.z; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // some final mixing
    hash ^= hash >> 13;
    hash *= m;
    hash ^= hash >> 15;
    return hash;
}

vec3 gradientDirection(uint hash) {
    switch (int(hash) & 15) { // look at the last four bits to pick a gradient direction
    case 0:
        return vec3(1, 1, 0);
    case 1:
        return vec3(-1, 1, 0);
    case 2:
        return vec3(1, -1, 0);
    case 3:
        return vec3(-1, -1, 0);
    case 4:
        return vec3(1, 0, 1);
    case 5:
        return vec3(-1, 0, 1);
    case 6:
        return vec3(1, 0, -1);
    case 7:
        return vec3(-1, 0, -1);
    case 8:
        return vec3(0, 1, 1);
    case 9:
        return vec3(0, -1, 1);
    case 10:
        return vec3(0, 1, -1);
    case 11:
        return vec3(0, -1, -1);
    case 12:
        return vec3(1, 1, 0);
    case 13:
        return vec3(-1, 1, 0);
    case 14:
        return vec3(0, -1, 1);
    case 15:
        return vec3(0, -1, -1);
    }
}

float interpolate(float value1, float value2, float value3, float value4, float value5, float value6, float value7, float value8, vec3 t) {
    return mix(
        mix(mix(value1, value2, t.x), mix(value3, value4, t.x), t.y),
        mix(mix(value5, value6, t.x), mix(value7, value8, t.x), t.y),
        t.z
    );
}

vec3 fade(vec3 t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlinNoise(vec3 position, uint seed) {
    vec3 floorPosition = floor(position);
    vec3 fractPosition = position - floorPosition;
    uvec3 cellCoordinates = uvec3(floorPosition);
    float value1 = dot(gradientDirection(hash(cellCoordinates, seed)), fractPosition);
    float value2 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 0, 0)), seed)), fractPosition - vec3(1, 0, 0));
    float value3 = dot(gradientDirection(hash((cellCoordinates + uvec3(0, 1, 0)), seed)), fractPosition - vec3(0, 1, 0));
    float value4 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 1, 0)), seed)), fractPosition - vec3(1, 1, 0));
    float value5 = dot(gradientDirection(hash((cellCoordinates + uvec3(0, 0, 1)), seed)), fractPosition - vec3(0, 0, 1));
    float value6 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 0, 1)), seed)), fractPosition - vec3(1, 0, 1));
    float value7 = dot(gradientDirection(hash((cellCoordinates + uvec3(0, 1, 1)), seed)), fractPosition - vec3(0, 1, 1));
    float value8 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 1, 1)), seed)), fractPosition - vec3(1, 1, 1));
    return interpolate(value1, value2, value3, value4, value5, value6, value7, value8, fade(fractPosition));
}

float perlinNoise(vec3 position, int frequency, int octaveCount, float persistence, float lacunarity, uint seed) {
    float value = 0.0;
    float amplitude = 1.0;
    float currentFrequency = float(frequency);
    uint currentSeed = seed;
    for (int i = 0; i < octaveCount; i++) {
        currentSeed = hash(currentSeed, 0x0U); // create a new seed for each octave
        value += perlinNoise(position * currentFrequency, currentSeed) * amplitude;
        amplitude *= persistence;
        currentFrequency *= lacunarity;
    }
    return value;
}

float lum(vec3 c) {
    return (c[0]*0.3) + (c[1]*0.59) + (c[2]*.11);
}

void main(void) {

    vec3 colors[10] = vec3[10](
      vec3(1.0, 0.0, 0.0),        
      vec3(1.0, 1.0, 0.0),
      vec3(1.0, 0.0, 1.0),
      vec3(0.0, 1.0, 0.0),
      vec3(0.0, 1.0, 1.0),
      vec3(0.0, 0.0, 1.0),
      vec3(1.0, 1.0, 1.0),
      vec3(0.0, 0.0, 0.0),
      vec3(0.0, 0.5, 0.5),
      vec3(0.5, 0.5, 0.0)
    ); 

    vec2 post = vec2(gl_FragCoord.xy[0], gl_FragCoord.xy[1] - 1.0) / resolution.xy;
    vec2 pos  = gl_FragCoord.xy / resolution.xy;
    vec2 posb = vec2(gl_FragCoord.xy.x, gl_FragCoord.xy.y + 1.0) / resolution.xy;
    vec2 posl = vec2(gl_FragCoord.xy.x - 1.0, gl_FragCoord.xy.y) / resolution.xy;
    vec2 posr = vec2(gl_FragCoord.xy.x + 1.0, gl_FragCoord.xy.y) / resolution.xy;

    pos.x *= resolution.x / resolution.y;
    post.x *= resolution.x / resolution.y;
    posb.x *= resolution.x / resolution.y;
    posl.x *= resolution.x / resolution.y;
    posr.x *= resolution.x / resolution.y;
    uint seed = 0x578437adU; // can be set to something else if you want a different set of random values
    float z = time * 0.01;
    int freq = 5;
    int octave = 3;
    float persistence = 0.5;
    float lacunarity = 2.0;
    // float frequency = 16.0;
    // float value = perlinNoise(position * frequency, seed); // single octave perlin noise
    
    float valueback = perlinNoise(vec3(pos + vec2(100.0,100.0), z), freq, octave, persistence, lacunarity, seed); // multiple octaves
    valueback = (valueback + 1.0) * 0.5;
    
    float value = perlinNoise(vec3(pos, z), freq, octave, persistence, lacunarity, seed); // multiple octaves
    value = (value + 1.0) * 0.5;
    value = floor(value * 10.0) / 10.0;
    
    float valuet = perlinNoise(vec3(post, z), freq, octave, persistence, lacunarity, seed); // multiple octaves
    valuet = (valuet + 1.0) * 0.5;
    valuet = floor(valuet * 10.0) / 10.0;
    
    float valueb = perlinNoise(vec3(posb, z), freq, octave, persistence, lacunarity, seed); // multiple octaves
    valueb = (valueb + 1.0) * 0.5;
    valueb = floor(valueb * 10.0) / 10.0;
    
    float valuel = perlinNoise(vec3(posl, z), freq, octave, persistence, lacunarity, seed); // multiple octaves
    valuel = (valuel + 1.0) * 0.5;
    valuel = floor(valuel * 10.0) / 10.0;
    
    float valuer = perlinNoise(vec3(posr, z), freq, octave, persistence, lacunarity, seed); // multiple octaves
    valuer = (valuer + 1.0) * 0.5;
    valuer = floor(valuer * 10.0) / 10.0;
    
    float lumc = lum(vec3(value));
    float lumt = lum(vec3(valuet));    
    float lumb = lum(vec3(valueb));    
    float luml = lum(vec3(valuel));
    float lumr = lum(vec3(valuer));
    
    vec3 purple = vec3(1.0, 0.0, 1.0);    
    vec3 cyan = vec3(0.0, 1.0, 1.0);

    
    float lap = lumt + lumb + lumr + luml - (4.0 * lumc);
    if (lap > .01) lap = 1.0;
    vec3 res = ((purple * valueback) * lap) + ((cyan * (1.0 - valueback)) * lap);
    res = res + (value * vec3(0.0, 0.0, 0.2));
    glFragColor = vec4(vec3(res), 1.0);
}
