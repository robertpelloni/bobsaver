#version 420

// original https://www.shadertoy.com/view/WlfyRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float remap(float oldMin, float oldMax, float newMin, float newMax, float value){
    return newMin + (value - oldMin) * (newMax - newMin) / (oldMax - oldMin);
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    uv += vec2( 0, remap( -1., 1., -.1, .1, sin(time * 3.) ) );
    
    float r = .8 * remap( -1., 1., 0.97, 1., sin(time * 9.) );
    float sr = .05;
    float d = abs( length( uv ) - r ) - 0.003;
    d = min(d, length(uv) - .05 * remap(-1., 1., 0.8, 1.1, cos(time*6.)) );
    
    float div = 16.;
    float TAU = 6.28318530718;
    float a = TAU / div;
    
    for ( float i = 0.; i < div; i++ ) {
        float rad = a * i + remap(-1.,1.,0.5,15.,sin(time));
        float radt = TAU - rad;
        vec2 pos = r * vec2( cos( rad ), sin( rad ) );
        vec2 post = r * vec2( cos( radt ), sin( radt ) );
        float srd = remap(-1., 1., 0.5, 1.7, sin( time * 5. + (i * .8 + 1.)) );
        float sd = length( uv - mix( pos, post, (sin(time) + 1.) * .5) ) - sr * srd;
        d = min( d, sd );
    }
    
    d = smoothstep( 0., 0.01, d );
    d = 1. - d;
    
    glFragColor = vec4( vec3( d ), 1 );
}
