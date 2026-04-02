#version 420

// original https://www.shadertoy.com/view/WlG3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1416

const float waves = 10.;

float wave(float angle, vec2 point) {
  float cth = cos(angle);
  float sth = sin(angle);
  return (cos(cth*point.y - sth*point.x));
}

float triWrap(float v)
{
    return abs(mod(v+1.,2.)-1.);
}

float cosWrap(float v)
{
     return ((1.-cos(v*PI))/2.-0.2)*10./8.;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    uv = vec2(uv.x*resolution.x/resolution.y, uv.y);
    
    float aTime = -time*PI*0.005;
    float color = 0.;
    
    int option = 2;
    
    if(option == 1)
    {
        for(float i=0.; i<waves; i++)
        {
            color += 1.-abs(wave(aTime*pow(2.,i), uv*PI*10.));
        }
    }
    
    if(option == 2)
    {
        for(float i=0.; i<waves; i++)
        {
            color += 1.-abs(wave(aTime*(i+1.), uv*PI*10.));
        }
        
    }
    
    color = cosWrap(color);
    
    glFragColor = vec4(vec3(color), 1.);
}
