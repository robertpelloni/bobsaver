#version 420

// original https://www.shadertoy.com/view/MdsyRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    Please note:
    This code is pretty badly written, I just experimented with the different noises.

    Especially the hills don't really make sense. 
    I did not find a way to make them smaller in the middle and higher on the sides.

    Sources:
    ashima github, shadertoy (maybe IQ's fbm), thebookofshaders...
    and the hills are from someone on this site
    sorry if I left out somebody, this shader is just meant for fun anyway

    
    
    * TSFH song *
**/

float globalRandom = 2101.671;    // Change this for another effect

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// -------------------------------------------------------------------------------------------------------------------------------------

float random (in vec2 st) 
{ 
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))* 
        43758.5453123);
}

float noise(in vec2 st)
{
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    // 4 corners in a 2d tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = vec2(0.0);
    //u = f * f * (3.0 - 2.0 * f);
    u = f*f*f*(f*(f*6.-15.)+10.);
    
    return mix(a, b, u.x) + 
        (c - a) * u.y * (1.0 - u.x) + 
        (d - b) * u.x * u.y;
}

// -------------------------------------------------------------------------------------------------------------------------------------

#define OCTAVES 7

float fbms(in vec2 coord)
{
    float sum = 0.0;
    float f = 0.0;
    
    vec2 dir = vec2(1.0, 0.0);
    
    vec2 q = coord;

    
    for(int i = 0; i < OCTAVES; ++i)
    {
        float multip = 0.5 / pow(2.0, float(i) );
        
        f += multip * snoise(q);
        sum += multip;
        q = q * 2.01; 
    }
    
    return f / sum;
}

float fbm(in vec2 coord)
{
    float sum = 0.0;
    float f = 0.0;
    
    vec2 dir = vec2(1.0, 0.0);
    
    vec2 q = coord;

    
    for(int i = 0; i < OCTAVES; ++i)
    {
        float multip = 0.5 / pow(2.0, float(i) );
        
        f += multip * noise(q);
        sum += multip;
        q = q * 2.01; 
    }
    
    return f / sum;
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#define RIDGE_OCTAVES 1

// Ridged multifractal
// See "Texturing & Modeling, A Procedural Approach", Chapter 12
float ridge(float h, float offset) {
    h = abs(h);     // create creases
    h = offset - h; // invert so creases are at top
    //h = h * h;      // sharpen creases
    return h;
}

float ridgedMF(vec2 p) {
    float lacunarity = 2.0;
    float gain = 0.5;
    float offset = 0.9;
        
    float sum = 0.0;
    float freq = 1.0, amp = 0.5;
    float prev = 1.0;
    for(int i=0; i < RIDGE_OCTAVES; i++) {
        float n = ridge(snoise(p*freq), offset);
        sum += n*amp;
        sum += n*amp*prev;  // scale by previous octave
        prev = n;
        freq *= lacunarity;
        amp *= gain;
    }
    return sum;
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

mat2 makem2(in float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, -s, s, c);
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

float gradient(vec2 p){
    float v = 0.8 - length(p / 2.0);
    v *= v * 2.0;
    return  v * step(0.0, v);
}

float fractal(vec2 c, float val){
    vec2 o = vec2(0.0);
    
    float f1 = fbms(c * 0.7 * makem2(2.7) + val);
    
    float a1 = fbms(c * 0.2);
    float f3 = ridgedMF(c * 0.4 + val + a1 * 0.4);
    
    return f1 * f3 * 2.0;
}

float fractal2(vec2 c, float val){
    vec2 o = vec2(0.0);
    
    float f1 = fbms(c * 0.7 * makem2(2.7) + val);
    
    float a1 = fbms(c * 0.2);
    float f3 = ridgedMF(c * 0.4 + val + a1 * 0.4);
    
    float f4 = fbms(c * (0.7 + 0.9 * f1 * f3) * makem2(2.7) + val);
    
    return f4;
}

float stars(vec2 uv, float val) {    
    float n1 = random(uv*102. + val);
    float n2 = random(uv*101. + val);
    float a1 = pow(n1, 20.);
    float a2 = pow(n2, 20.);
  
    return a1 * a2;
}

// ------------------------------------------------------------------------------------------------------------------------------------------------

float hills( vec2 pp, float offsetY, float val)
{
    float x = pp.x;

    
    pp.x += val;
    pp.y += offsetY;
    
    
    // Properties
    const int octaves = 8;
    float lacunarity = 2.0;
    float gain = 0.5;
    //
    // Initial values
    float amplitude = 0.9;
    float frequency = 0.6;

    
    // Loop of octaves
    for (int i = 0; i < octaves; i++) {
        amplitude *= gain;
        pp.y += amplitude * snoise(vec2(frequency*pp.x) );
        frequency *= lacunarity;    
    }
    
    float h = pp.y;
    
    h = smoothstep( -9./resolution.y, 0., h-.8);
    
    return 1.0 - h;
}

float twoHills(float offsetY, float val, vec2 gl_FragCoord)
{
    vec2 pp = ( 2.0 * (gl_FragCoord.xy) - resolution.xy) / resolution.y;
    
    float y = pp.y;
    pp.y = y * ( (resolution.x - gl_FragCoord.x) / resolution.x * 3.5);
    
    float h1 = hills(pp, offsetY, val);
    
    pp.y = y * ( gl_FragCoord.x / resolution.x * 3.5);
    float h2 = hills(pp, offsetY, val);
    
    return h1 + h2;
}

void main(void)
{
    // Not scaled
    vec2 k = (gl_FragCoord.xy / resolution.xy - 0.5) * 2.0;
    float g = gradient(k);
    
    vec2 q = gl_FragCoord.xy / resolution.xy;
    
        vec2 p = -0.5 + 2.0 * q;
    
    if(resolution.x < resolution.y) {
           p.y *= resolution.y/resolution.x;
    }
    else{
        p.x *= resolution.x/resolution.y;
    }
    
    vec3 color = vec3(0.0);
    
    float val = globalRandom;
    
    // Rotating really sells this effect
    float c1 = fractal2(p * makem2(0.5), val + 0.3) * g;
    
    // Idea for coloring small areas
    float s1 = snoise(p + val);
    float s2 = snoise(p * 0.7 + val + 3.0);
    float s3 = snoise(p + val + 13.0);
    
    
    float st1 = stars(p, val);
    float st2 = stars(p, val + 1.0);
    float st3 = stars(p, val + 2.0);
    float st4 = stars(p, val + 3.0);
    float st5 = stars(p, val + 4.0);
    
    
    // Light blue 900 -> 400
    color = mix(vec3(0.003921569, 0.34117648, 0.60784316) * 0.5, vec3(0.16078432, 0.7137255, 0.9647059) * 1.0, c1 * s1 * 1.1);    
    
    color += st1;
    color += (st2 + st3) * c1 * s1 * 8.0;
    
    // Hills ->
    // Hills can have different colors
    vec2 pp = ( 2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    float h1 = twoHills(1.9, val + 23.0, gl_FragCoord.xy);
    
    vec3 temp = color * step(0.5, 1.0 - h1);
    color = vec3(0.003921569, 0.34117648, 0.60784316) * step(0.5, h1) * 0.3;
    color += temp;
    
    float h2 = twoHills(2.8, val + 27.0, gl_FragCoord.xy);
    temp = color * step(0.5, 1.0 - h2);
    color = vec3(0.003921569, 0.34117648, 0.60784316) * step(0.5, h2) * 0.4;
    color += temp;
        
    
    glFragColor = vec4( color, 1.0 );
}
