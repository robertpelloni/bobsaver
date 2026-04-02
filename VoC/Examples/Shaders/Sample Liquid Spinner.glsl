#version 420

// original https://www.shadertoy.com/view/4tlfDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;
const float tau = 6.28318; 
const float epsilon = .0001;

vec3 translate(vec3 p, vec3 amount) 
{
    return p - amount;
}

float sphereSDF(vec3 p, float size)
{
    return length(p) - size;
}

// iq's smooth min
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float mergeSDF(float d1, float d2, float k)
{
    return smin(d1, d2, k);
}

float sceneSDF(vec3 p)
{
    const float secondsPerCycle = 1.5;
    const float secondsBetweenBalls = .06;
    const float radius = 3.85;
    float res = 2.;
    
    vec3 pos = p;
    
    for (float i = 0.; i < 5.; i++) {
        float x = i * secondsBetweenBalls + time / secondsPerCycle;
        float angle = tau * x + pi / 6. - 4./ tau * sin(tau * x);
        pos = translate(p, vec3(sin(angle) * radius, cos(angle) * radius, 0.));
        res = mergeSDF(res, sphereSDF(pos, .4), 1.2);
    }
    return res;
}

vec3 gradient(vec3 p)
{
    const vec3 dx = vec3(epsilon, 0., 0.);
    const vec3 dy = vec3(0., epsilon, 0.);
    const vec3 dz = vec3(0., 0., epsilon);
    
    return normalize(vec3(
        sceneSDF(p + dx) - sceneSDF(p - dx),
        sceneSDF(p + dy) - sceneSDF(p - dy),
        sceneSDF(p + dz) - sceneSDF( p - dz)
    ));
}

vec3 phong(vec3 p, vec3 view, vec3 light)
{
    const vec3 diffuseColor = vec3(1., .5, 0.);
    const vec3 specularColor = vec3(1., 1., 1.) ;
    const vec3 ambientColor = vec3(1., .5, 0.);
    const float ambientStrength = .5;
    const float glossiness = 16.;
    
    vec3 normal = gradient(p);
    vec3 diffuse = max(0., dot(normal, light)) * diffuseColor;
    vec3 specular = pow(max(0., dot(view, reflect(-light, normal))), glossiness) * specularColor;
    vec3 ambient = ambientStrength * ambientColor;
    
    return diffuse + specular + ambient;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 eye = vec3(0., 0., 5.);
    vec3 light = vec3(0., 2., 2.);
    vec3 dir = normalize(vec3(uv, -1.));
    
    // march
    vec3 pos = eye;
    float dist = 0.;
    for (int i = 0; i < 70; i++) 
    {
        dist = sceneSDF(pos);
        pos += dist * dir;
    }
    
    glFragColor = vec4(0.);
    
    if (dist < epsilon)
    {
        glFragColor.rgb = phong(pos, normalize(eye - pos), normalize(light - pos));
    }
}
