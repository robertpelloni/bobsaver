#version 420

// original https://www.shadertoy.com/view/llX3Rn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float RAINBOW_SPLINE_SIZE = 6.0;

/**
 * Lookup table for rainbox colors. Workaround as GLSL does not support arrays.
 * @param i: Array index; Should be integer.
 * @return The color at the given index.
 */
vec3 GetRainbowColor(float i){
    if(i == 0.0){
        return vec3(1.0, 0.0, 0.0); // Red
    }
    else if(i == 1.0){
        return vec3(1.0, 0.5, 0.0); // Orange
    }
    else if(i == 2.0){
        return vec3(1.0, 1.0, 0.0); // Yellow
    }
    else if(i == 3.0){
        return vec3(0.0, 1.0, 0.0); // Green    
    }
    else if(i == 4.0){
        return vec3(0.0, 0.0, 1.0); // Blue    
    }
    else if (i == 5.0){
        return vec3(0.27, 0.0, 0.51); // Purple
    }
    else if (i == 6.0){
        return vec3(0.57, 0.0, 1.0); // Violet    
    }

    return vec3(1.0, 1.0, 1.0); // should never get here.
}

/**
 * Perform Catmull-Rom spline interpolation between support points v1 and v2.
 * @param x: Interpolation factor between v1 and v2; Range[0.0,1.0]
 * @param v0: left most control point.
 * @param v1: left support point.
 * @param v2: right support point.
 * @param v3: right most control point.
 * @return The interpolated value.
 */
vec3 CatmullRomSpline(float x, vec3 v0, vec3 v1, vec3 v2, vec3 v3) 
{
    // Note: this spline will go through it's support points.
    vec3 c2 = -.5 * v0                + 0.5 *v2;
    vec3 c3 =         v0    + -2.5*v1     + 2.0 *v2 + -.5*v3;
    vec3 c4 = -.5 * v0    + 1.5 *v1     + -1.5*v2 + 0.5*v3;
    return(((c4 * x + c3) * x + c2) * x + v1);
}

/**
 * Evaluates the rainbox texture in UV-space using a Catmull-Rom spline.
 */
vec3 EvaluateRainbowSpline(float x){
    // x must be in range [0.0,1.0]
    float scaledX = clamp(x, 0.0, 1.0) * RAINBOW_SPLINE_SIZE;
    
    // Determine which 'rainbox segment' we are evluating:
    float segmentIndex = floor(scaledX);
    
    // Note that you evaluate between v1 and v2, using v0 and v3 as control points:
    vec3 v0 = GetRainbowColor(segmentIndex-1.0);
    vec3 v1 = GetRainbowColor(segmentIndex+0.0);
    vec3 v2 = GetRainbowColor(segmentIndex+1.0);
    vec3 v3 = GetRainbowColor(segmentIndex+2.0);
    
    return CatmullRomSpline(fract(scaledX), v0,v1,v2,v3);
}

/**
 * Creates a hashkey based on a 2D variable.
 * Note: Using haskeys directly as noise function gives non-coherent noise.
 * @return: Haskey in range [0.0, 1.0)
 */
float hash(in vec2 p){
    // Transform 2D parameter into a 1D value:
    // Note: higher value means 'higher frequency' when plugging uv coordinates.
    float h = dot(p, vec2(12.34, 56.78));
    
    // Use a sinusoid function to create both positive and negative numbers.
    // Multiply by a big enough number and then taking only the fractional part creates a pseudo-random value.
    return fract(cos(h)*12345.6789);
}

/**
 * Create a coherent noise using the perline noise algorithm. Haskeys are
 * used to remove the need of an array of random values.
 * @return: noise value in the range[0.0, 1.0)
 */
float perlinNoise( in vec2 p )
{
    // see: http://webstaff.itn.liu.se/~stegu/TNM022-2005/perlinnoiselinks/perlin-noise-math-faq.html#whatsnoise
    vec2 i = floor(p); // Use hashing with this to fake a gridbased value noise.
    vec2 f = fract(p);
    
    // Using this 'ease curve' generates more visually pleasing noise then without.
    // Function describes a function similar to a smoothstep.
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix(hash(i + vec2(0.0,0.0)), 
                    hash(i + vec2(1.0,0.0)), u.x),
                mix(hash(i + vec2(0.0,1.0)), 
                    hash(i + vec2(1.0,1.0)), u.x), u.y);
}

/**
 * Performs a fractal sum of the same noise function for different 'frequencies'.
 * @return: noise value in the range [0.0, ~1.94)
 */
