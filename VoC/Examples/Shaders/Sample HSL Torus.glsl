#version 420

// original https://www.shadertoy.com/view/4tsfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.1415926535897932384626433832795;
const float M_120Deg = pi*2.0/3.0;
const float M_240Deg = M_120Deg*2.0;

vec3 hsl2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.) -3. ) -1., 0.,1.);
    return c.z + c.y * (rgb-.5)*(1.-abs(2.*c.z-1.));
}

void main(void)
{
    vec2 translated = 2.0*(gl_FragCoord.xy - resolution.xy/2.0);
    translated /= ( resolution.x<resolution.y ? resolution.x : resolution.y );
    
    float dist = length( translated );
    float innerRadius = sin(time)/6.0+0.3;
    
    vec3 hsl = vec3( time/3.0 + atan( translated.x, translated.y )/(pi*2.0), 1.0, (dist>innerRadius?0.5-(dist-innerRadius)/(2.0*innerRadius):dist/(innerRadius*2.0)));
    glFragColor = vec4( hsl2rgb( hsl ), 1.0 );
}
