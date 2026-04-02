#version 420

// original https://www.shadertoy.com/view/ltKcDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

vec4 circle(vec2 uv, float size)
{
    float d = 0.0;
    
    // Squish
    uv = uv * (size + sin(time * 5. + size*10.) / 5.);

    // Number of sides of your shape
    int N = 4;

    // Angle and radius from the current pixel
    float a = atan(uv.x,uv.y)+PI;
    float r = TWO_PI/float(N);
    
    // Spinning
    a += time*4. + length(uv) * 10.;

    // Shaping function that modulate the distance
    d = cos(floor(.5+a/r)*r-a)*length(uv);
    
    vec3 color = vec3(1.0-smoothstep(.4,.5,d));

    return vec4(color,1.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv.x *= resolution.x/resolution.y;
    
    // Center Coords
    uv.x -= resolution.x/resolution.y * .5;
    uv.y -= .5;
    
    vec4 color = vec4(1);
    float mod = 1.;
    for(float i = .5; i < 10.; i+=.5)
    {
        mod *= -1.;
        color += circle(uv, i) * mod;
    }

    vec3 col = 0.5 + 0.5*cos(time+vec3(0,2,4)+ length(uv)*4.);
    color.rgb += mix(col, col*-1., color.r);
    
    glFragColor = color;
}
