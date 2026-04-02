#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3sVfzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// convert 2D seed to 1D
// 2 imad
uint seed(uint x) {
    return 19u * x;
}

uint seed(uvec2 p) {
    return 19u * p.x + 47u * p.y + 101u;
}

// convert 3D seed to 1D
uint seed(uvec3 p) {
    return 19u * p.x + 47u * p.y + 101u * p.z + 131u;
}

uint seed(uvec4 p) {
    return 19u * p.x + 47u * p.y + 101u * p.z + 131u * p.w + 173u;
}

uint pcg(uint v)
{
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

float noise(float x)
{
    return float(pcg(uint(x*1000.0))) * (1.0/float(0xffffffffu));
}

vec2 noise(vec2 p)
{
    uint x = seed(uvec3(p.xy*1000.0, time*1000.1));
    float v = float(pcg(x)) * (1.0/float(0xffffffffu));
    return vec2(v);
}

float noise2( uint n ) 
{   // integer hash copied from Hugo Elias
    n = (n<<13U)^n;
    n = n*(n*n*15731U+789221U)+1376312589U;
    return float(n&uvec3(0x0fffffffU))/float(0x0fffffff);
}

// Basic noise
float bnoise( in float x )
{
    // setup    
    float i = floor(x);
    float f = fract(x);
    float s = sign(fract(x/2.0)-0.5);
    
    // use some hash to create a random value k in [0..1] from i
    float k = noise2(uint(i));

    // quartic polynomial
    return s*f*(f-1.0)*((16.0*k-4.0)*f*(f-1.0)-1.0);
}

float terrain(vec2 p)
{
    float v2 = 1.0 * bnoise(p.x*0.5);
    v2 += 0.05 * bnoise(p.x*2.2);
    v2 += 0.025 * bnoise(p.x*4.2);
    v2 += 0.0125 * bnoise(p.x*8.2);
    v2 += 0.0025 * bnoise(p.x*36.2);
    return v2;
}

vec3 noiseLine(vec2 p, vec3 col)
{
    float px = 1.0/resolution.y;
    p.x = (p.x*0.3) + 0.5;
    return mix(col, vec3(0.0,1.0,1.0), 1.0 - smoothstep(0.0, px*2.0, abs(p.y-p.x)));
}

/**
 * Convert r, g, b to normalized vec3
 */
vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}

/**
 * Draw a rectangle at vec2 `pos` with width `width`, height `height` and
 * color `color`.
 */
vec4 rectangle(vec2 uv, vec2 pos, float width, float height, vec3 color) {
    float t = 0.0;
    if ((uv.x > pos.x - width / 2.0) && (uv.x < pos.x + width / 2.0)
        && (uv.y > pos.y - height / 2.0) && (uv.y < pos.y + height / 2.0)) {
        t = 1.0;
    }
    return vec4(color, t);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float px = 1.0/resolution.y;
    vec2 p = gl_FragCoord.xy*px;
    p.x += time*2.5;

    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    vec3 col = vec3(0.5);
    
    vec2 n1 = vec2((terrain(p)+terrain(p*0.3)*2.0)*0.4, p.y);
    vec2 n2 = vec2(terrain(p*0.1), p.y);
    vec2 n3 = vec2(terrain(p*0.7), p.y);
    
    col = noiseLine(n1, col);
    col += noiseLine(n2, vec3(1.0, 0.0, 0.0));
    col += noiseLine(n3, vec3(1.0, 0.0, 0.0));
    
    vec4 r = rectangle(uv, vec2(0.4+(n1.x*-0.25), n1.x*0.3+0.514), 0.014, 0.032, vec3(1.0));
    r += rectangle(uv, vec2(0.5+(n2.x*-0.45), n2.x*0.3+0.514), 0.05, 0.032, vec3(1.0));
    r += rectangle(uv, vec2(0.6+(n3.x*-0.12), n3.x*0.3+0.508), 0.03, 0.018, vec3(1.0));
    
    glFragColor = vec4(col, 1.0);
    glFragColor = mix(glFragColor, r, r.a);
}
