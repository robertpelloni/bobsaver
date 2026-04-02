#version 420

// original https://www.shadertoy.com/view/Ws3GWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Created by Skye Adaire

#define pi32 3.1415926535
#define tau32 6.2831853072
#define eps32 10e-15

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

//end Hypercomplex

//column-major and complex-valued 
#define ComplexVector2 mat2x2
#define ComplexMatrix2 mat4x2

ComplexMatrix2 identityMob = ComplexMatrix2(1,0, 0,0, 0,0, 1,0); 

//inverse of mobius transform with det 1
ComplexMatrix2 M_inverse(ComplexMatrix2 m)
{
    return ComplexMatrix2(m[3], -m[1], -m[2], m[0]); 
}

ComplexMatrix2 M_multiply(ComplexMatrix2 lhs, ComplexMatrix2 rhs)
{
    return ComplexMatrix2(
        H_multiply(lhs[0], rhs[0]) + H_multiply(lhs[2], rhs[1]),
        H_multiply(lhs[1], rhs[0]) + H_multiply(lhs[3], rhs[1]),
        H_multiply(lhs[0], rhs[2]) + H_multiply(lhs[2], rhs[3]),
        H_multiply(lhs[1], rhs[2]) + H_multiply(lhs[3], rhs[3]));
}

//complex-valued homogeneous transform
Complex M_multiply(ComplexMatrix2 m, Complex z)
{    
    return H_divide(H_multiply(m[0], z) + m[2], H_multiply(m[1], z) + m[3]);
}

//returns the mob mapping z0 -> 0, z1 -> 1, z2 -> inf
ComplexMatrix2 M_mapTripleTo01I(Complex z0, Complex z1, Complex z2)
{
    return ComplexMatrix2(
        z0 - z2,
        z0 - z1,
        H_multiply(-z1, z0 - z2),
        H_multiply(-z2, z0 - z1));
}
 
//uses the cross ratio to construct the mob taking the ordered triple a,b,c -> p,q,r
ComplexMatrix2 M_mapTripleToTriple(
    Complex a, Complex b, Complex c, 
    Complex p, Complex q, Complex r)
{
    return M_multiply(M_inverse(M_mapTripleTo01I(p, q, r)), M_mapTripleTo01I(a, b, c));
}

//mob taking  [-1, 0, 1] to [L, c, R]
ComplexMatrix2 M_mapRealsToLine(Complex L, Complex c, Complex R)
{
    return M_mapTripleToTriple(
        Complex(-1, 0), Complex(0, 0), Complex(1, 0),
        L, c, R);
}

//the euclidean rotation of the plane is an isometry of the disk
ComplexMatrix2 M_rotation(Real a)
{
    return ComplexMatrix2(H_versor(0.5 * a), Complex(0, 0), Complex(0, 0), H_versor(-0.5 * a));
}

ComplexMatrix2 M_translateReals(Real t)
{
    Real ex = exp(t);
    Complex exp1 = Complex(ex + 1.0, 0);
    Complex exm1 = Complex(ex - 1.0, 0);
    
    return ComplexMatrix2(exp1, exm1, exm1, exp1);
}

ComplexMatrix2 M_translateDisk(vec2 v)
{
    PolarComplex p = H_toPolar(v);
    ComplexMatrix2 r = M_rotation(p.argument);
    return M_multiply(r, M_multiply(M_translateReals(p.norm), M_inverse(r)));
}

struct Circle
{
     Complex center;
    Real radius;
};

Circle M_getCircleBetweenDiskPoints(Complex p, Complex q)
{
    Real dp = H_sqnorm(p) + 1.0;
    Real dq = H_sqnorm(q) + 1.0;
    Real dpq = 2.0 * (p[0] * q[1] - p[1] * q[0]);
    Complex center = Complex(q[1] * dp - p[1] * dq, -q[0] * dp + p[0] * dq) / dpq;

    return Circle(center, sqrt(H_sqnorm(center) - 1.0));
}

//return the first positive solution along the ray
bool solveQuadraticIntersection(float a, float b, float c, out float t)
{
    if(abs(a) < eps32)
    {
        t = -c / b;
        return t > 0.0;
    }

    float discriminant = b * b - 4.0 * a * c;

    if(abs(discriminant) < eps32)
    {
        t = - b / (2.0 * a);
        return true;
    }
    else if(discriminant < 0.0)
    {
        return false;
    }
    else
    {
        float sqrtd = sqrt(discriminant);

        float t0 = (-b + sqrtd) / (2.0 * a);
        float t1 = (-b - sqrtd) / (2.0 * a);

        if(t1 < t0)
        {
            float tt = t0;
            t0 = t1;
            t1 = tt;
        }

        if(t0 > 0.0)
        {
            t = t0;
            return true;
        }

        if(t1 > 0.0)
        {
            t = t1;
            return true;
        }

        return false;
    }
}

