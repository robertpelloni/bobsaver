#version 420

// original https://www.shadertoy.com/view/Wd3Gzj

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
#define Nat uint

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

Real H_inverse(Real r)
{
     return 1.0 / r;   
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

Real H_power(Real x, Real e)
{
    return pow(x, e);
}

Real H_power(Real x, Nat e)
{
    return pow(abs(x), float(e)) * ((e % 2u) == 0u ? 1.0 : sign(x));
}

Real H_sq(Real r)
{
    return r * r;
}

Real H_sin(Real r)
{
    return sin(r);
}

Real H_cos(Real r)
{
    return cos(r);
}

#define DualReal vec2

DualReal D_add(DualReal lhs, DualReal rhs)
{
    return lhs + rhs;
}

DualReal D_subtract(DualReal lhs, DualReal rhs)
{
    return lhs - rhs;
}

DualReal D_multiply(DualReal lhs, DualReal rhs)
{
    return DualReal(
        H_multiply(lhs[0], rhs[0]),
        H_add(H_multiply(lhs[1], rhs[0]), H_multiply(lhs[0], rhs[1])));
}

DualReal D_divide(DualReal lhs, DualReal rhs)
{
    return DualReal(
        H_divide(rhs[0], lhs[0]),
        H_divide(
            H_subtract(H_multiply(lhs[1], rhs[0]), H_multiply(lhs[0], rhs[1])),
            H_sq(rhs[0])));
}

DualReal D_power(DualReal d, Real exponent)
{
    return DualReal(
        H_power(d[0], exponent),
        H_multiply(exponent * H_power(d[0], exponent - 1.0), d[1]));
}

DualReal D_power(DualReal d, Nat exponent)
{
    return DualReal(
        H_power(d[0], exponent),
        H_multiply(float(exponent) * H_power(d[0], exponent - 1u), d[1]));
}

DualReal D_sq(DualReal d)
{
     return D_multiply(d, d);   
}

DualReal D_inverse(DualReal d)
{
    return DualReal(
        H_inverse(d[0]),
        H_multiply(H_negate(H_inverse(H_sq(d[0]))), d[1]));
}

DualReal D_sin(DualReal d)
{
     return DualReal(
        H_sin(d[0]), 
        H_multiply(d[1], H_cos(d[0])));   
}
                          
DualReal D_cos(DualReal d)
{
     return DualReal(
        H_cos(d[0]),
        H_multiply(H_negate(d[1]), H_sin(d[0])));   
}

#define DualVector2 mat2x2
#define DualVector3 mat3x2

//end Hypercomplex

DualReal f(int index, DualVector3 d)
{
    switch(index)
    {
        case 10:
        {
DualReal x = d[0];
            DualReal x2 = D_multiply(x, x);
            DualReal x3 = D_multiply(x, x2);
            DualReal x4 = D_multiply(x, x3);
            DualReal y = d[1];
            DualReal y2 = D_multiply(y, y);
            DualReal y3 = D_multiply(y, y2);
            DualReal y4 = D_multiply(y, y3);
            DualReal z = d[2];
            DualReal z2 = D_multiply(z, z);
            DualReal z3 = D_multiply(z, z2);
            DualReal z4 = D_multiply(z, z3);
            DualReal w = DualReal(1.5,0);
            DualReal w2 = D_multiply(w, w);
            DualReal w3 = D_multiply(w, w2);
            DualReal w4 = D_multiply(w, w3);
            
            Real ro = 0.5 * (1.0 + 2.2360679775);
            Real ro2 = ro * ro;
            Real ro3 = ro * ro2;
            Real ro4 = ro * ro3;
            
            DualReal t0 = 8.0 * (x2 - ro4 * y2);
            DualReal t1 = y2 - ro4 * z2;
            DualReal t2 = z2 - ro4 * x2;
            DualReal t3 = x4 + y4 + z4 - 2.0 * D_multiply(x2, y2) - 2.0 * D_multiply(x2, z2) - 2.0 * D_multiply(y2, z2);
            DualReal p0 = D_multiply(t0, D_multiply(t1, D_multiply(t2, t3)));
            DualReal t4 = (3.0 + 5.0 * ro) * D_sq(x2 + y2 + z2 - w2);
            DualReal t5 = D_multiply(D_sq(x2 + y2 + z2 - (2.0 - ro) * w2), w2);
            DualReal p1 = D_multiply(t4, t5);
            return p0 + p1;
            
        }
    }
}    

float getDE(int index, vec3 p, out vec3 gradient)
{
     DualReal dx = f(index, DualVector3(p.x, 1, p.y, 0, p.z, 0)); 
    DualReal dy = f(index, DualVector3(p.x, 0, p.y, 1, p.z, 0)); 
    DualReal dz = f(index, DualVector3(p.x, 0, p.y, 0, p.z, 1)); 
    
    float fp = dx[0];//level, same for all partials
    gradient = vec3(dx[1], dy[1], dz[1]);
    float de = fp / length(gradient);
    
    float bound = length(p) - 3.5;
    
    return max(abs(de), bound) * 0.5;//intersection
}

mat3 rotationXY(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(c, s, 0, -s, c, 0, 0, 0, 1);
}

mat3 rotationXZ(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

mat3 rotationYZ(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(1, 0, 0, 0, c, s, 0, -s, c);
}

void main(void)
{
    float aspectRatio = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 clip = uv * 2.0 - 1.0;
    vec2 unitSpacePosition = 0.5 * clip;
    vec2 ratioSpacePosition = vec2(aspectRatio, 1) * unitSpacePosition;
    
    //model
    float time = time * 0.15;
    int index = 10;
    
    //view basis
    float polar = 0.0; //(mouse*resolution.xy == vec4(0)) ? 0.0 : tau32 * mouse*resolution.xy.y / resolution.y + pi32;
    float az = time*tau32; //(mouse*resolution.xy == vec4(0)) ? time * tau32 : -tau32 * mouse*resolution.xy.x / resolution.x;
    mat3 viewTransform = rotationXZ(az) * rotationYZ(polar);
    vec3 viewPosition = viewTransform * vec3(0, 0, 7);
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

    //sphere trace
    int i;
    float t = 0.0;
    vec3 p;
    bool hit = false;
    vec3 gradient;
    
    for(i = 0; i < 300; i++)
    {
        p = srp + t * srd;
        
        float de = getDE(index, p, gradient);
        
        if(de < 0.0001)
        {
            hit = true;
            p -= 0.001 * srd;
            break; 
        }

        t += de;
    }
    
    if(hit)
    {
        vec3 color = vec3(1.0 - float(i) / 100.0) * 2.0;
        color *= normalize(gradient) * 0.8 + 0.2;
        glFragColor = vec4(color, 1);
    }
    else
    {
         glFragColor = vec4(vec3(0.2),1);   
    }
}
