#version 420

// original https://www.shadertoy.com/view/4tGyWw

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
    uv = uv * (size + sin(time * 5. + size*2.) / 2.);

    // Number of sides of your shape
    float N = 4.;

    // Angle and radius from the current pixel
    float a = atan(uv.x,uv.y)+PI;
    float r = TWO_PI/float(N);
    
    // Spinning
    a += time*4.; //+ length(uv) * 4.;

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
    
    // Swerve;
    uv.x += sin(time*4. + length(uv) * 20.0)/10.;
    uv.y += cos(time*4. + length(uv) * 50.0)/10.;
    
    // Draw Circles
    vec4 color = vec4(1);
    float mod = 1.;
    for(float i = .1; i < 10.5; i+=.25)
    {
        mod *= -1.;
        color += circle(uv, i) * mod;
    }

    // Color It In
    vec3 col = 0.5 + 0.5*cos(time+vec3(0,2,4)+ length(uv)*4.);
    color.rgb -= mix(col, col-.1,color.r);
    
    // Inner Shadow
    color -= (1.0-length(uv))/2.;
    
    // Sepia
    //color.rgb = vec3(dot(color.rgb, vec3(0.299, 0.587, 0.114)));
    
    // Select Colors
    //vec3 col = vec3((sin(time + length(uv)) + 1.) / 4., (sin(time + length(uv)) + 1.) / 4., 1. + (sin(time)-1.)/4.);
    //color.rgb = mix(col.rgb/1.25, col.grb, color.r);
    //color.rgb -= (length(uv))/2.;
    
    
    glFragColor = color;
}
