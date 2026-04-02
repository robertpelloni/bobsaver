#version 420

// original https://www.shadertoy.com/view/XdfSWS

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

const float PI = 3.14159;
const float MAX_ITS = 10.0;
vec2 samples[4];

vec2 Zsqr(vec2 Z)
{
    //(a+ib)^2 = (a^2 - b^2) + i*(2ab)
    return vec2(Z.x*Z.x - Z.y*Z.y, 2.0*Z.x*Z.y);
}

vec2 Zmul(vec2 P, vec2 Q)
{
    //(a+ib)*(c+id) = (ac - bd) + i*(ad+bc)
    return vec2(P.x*Q.x - P.y*Q.y, P.x*Q.y + P.y*Q.x);
}

vec2 Zdiv(vec2 P, vec2 Q)
{
    //(a+ib)/(c+id) = ((ac + bd) + i*(bc-ad))/(c^2+d^2)
    return vec2(P.x*Q.x + P.y*Q.y, P.y*Q.x - P.x*Q.y)/(dot(Q,Q));
}

vec2 Zexp(vec2 Z)
{
    //e^(a+ib) = e^a*e^(ib) = e^a*cos(b) + i*e^a*sin(b)
    float etoa = exp(Z.x);
    return vec2(etoa*cos(Z.y), etoa*sin(Z.y));
}

void main(void)
{
    
    for(int i = 0; i < 4; i++)
    {
        vec2 offset = vec2(cos(float(i)/2.0*PI), sin(float(i)/2.0*PI))/1.5;
        
        //Get coordinates in the range [-1.0, 1.0]
        vec2 uv = (gl_FragCoord.xy+offset) / resolution.xy;
        vec2 aspect_uv = (uv - 0.5) * 2.0; 
        
        //Adjust for aspect ratio
        samples[i] = aspect_uv * (resolution.xy / resolution.y);
    }
    //Setup complex parameters for the Julia set
    //Here we animate C to give an interesting morphing effect
    vec2 A = 1.2*vec2(cos(time/17.0), sin(time/47.0));
    vec2 B = vec2(cos(0.667*PI+time/7.0), sin(0.667*PI+time/53.0));
    vec2 C = 0.8*vec2(cos(-0.667*PI+time/11.0), sin(-0.667*PI+time/23.0));
    vec2 D = vec2(0.0);    
    
    glFragColor = vec4(0.0);
    
    for(int i = 0; i < 4; i++)
    {
        vec2 Z = 1.3*(samples[i]);
        
        float iter = 0.0;
        vec4 orbit = vec4(1e30);
        bool exited = false;
        
        //Iterate through MAX_ITS iterations
        for(float n = 1.0; n <= MAX_ITS; n++)
        {
            //We are using Z_{n+1} = Z_n - F(Z_n)/F'(Z_n)
            //F : z -> z^3 - 1
            vec2 za = Z-A;
            vec2 zb = Z-B;
            vec2 zc = Z-C;
            vec2 zd = Z-D;
            vec2 F = Zmul(za, Zmul(zb, Zmul(zc, zd)));
            vec2 Fprime = Zmul(za, Zmul(zb, zc)) + 
                          Zmul(za, Zmul(zb, zd)) + 
                          Zmul(za, Zmul(zc, zd)) + 
                          Zmul(zb, Zmul(zc, zd));
            Z = Z - Zdiv(F, Fprime);
            float r = dot(Z,Z);
            //We are keeping track of the closest the point Z comes to:
            //  the origin
            //    the real axis
            //    the imaginary axis
            orbit = min(vec4(dot(Z-A,Z-A),
                             dot(Z-B,Z-B),
                             dot(Z-C,Z-C),
                             dot(Z-D,Z-D)), orbit);
            //We assume that if |Z_n| > 2.0 then Z_inf diverges
            if(r > 2.0)
            {
                iter = n;
                exited = true;
            }
        }
        
        //Plot those orbit trap calculations
        if (orbit.x < orbit.y && orbit.x < orbit.z && orbit.x < orbit.w)
        {
            glFragColor += vec4(exp(-orbit.x)*0.25, 0.0, 0.0, 1.0);
        }
        else if (orbit.y < orbit.x && orbit.y < orbit.z && orbit.y < orbit.w)
        {
            glFragColor += vec4(0.0, exp(-orbit.y)*0.25, 0.0, 1.0);
        }
        else if (orbit.z < orbit.x && orbit.z < orbit.y && orbit.z < orbit.w)
        {
            glFragColor += vec4(0.0, 0.0, exp(-orbit.w)*0.25, 1.0);
        }
        else
        {
            glFragColor += vec4(vec3(exp(-orbit.z)*0.25), 1.0);
        }
    }
}
