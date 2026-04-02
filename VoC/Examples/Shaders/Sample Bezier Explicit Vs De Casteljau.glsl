#version 420

// original https://www.shadertoy.com/view/wllBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Comparing the numerical precision of explicit Bezier curve evaluation versus de Casteljau method.
//
// Top-Left = Using cached binomial coefficients (explained below)
// Top-Right = Cached binomial coefficients + efficient pow() evaluation
// Bottom-Left = Calculating factorials and running out of precision
// Bottom-Right = Paul de Casteljau's method: https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm

// Wikipedia states that the de Casteljau method is "a numerically stable method for evaluating the curves".
// This implies that the original formulation is not numerically stable. I think this is probably because
// the calculated factorials for curves of degree > 12 start to grow larger than what a 32-bit integer
// can hold, and larger than what is representable in a 32-bit float (24 bits of precision).
//
// However, these factorials are only calculated as part of the binomial coefficients which generally end up
// being easily representable in 24 bits. The set of binomial coefficients for a Bezier curve of a given
// degree is constant, so it can be pre-computed offline with a high precision and range.
//
// The result is that the original formulation of the Bezier curve evaluation is just as stable as
// de Casteljau's method at the scales that I've tried. On top of that, de Casteljau's method
// is very slow at high degrees O(n²) compared to the original formulation's O(n).
//

// Undefine this to use a more efficient way to compute the binomial coefficient.
// This is yet another way that the supposed precision loss in the original Bezier formulation
// can be avoided.
#define USE_FACTORIAL

// Degree of the Bezier curve
const int n = 13;

// Pre-computed binomial coefficients
const int bin13[14] = int[14](1, 13, 78, 286, 715, 1287, 1716, 1716, 1287, 715, 286, 78, 13, 1);

// Control points
vec2 control_points[n + 1];

int factorial(int x)
{
    // For values of n greater than around 12, the int datatype can't contain the result.
    int y = 1;
    while(x > 0)
    {
        y *= x;
        x -= 1;
    }
    return y;
}

float binomialCoefficient(int n, int k)
{
#ifdef USE_FACTORIAL
    // Naïve implementation using factorial.
    return float(factorial(n)) / float(factorial(k) * factorial(n - k));
#else
    // Using the multiplicative formula
    // https://en.wikipedia.org/wiki/Binomial_coefficient#Multiplicative_formula
    float c = 1.;
    for(int i = 1; i <= k; ++i)
        c *= float(n + 1 - i) / float(i);
    return c;
#endif
}

float binomialCached(int n, int k)
{
    // Use pre-computed tables to avoid overflow during calculation
    if(n == 13)
        return float(bin13[k]);
    
    return binomialCoefficient(n, k);
}

// The method which can be found on Wikipedia: https://en.wikipedia.org/wiki/B%C3%A9zier_curve
vec2 explicitBezier(float t)
{
    vec2 sum = vec2(0);
    for(int i = 0; i <= n; ++i)
    {
        sum += float(binomialCoefficient(n, i)) *
                pow(1. - t, float(n - i)) * pow(t, float(i)) * control_points[i];
    }
    return sum;
}

// Method using cached binomial coefficients to avoid overflow / precision loss.
vec2 explicitBezierCached(float t)
{
    vec2 sum = vec2(0);
    for(int i = 0; i <= n; ++i)
    {
        sum += float(binomialCached(n, i)) *
                pow(1. - t, float(n - i)) * pow(t, float(i)) * control_points[i];
    }
    return sum;
}

// Cached binomial coefficients, plus a reduced method of evaluating the polynomials.
vec2 explicitBezierCachedWithoutPow(float t)
{
    vec2 sum = vec2(0);
    float s = 1.0;
    for(int i = 0; i <= n; ++i)
    {
        sum *= t;
        sum += s*binomialCached(n,i)*control_points[n-i];
        s *= 1.0-t;
    }
    return sum;
}

vec2 deCasteljau(float t)
{
    vec2 mid_points[n];
    for(int i = 0; i < n; ++i)
    {
        mid_points[i] = mix(control_points[i], control_points[i + 1], t);
    }
    int k = n;
    while(k > 2)
    {
        k -= 1;
        for(int i = 0; i < k; ++i)
        {
            mid_points[i] = mix(mid_points[i], mid_points[i + 1], t);
        }
    }
    return mix(mid_points[0], mid_points[1], t);
}

float hash( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*43758.5453123);
}

// Distance to line segment
float segment(vec2 p, vec2 a, vec2 b)
{
    return distance(p, mix(a, b, clamp(dot(p - a, b - a) / dot(b - a, b - a), 0., 1.)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.xy * 2.;
    vec2 uv2 = (fract(uv) - .5) * 3.5;
    uv2.x *= resolution.x / resolution.y;

    // Generate control points
    for(int i = 0; i <= n; ++i)
    {
        control_points[i] = vec2(float(i) / float(n) * 2. - 1. + sin(float(i) * 2.3 - time / 2.) * .8,
                                 (hash(vec2(i, 8)) * 2. - 1.) * .4) * 1.5;
        control_points[i].y += sin(time / 3. + float(i) / 1.5);
    }
    
    vec4 col = vec4(0);

    col = vec4(.1 - .02 * smoothstep(0.02, 0.04, abs(fract(uv.x * resolution.x / resolution.y * 8.) - .5)) -
                       .02 * smoothstep(0.02, 0.04, abs(fract(uv.y * 8.) - .5)));
    
    col *= smoothstep(0.005, .01, min(abs(uv.y), abs(uv.x) * resolution.x / resolution.y));
    
    const int m = 64;
    
    float dist = 1e4;
    
    // Draw the Bezier curve
    
    vec2 prevp;
    for(int i = 0; i <= m; ++i)
    {
        float t = float(i) / float(m);
        vec2 p;
        
        if(uv.x < 0.)
        {
            if(uv.y < 0.)
            {
                p = explicitBezier(t);
            }
            else
            {
                p = explicitBezierCached(t);
            }
        }
        else
        {
            if(uv.y < 0.)
            {
                p = deCasteljau(t);
            }
            else
            {
                p = explicitBezierCachedWithoutPow(t);
            }
        }
        
        if(i > 0)
            dist = min(dist, segment(uv2, prevp, p));

        prevp = p;
    }
    
    col = mix(vec4(1, .2, .2, .2), col, smoothstep(.03, .04, dist));
    
    // Draw control points
    for(int i = 0; i <= n; ++i)
       col = mix(vec4(1), col, smoothstep(.02, .03, distance(uv2, control_points[i])));
    
    if(uv.x < 0.)
        col = col.argb;
    if(uv.y < 0.)
        col = col.barg;
    
    glFragColor = vec4(sqrt(col.rgb), 1.0);
}
