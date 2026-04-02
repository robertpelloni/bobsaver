#version 420

// original https://www.shadertoy.com/view/4tXBWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi  3.14159
#define tau 6.28318
#define t time

#define p0 0.5, 0.5, 0.5,  0.5, 0.5, 0.5,  1.0, 1.0, 1.0,  0.0, 0.33, 0.67    
    
// source: http://iquilezles.org/www/articles/palettes/palettes.htm
// cosine based palette, 4 vec3 params
vec3 palette( in float t, in float a0, in float a1, in float a2, in float b0, in float b1, in float b2,
              in float c0, in float c1, in float c2,in float d0, in float d1, in float d2)
{
    return vec3(a0,a1,a2) + vec3(b0,b1,b2)*cos( tau*(vec3(c0,c1,c2)*t+vec3(d0,d1,d2)) );
}

const float epsilon = .0001;

vec3 rotateZ(vec3 p, float rads) {
    return mat3(vec3(cos(rads), sin(rads), 0.), vec3(-sin(rads), cos(rads), 0.), vec3(0., 0., 1.)) * p;
}

// IQ distance functions
float roundBoxSDF(vec3 p, vec3 size, float r)
{
    return length(max(abs(p) - size, 0.0))-r;
}

float opRep(vec3 p, vec3 c)
{
    vec3 q = mod(p, c) - .5 * c;
    return roundBoxSDF(q, vec3(.15), .1);
}

float sceneSDF(vec3 p)
{
    return opRep(p, vec3(1.));
}

vec3 gradient(vec3 p)
{
    vec3 dx = vec3(epsilon, 0., 0.);
    vec3 dy = vec3(0., epsilon, 0.);
    vec3 dz = vec3(0., 0., epsilon);
    return normalize(vec3(
        sceneSDF(p + dx) - sceneSDF(p - dx),
        sceneSDF(p + dy) - sceneSDF(p - dy),
        sceneSDF(p + dz) - sceneSDF(p - dz)
    ));
}

vec3 phong(vec3 p, vec3 eye, vec3[1] lights, vec3 color)
{
    const vec3 specularColor = vec3(1.);
    const float ambientStrength = .5;
    
    vec3 norm = gradient(p);
    vec3 col = vec3(0.);
    vec3 view = normalize(eye - p);
    
    for (int i = 0; i < lights.length(); i++)
    {
        float kd = dot(lights[i], norm);
        vec3 reflection = reflect(normalize(p - lights[i]), norm);
        float ks = pow(max(dot(view, reflection), 0.), 16.);
        
        col += color * kd + ks * specularColor;
    }
    
    return col + color * ambientStrength;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    glFragColor = vec4(0.);
    vec3 ray = normalize(vec3(uv, -1.));
    vec3 eye = vec3(sin(time), sin(time), -time * 3.);
    vec3[1] lights;
    lights[0] = vec3(1., 2., 5.);
    
    vec3 pos = eye;
    
    float dist = 0.;
    for (float i = 0.; i < 70.; i++)
    {
        dist = sceneSDF(rotateZ(pos, time));
        pos += ray * dist;
    }
    
    if (dist < epsilon) {
        pos = rotateZ(pos, time);
        float colorIndex = floor(pos.x) + floor(pos.y) + floor(pos.z);
        colorIndex *= .2;
        colorIndex += time;
        
        // https://www.shadertoy.com/view/MdXGDr
        float fogFact = clamp(exp(-distance(eye, pos) * 0.3), 0.0, 1.0);
        
        glFragColor.rgb = fogFact * phong(pos, eye, lights, .5 * palette(colorIndex, p0));
    }
}
