#version 420

// original https://www.shadertoy.com/view/WdcGzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//created by Skye Adaire

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

#define Quaternion vec4

Quaternion H_negate(Quaternion h)
{
    return -h;
}

Quaternion H_conjugate(Quaternion h)
{
    return Quaternion(h[0], -h[1], -h[2], -h[3]);
}

Real H_sqnorm(Quaternion h)
{
    return dot(h, h);
}

Real H_norm(Quaternion h)
{
    return length(h);
}

Quaternion H_inverse(Quaternion h)
{
    return H_conjugate(h) / H_sqnorm(h);
}

Quaternion H_normalize(Quaternion h)
{
    return normalize(h);
}

Quaternion H_add(Quaternion lhs, Quaternion rhs)
{
    return lhs + rhs;
}

Quaternion H_subtract(Quaternion lhs, Quaternion rhs)
{
    return lhs - rhs;
}

Quaternion H_multiply(Quaternion lhs, Quaternion rhs)
{
    Complex lhs_0 = Complex(lhs[0], lhs[1]);
    Complex lhs_1 = Complex(lhs[2], lhs[3]);
    Complex rhs_0 = Complex(rhs[0], rhs[1]);
    Complex rhs_1 = Complex(rhs[2], rhs[3]);

    return Quaternion(
        H_subtract(H_multiply(lhs_0, rhs_0), H_multiply(H_conjugate(rhs_1), lhs_1)),
        H_add(H_multiply(rhs_1, lhs_0), H_multiply(lhs_1, H_conjugate(rhs_0))));
}

Quaternion H_divide(Quaternion lhs, Quaternion rhs)
{
    return H_multiply(lhs, H_conjugate(rhs)) / H_sqnorm(rhs);
}

bool H_isZero(Quaternion h)
{
    return H_norm(h) < eps32;
}

struct PolarQuaternion
{
    Real norm;
    Real angle;
    vec3 axis;//normalized
};

PolarQuaternion H_toPolar(Quaternion h)
{
    PolarQuaternion result;
    Real vectorLength2 = dot(h.yzw, h.yzw);

    if(H_isZero(vectorLength2))
    {
        result.axis = vec3(0);
    }
    else//normalize the vector part
    {
        result.axis = h.yzw / sqrt(vectorLength2);
    }

    result.norm = sqrt(H_sq(h[0]) + vectorLength2);

    if(H_isZero(result.norm))
    {
        result.angle = 0.0;
    }
    else
    {
        result.angle = acos(h[0] / result.norm);
    }

    return result;
}

Quaternion H_toCartesian(PolarQuaternion p)
{
    return p.norm * Quaternion(cos(p.angle), sin(p.angle) * p.axis);
}

Quaternion H_versor(Real angle, vec3 axis)
{
    return H_toCartesian(PolarQuaternion(1.0, angle / 2.0, axis));
}

PolarQuaternion H_power(PolarQuaternion polar, Real exponent)
{
    polar.norm = pow(polar.norm, exponent);
    polar.angle = polar.angle * exponent;
    return polar;
}

Quaternion H_power(Quaternion h, Real exponent)
{
    if(H_isZero(exponent))
    {
        return Quaternion(1,0,0,0);
    }
    else
    {
        return H_toCartesian(H_power(H_toPolar(h), exponent));
    }
}

Quaternion H_sq(Quaternion h)
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

#define DualQuaternion mat2x4

DualQuaternion D_add(DualQuaternion lhs, DualQuaternion rhs)
{
    return lhs + rhs;
}

DualQuaternion D_subtract(DualQuaternion lhs, DualQuaternion rhs)
{
    return lhs - rhs;
}

DualQuaternion D_multiply(DualQuaternion lhs, DualQuaternion rhs)
{
    return DualQuaternion(
        H_multiply(rhs[0], lhs[0]),
        H_add(H_multiply(lhs[1], rhs[0]), H_multiply(lhs[0], rhs[1])));
}

DualQuaternion D_divide(DualQuaternion lhs, DualQuaternion rhs)
{
    return DualQuaternion(
        H_divide(rhs[0], lhs[0]),
        H_divide(
            H_subtract(H_multiply(lhs[1], rhs[0]), H_multiply(lhs[0], rhs[1])),
            H_sq(rhs[0])));
}

DualQuaternion D_power(DualQuaternion d, Real exponent)
{
    return DualQuaternion(
        H_power(d[0], exponent),
        H_multiply(exponent * H_power(d[0], exponent - 1.0), d[1]));
}