bool intersectHypersphere(
    vec2 rayPosition,
    vec2 rayDirection,
    vec2 center,
    float radius,
    out float t)
{
    float a = dot(rayDirection, rayDirection);
    float b = 2.0 * (dot(rayDirection, rayPosition) - dot(rayDirection, center));
    float c = dot(rayPosition, rayPosition) - 2.0 * dot(rayPosition, center) + dot(center, center) - H_sq(radius);

    return solveQuadraticIntersection(a, b, c, t);
}

ComplexMatrix2 M_getIdealLine(Complex i0, Complex i1)
{
     Circle c = M_getCircleBetweenDiskPoints(i0, i1);
    vec2 d = normalize(c.center);
    
    float t;
    intersectHypersphere(vec2(0), d, c.center, c.radius, t);
    
    return M_mapRealsToLine(i0, t * d, i1);
}

Complex M_fromPlaneToDisk(Complex z)
{
   return Complex(2.0 * z.x, H_sqnorm(z) - 1.0) / (H_sq(z.x) + (1.0 + z.y) * (1.0 + z.y));
}

//a tile is constructed from half planes
//the union of these half planes is the fundamental domain
//we reflect the point about half planes until it is in the domain
vec2 getPoincareTiling(
    ComplexMatrix2 transformFromA, ComplexMatrix2 transformToA, 
    ComplexMatrix2 transformFromB, ComplexMatrix2 transformToB, 
    ComplexMatrix2 transformFromC, ComplexMatrix2 transformToC, 
    vec2 z, out vec3 d, out int i)
{
   for(i = 0; i < 60; i++)
   {
      vec2 t;
       
      t = M_multiply(transformToA, z);

      d[0] = abs(t.y);

      if(t.y < 0.0)
      {
         t = H_conjugate(t);
         z = M_multiply(transformFromA, t);
         continue;
      }
       
      t = M_multiply(transformToB, z);

      d[1] = abs(t.y);

      if(t.y < 0.0)
      {
         t = H_conjugate(t);
         z = M_multiply(transformFromB, t);
         continue;
      }
       
      t = M_multiply(transformToC, z);

      d[2] = abs(t.y);

      if(t.y < 0.0)
      {
         t = H_conjugate(t);
         z = M_multiply(transformFromC, t);
         continue;
      }

      //the point is in the fundamental domain
      break;
   }

   return z;
}

Real P_length(Complex p)
{
    float n = length(p);
     return log((1.0 + n) / (1.0 - n));
}

//https://www.shadertoy.com/view/lsS3Wc
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 clip = uv * 2.0 - 1.0;
       clip.x *= resolution.x / resolution.y;
    vec2 p = (clip + vec2(0, 1)) * 2.0;
    
    vec2 z = M_fromPlaneToDisk(p);
    
    //translation vector, input or default
    float time = 0.4 * time;
    vec2 mouse = -(mouse*resolution.xy.xy / resolution.xy - 0.5) * 5.0;
    vec2 def = 4.0 * vec2(0.2*cos(0.05*time), sin(0.3*time));                      
    vec2 v = def;

    //this transform moves us around 
    //transformation could also be done by complex matrix composition, just like view matrices in R3
    //since this is a fully proceedural shader, I recompute the translation each frame
    ComplexMatrix2 translation = M_translateDisk(v);
    z = M_multiply(translation, z);

    //these transforms comprise the fundamental domain of the tiling
    ComplexMatrix2 transformFromA = identityMob;
    ComplexMatrix2 transformToA = M_inverse(transformFromA);

    float angleB = tau32 / 16.0;
    Complex versorB = H_versor(angleB);
    ComplexMatrix2 transformFromB = M_mapRealsToLine(versorB, Complex(0,0), -versorB);
    ComplexMatrix2 transformToB = M_inverse(transformFromB);

    ComplexMatrix2 transformFromC = M_getIdealLine(H_versor(-0.872), H_versor(0.872));
    ComplexMatrix2 transformToC = M_inverse(transformFromC);

    vec3 distances;
    int i;
    z = getPoincareTiling(
        transformFromA, transformToA,
        transformFromB, transformToB,
        transformFromC, transformToC,
        z, distances, i);

    float edge = 0.755;
    float d = P_length(z);
    float s = 1.0 - smoothstep(edge, edge + 0.02, d);
    vec3 color = hsv2rgb(vec3(d * 0.25 + 0.5, 1, 1));
    
    color = mix(vec3(0.1), color, s);
    
    //if(length(p) > 1.0) color = 1.0 - color;
    glFragColor = vec4(color,1.0);
}
