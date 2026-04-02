#version 420

// original https://www.shadertoy.com/view/Xt2cWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = 3.1415;

//credit to IQ for these FBM & noise functions http://www.iquilezles.org/www/articles/warp/warp.htm
const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

float noise( in vec2 x )
{
    return sin(1.5*x.x)*sin(1.5*x.y);
}

float fbm6( vec2 p )
{
    float f = 0.0;
    f += 0.500000*(0.5+0.5*noise( p )); p = m*p*2.02;
    f += 0.250000*(0.5+0.5*noise( p )); p = m*p*2.03;
    f += 0.125000*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.062500*(0.5+0.5*noise( p )); p = m*p*2.04;
    f += 0.031250*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.015625*(0.5+0.5*noise( p ));
    return f/0.96875;
}

float pattern( in vec2 p )
{
    vec2 q = vec2( fbm6( p + vec2(0.0,0.0) ),
                  fbm6( p + vec2(5.2,1.3) ) );
    vec2 r = vec2( fbm6( p + 4.0*q + vec2(-1.2,9.2) ),
                  fbm6( p + 4.0*q + vec2(8.3,2.8) ) );
    return fbm6( p + 4.0*r + sin(time/3.));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    if(time<0.1){
        glFragColor = vec4(uv.xy, fbm6(uv), fbm6(uv.yx)); 
    } else {
        vec4 last = texture(backbuffer, uv);
        glFragColor = vec4(0.0);
        glFragColor.r += pattern(uv + mod(last.b, 8.)*vec2(sin(time/2.), cos(time/8.)));
        glFragColor.g += pattern(uv + mod(last.g, 7.)*vec2(sin(time/3.), cos(time/7.)));
        glFragColor.b += pattern(uv + mod(last.r, 4.)*vec2(sin(time/5.), cos(time)));
        glFragColor = mix(glFragColor, last, sin(glFragColor.r + glFragColor.g + glFragColor.b));
    }
}
