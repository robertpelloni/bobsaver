#version 420

// original https://www.shadertoy.com/view/WscGRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Created by Skye Adaire

#define pi32 3.1415926535
#define tau32 6.2831853072
#define eps32 10e-15

float alpha(float x, float a, float b)
{
   return (x - a) / (b - a);
}

#define uclamp(x) clamp(x, 0.0, 1.0)
#define ualpha(x, a, b) uclamp(alpha(x, a, b))

//begin Hypercomplex

#define Real float

Real H_negate(Real r)
{
    return -r;
}

Real H_conjugate(Real r)
{
    return r;
}

Real H_norm(Real r)
{
    return abs(r);
}

Real H_sqnorm(Real r)
{
    return r * r;
}

Real H_add(Real lhs, Real rhs)
{
    return lhs + rhs;
}

Real H_subtract(Real lhs, Real rhs)
{
    return lhs - rhs;
}

Real H_multiply(Real lhs, Real rhs)
{
    return lhs * rhs;
}

Real H_divide(Real lhs, Real rhs)
{
    return lhs / rhs;
}

bool H_isZero(Real r)
{
    return H_norm(r) < eps32;
}

Real H_sq(Real r)
{
    return r * r;
}

#define Complex vec2

Complex H_negate(Complex h)
{
    return -h;
}

Complex H_conjugate(Complex h)
{
    return Complex(h[0], -h[1]);
}

Real H_sqnorm(Complex h)
{
    return dot(h, h);
}

Real H_norm(Complex h)
{
    return length(h);
}

Complex H_inverse(Complex h)
{
    return H_conjugate(h) / H_sqnorm(h);
}

Complex H_normalize(Complex h)
{
    return normalize(h);
}

Complex H_add(Complex lhs, Complex rhs)
{
    return lhs + rhs;
}

Complex H_subtract(Complex lhs, Complex rhs)
{
    return lhs - rhs;
}

Complex H_multiply(Complex lhs, Complex rhs)
{
    Real lhs_0 = lhs[0];
    Real lhs_1 = lhs[1];
    Real rhs_0 = rhs[0];
    Real rhs_1 = rhs[1];

    return Complex(
        H_subtract(H_multiply(lhs_0, rhs_0), H_multiply(H_conjugate(rhs_1), lhs_1)),
        H_add(H_multiply(rhs_1, lhs_0), H_multiply(lhs_1, H_conjugate(rhs_0))));
}

Complex H_divide(Complex lhs, Complex rhs)
{
    return H_multiply(lhs, H_conjugate(rhs)) / H_sqnorm(rhs);
}

bool H_isZero(Complex h)
{
    return H_norm(h) < eps32;
}

Real H_argument(Complex h)
{
   return atan(h[1], h[0]);//[-pi, pi]
}

Real H_argument2(Complex h)
{
    Real angle = H_argument(h);
    return angle < Real(0) ? angle + tau32 : angle;//[0, tau]
}

Complex H_versor(Real angle)
{
    return Complex(cos(angle), sin(angle));
}

struct PolarComplex
{
    float norm;
    float argument;
};

PolarComplex H_toPolar(Complex h)
{
    return PolarComplex(H_norm(h), H_argument(h));
}

Complex H_toCartesian(PolarComplex h)
{
    return h.norm * H_versor(h.argument);
}

PolarComplex H_power(PolarComplex polar, Real exponent)
{
    return PolarComplex(pow(polar.norm, exponent), polar.argument * exponent);
}

Complex H_power(Complex h, Real exponent)
{
    return H_toCartesian(H_power(H_toPolar(h), exponent));
}

Complex H_sq(Complex h)
{
    return H_multiply(h, h);
}

#define DualComplex mat2x2

DualComplex D_add(DualComplex lhs, DualComplex rhs)
{
    return lhs + rhs;
}

DualComplex D_subtract(DualComplex lhs, DualComplex rhs)
{
    return lhs - rhs;
}

DualComplex D_multiply(DualComplex lhs, DualComplex rhs)
{
    return DualComplex(
        H_multiply(rhs[0], lhs[0]),
        H_add(H_multiply(lhs[1], rhs[0]), H_multiply(lhs[0], rhs[1])));
}

DualComplex D_divide(DualComplex lhs, DualComplex rhs)
{
    return DualComplex(
        H_divide(rhs[0], lhs[0]),
        H_divide(
            H_subtract(H_multiply(lhs[1], rhs[0]), H_multiply(lhs[0], rhs[1])),
            H_sq(rhs[0])));
}

DualComplex D_power(DualComplex d, Real exponent)
{
    return DualComplex(
        H_power(d[0], exponent),
        H_multiply(exponent * H_power(d[0], exponent - 1.0), d[1]));
}

//end Hypercomplex

//https://www.shadertoy.com/view/lsS3Wc
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 getPlaneColor(Complex z)
{
    PolarComplex polar = H_toPolar(z);
    
    return hsv2rgb(vec3(polar.argument / tau32, 1, 1));
}

DualComplex f(DualComplex z)
{
    //return D_power(z, 3.0) - DualComplex(1, 0, 0, 0);
    //return D_power(z, 3.0) - 2.0 * z + DualComplex(2, 0, 0, 0);
    return 
        D_multiply(DualComplex(1.0, -2.0, 0, 0), D_power(z, 7.0)) +
        D_multiply(DualComplex(-10.0, 10.0, 0, 0), D_power(z, 6.0)) +
        D_multiply(DualComplex(-5.0, 2.0, 0, 0), D_power(z, 3.0)) + 
        D_multiply(DualComplex(-1.0, -6.0, 0, 0), D_power(z, 2.0)) + 
        DualComplex(100, -20,  0, 0);
}

Complex newton(Complex z, out float m)
{
    int i;
    m = 0.0;
    
     for(i = 0; i < 100; i++)
    {
        DualComplex d = DualComplex(z, 1, 0);
        DualComplex fz = f(d);
        
        Complex zt = z;
        z = z - H_divide(fz[0], fz[1]);
        
        if(H_norm(zt - z) < 0.0001) 
        {
            break;
        }
        
        //https://www.shadertoy.com/view/Md2yDG
        vec2 w = H_inverse(z - zt);
        m += exp(-length(w));
    }
    
    m = 1.0 - min(m / 20.0, 1.0);

    return z;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 clip = uv * 2.0 - 1.0;
       clip.x *= resolution.x / resolution.y;
    vec2 ss = clip * vec2(1.5);

    float i;
    vec3 color = getPlaneColor(newton(ss, i));
    color *= i;
    
    glFragColor = vec4(color, 1);
}
