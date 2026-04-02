#version 420

// original https://www.shadertoy.com/view/ltcBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( vec2 p )
{
    float h = dot(p,vec2(127.1,311.7));    
    return -1.0 + 2.0*fract(sin(h)*43758.5453123);
}

float noise(vec2 p)
{
    vec2 cell = floor(p);
    
    float BottomLeft = hash(cell);
    float BottomRight = hash(cell + vec2(1.,0.));
    float TopLeft =  hash(cell + vec2(0.,1.));
    float TopRight = hash(cell + vec2(1.,1.));
    
    vec2 posLocal = fract(p);
    
    vec2 u = posLocal*posLocal*(3.0-2.*posLocal);
    
    float BottomLine = mix(BottomLeft,BottomRight,u.x);
    float TopLine = mix(TopLeft,TopRight,u.x);
    
    float CellInterpolationFinal = mix(BottomLine,TopLine,u.y);
    
    return CellInterpolationFinal;
}

float perlinNoise(vec2 p,float iteration)
{
    float outValue = 0.;
    
    for(float i = 0.0;i < iteration;i += 1. )
    {
        float freq = pow(2.,i);
        float Amp = 1. / freq;
        
        outValue += sin((noise(p * freq) * Amp));
    }
    return outValue;
}

vec2 Turbul(inout vec2 p,float freq,float amp)
{
    p.x += sin(time*5. + p.y * freq) * amp;
    p.y += sin(time*5. + p.x * freq) * amp;
    return p;
}

void rotate(inout vec2 p,float angle,vec2 rotationOrigin)
{
    p -= rotationOrigin;
    p *= mat2(cos(angle),-sin(angle),sin(angle),cos(angle));
    p += rotationOrigin;
}

vec4 fx(vec2 p)
{
    vec3 col = 0.5 + 0.5*cos(time+p.xyx+vec3(0,2,4));
    
    float noiseVal = 1.;
    float l = length(p*1.)*3.;
        
    rotate(p,l*l*l,vec2(0.,0.));
        
    p += perlinNoise(p * 2.,2.)*.1 * noiseVal;
    p -= perlinNoise(p * 4.,2.)*.05 * noiseVal;
    p += perlinNoise(p * 8.,2.)*.025 * noiseVal;
    p -= perlinNoise(p * 8.,2.)*.0125 * noiseVal;
    
    Turbul(p,20.,0.05 );
    Turbul(p,50.,0.0125 );
    
    float c = 1. - max( pow(length(p*5.),0.75)*1.,0.);
    c =  1. - abs((sin(time) * 0.5 + 0.5) - c)*1.;
    return vec4(c*col,1.0);
}

void main(void)
{    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    // Output to screen
    glFragColor = fx(uv)+fx(-uv*1.);
}
