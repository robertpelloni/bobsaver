#version 420

//synthetic aperture, aka beamforming

//cribbed from this : https://www.shadertoy.com/view/ldlSzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D renderbuffer;

out vec4 glFragColor;

#define EMITTERS         17
#define SCALE            128.
#define WAVELENGTH        .5
#define VELOCITY        5.
#define CONFIGURATION        1.//floor(mod(time/8., 2.))
#define AMPLITUDE        2.
#define RADIUS            128.
#define TAU             (8.*atan(1.))

mat2 rmat(float t)
{
    float c = cos(t);
    float s = sin(t);
    
    return mat2(c, s, -s ,c);
}

float wave(float x)
{
    bool p  = fract(x*.5)<.5;
    x    = fract(x)*2.;
    x     *= 2.-x;
    x     *= 1.-abs(1.-x)*.25;
    return  p ? x : -x;
}

float cube(vec2 position, vec2 scale)
{
    position.xy    *= rmat(time*1.);
    vec2 vertex     = abs(position) - scale;
    vec2 edge     = max(vertex, 0.);
    float interior    = max(vertex.x, vertex.y);
    return min(interior, 0.) + length(edge);
}

void main( void ) 
{
    float scale        = SCALE;
    vec2 aspect        = resolution/min(resolution.x, resolution.y);
    vec2 uv            = gl_FragCoord.xy/resolution;
    vec2 position        = (uv * 2. - 1.) * aspect * scale;
    vec2 mouse        = (mouse * 2. - 1.) * aspect * scale;

    
    vec2 target        = mouse;
    
    float wavelength     = WAVELENGTH;
    float velocity        = VELOCITY;
    float radius        = RADIUS;
    
    float total        = 0.;
    float travel        = 1.1;
    float energy        = 0.;
    vec3 direction         = normalize(vec3(position.xy, 1.5));
    for(int j = 0; j < 17; j++)
    {
        for(int i = 0; i < EMITTERS; i++)
        {
            float interval    = float(EMITTERS-i)/float(EMITTERS);
        
            vec2 source     = vec2(0.);
            source         = CONFIGURATION == 0. ? vec2((interval*radius/4.-radius/8.)*2., -scale*.75)     : source;        
            source         = CONFIGURATION == 1. ? vec2(radius, 0.) * rmat(TAU * interval)             : source;
            source        -= direction.xy * travel;
            float theta      = distance(source, position);    
            float range     = cube(source-target, vec2(24.));

        
                float shift      = theta - velocity * time;
            float phase     = wave(1. * wavelength * (shift - range));
            float amplitude     = pow(theta, .25*sqrt(abs(theta-range)))*AMPLITUDE;
    
            energy         += phase/amplitude;
        }

        position     += direction.xy*travel;
        radius        *= travel;
        total         += abs(energy/8.);
        energy         = 0.;

    }
    energy = total;
    vec4 result    = vec4(0.);
    result.x        = energy;
    result.z        = 1.-energy;
    result         *= abs(energy)/.2;
    result.w        = 1.;
    
    glFragColor    = result;
}//sphinx