float fractalSumNoise(in vec2 p){
    float value = 0.0;
    
    float f = 1.0;
    
    // Experimentation yielded 5 itterations gave optimal results. Less itterations gave too
    // blotchy result, and more itterations did no longer have any significant visual impact.
    for (int i = 0; i < 10; i++){
        value += perlinNoise(p * f)/f;
        f = f * 2.0;
    }
    
    return value;
}

/**
 * Creates a hashkey based on a 3D variable.
 * Note: Using haskeys directly as noise function gives non-coherent noise.
 * @return: Haskey in range [0.0, 1.0)
 */
float hash3(in vec3 p){
    // Transform 3D parameter into a 1D value:
    // Note: higher value means 'higher frequency' when plugging uv coordinates.
    float h = dot(p, vec3(123.45, 678.91, 234.56));
    
    // Use a sinusoid function to create both positive and negative numbers.
    // Multiply by a big enough number and then taking only the fractional part creates a pseudo-random value.
    return fract(cos(h)*12345.6789);
}

/**
 * Create a coherent noise using the perline noise algorithm. Haskeys are
 * used to remove the need of an array of random values.
 * @return: noise value in the range[0.0, 1.0)
 */
float perlinNoise3( in vec3 p )
{
    // see: http://webstaff.itn.liu.se/~stegu/TNM022-2005/perlinnoiselinks/perlin-noise-math-faq.html#whatsnoise
    vec3 i = floor(p); // Use hashing with this to fake a gridbased value noise.
    vec3 f = fract(p);
    
    // Using this 'ease curve' generates more visually pleasing noise then without.
    // Function describes a function similar to a smoothstep.
    vec3 u = f*f*(3.0-2.0*f);

    float dx1 = mix(hash3(i + vec3(0.0,0.0,0.0)), 
                    hash3(i + vec3(1.0,0.0,0.0)), u.x);
    float dx2 = mix(hash3(i + vec3(0.0,1.0,0.0)), 
                    hash3(i + vec3(1.0,1.0,0.0)), u.x);
    float dy1 = mix(dx1, dx2, u.y);
    
    float dx3 = mix(hash3(i + vec3(0.0,0.0,1.0)), 
                    hash3(i + vec3(1.0,0.0,1.0)), u.x);
    float dx4 = mix(hash3(i + vec3(0.0,1.0,1.0)), 
                    hash3(i + vec3(1.0,1.0,1.0)), u.x);
    float dy2 = mix(dx3, dx4, u.y);
    
    return mix(dy1, dy2, u.z);
}

/**
 * Performs a fractal sum of the same noise function for different 'frequencies'.
 * @return: noise value in the range [0.0, ~1.94/2)
 */
float fractalSumNoise3(in vec3 p){
    float value = 0.0;
    
    float f = 1.0;
    
    // Experimentation yielded 5 itterations gave optimal results. Less itterations gave too
    // blotchy result, and more itterations did no longer have any significant visual impact.
    for (int i = 0; i < 5; i++){
        value += perlinNoise3(p * f)/f;
        f = f * 2.0;
    }
    
    return value/2.0;
}

float pattern( in vec3 p )
  {
      vec3 q = vec3( fractalSumNoise3( p + vec3(0.0,0.0,0.0)),
                     fractalSumNoise3( p + vec3(5.2,1.3,0.7)),
                     fractalSumNoise3( p + vec3(6.7,2.6,1.2)));

      return fractalSumNoise3( p + 4.0*q );
  }

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    // TODO: Add code to create your texture based on perline noise.
    // Some idea's:
    // * Start with visualizing the fractal sum and play around with the number of iterations and factors.
    // * Experiment with coloring the noise texture based on the noise value. (Use for example a spline: https://www.shadertoy.com/view/MdBXzG)
    // * Experiment using different coordinates in the perlinNoise function.
    // * Experiment with creating your own hash function.
    // * Experiment with creating a 3D animated noise texture.
    // * Experiment with using domain warping: http://www.iquilezles.org/www/articles/warp/warp.htm
    // * Experiment with combining raymarching and 3D solid texturing like in the marble example: https://www.shadertoy.com/view/ldjSz3
    
    glFragColor = vec4(pattern(vec3(5.0*uv,0.5+0.5*sin(0.3*time))),
                        pattern(vec3(5.0*uv,0.5+0.5*cos(0.3*time))),
                        pattern(vec3(0.5+0.5*sin(0.3*time),5.0*uv)),
                        1.0);
}