//end Hypercomplex

mat3 rotation3XZ(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

//https://www.shadertoy.com/view/lsS3Wc
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

float getJuliaDE(DualQuaternion dd, vec3 inPosition, out vec3 outNormal, out int i)
{
    Quaternion c = Quaternion(inPosition, 0);

    //directional derivatives
    DualQuaternion dx = DualQuaternion(c, Quaternion(1,0,0,0));
    DualQuaternion dy = DualQuaternion(c, Quaternion(0,1,0,0));
    DualQuaternion dz = DualQuaternion(c, Quaternion(0,0,1,0));

    for(i = 0; i <= 7; i++)
    {
        if(H_sqnorm(dx[0]) > 16.0)
        {
            break;
        }

        dx = D_add(D_multiply(dx, dx), dd);
        dy = D_add(D_multiply(dy, dy), dd);
        dz = D_add(D_multiply(dz, dz), dd);
    }

    //the final position is the same for all partials
    vec3 fp = dx[0].xyz;
    float r = H_norm(dx[0]);
    
    float dr = length(vec3(H_norm(dx[1]), H_norm(dy[1]), H_norm(dz[1])));
    outNormal = normalize(vec3(dot(fp, dx[1].xyz), dot(fp, dy[1].xyz), dot(fp, dz[1].xyz)));

      return 0.5 * log(r) * r / dr;//better for low iteration counts
    //return 0.5 * r / dr;
}

void main(void)
{
    float aspectRatio = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 clip = uv * 2.0 - 1.0;
    vec2 unitSpacePosition = 0.5 * clip;
    vec2 ratioSpacePosition = vec2(aspectRatio, 1) * unitSpacePosition;
    
    //view basis
    mat3 viewTransform = rotation3XZ(time * 0.1);
    vec3 viewPosition = viewTransform * vec3(0, 0, 2);
    vec3 viewRight = viewTransform * vec3(1, 0, 0);
    vec3 viewUp = viewTransform * vec3(0, 1, 0);
    vec3 viewForward = viewTransform * vec3(0, 0, -1);
    
    //view ray
    vec3 frustumPoint = viewPosition - viewForward;
    vec3 srp =
       viewPosition +
       viewRight * ratioSpacePosition.x +
       viewUp * ratioSpacePosition.y;
    vec3 srd = normalize(srp - frustumPoint);
    
    //julia constant
    float time = 0.2 * time;
    float ct = cos(time);
    float st = sin(time);
    Quaternion d = Quaternion(0, ct * 1.1, 0, 0);
    DualQuaternion dd = DualQuaternion(d, Quaternion(0));

    //ray march the distance field
    int i;
    float t = 0.0;
    vec3 p;
    bool hit = false;
    
    //last julia outputs
    int iEscape;
    vec3 globalNormal;
    
    for(i = 0; i < 150; i++)
    {
        p = srp + t * srd;
        
        float de = getJuliaDE(dd, p, globalNormal, iEscape);
        
        if(abs(de) < (0.0001 * t))
        {
            hit = true;
            p -= 0.001 * srd;
            break; 
        }

        t += de;
    }
    
    //color the intersection
    vec4 color = vec4(0);
    
    if(hit)
    {
        float escape = 0.7 * float(iEscape) / float(20) + 0.2;
        vec3 surfaceColor = mix(abs(globalNormal), hsv2rgb(vec3(escape, 1, 1)), 0.0);

        vec3 bottomLightDirection = normalize(vec3(-1,-1,-1));
        vec3 bottomLight = 1.0 * clamp(dot(globalNormal, bottomLightDirection), 0.0, 1.0) * vec3(1, 1, 1);
        color += vec4(bottomLight * surfaceColor, 1);

        vec3 spotLight1Position = vec3(10);
        vec3 spotLight1Color = 2.0 * vec3(1, 1, 1);
        vec3 spotLight1Direction = normalize(spotLight1Position - p);
        float spotLight1Incidence = clamp(dot(globalNormal, spotLight1Direction), 0.0, 1.0);
        float spotLight1Blocked = 1.0;
        vec3 spotLight = spotLight1Blocked * spotLight1Incidence * spotLight1Color;
        color += vec4(spotLight * surfaceColor, 1);
    }
    
    color = pow(color, vec4(0.4545));
    
    glFragColor = vec4(color);
}
