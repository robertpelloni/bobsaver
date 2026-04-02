#version 420

// original https://www.shadertoy.com/view/wtyBzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float phase_offset = 1.618;
float amplitude_scale = 0.3;
float signal_offset = 0.6;

int accum = 0;

float f( float x )
{
 return amplitude_scale * sin(x + time + phase_offset) + signal_offset;
}

float f2( float x )
{
 return amplitude_scale * 0.618 * sin(x + time + phase_offset * 1.618) + signal_offset + 0.75;
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(0.5);
    uv *= 5.; // -1 to 1, then scaled from there

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    col = vec3(0.2*dot(col,col)); // grayscale

    float result;

      
    
    for(float c = 0.1; c < 97.5; c += c)
    {
        amplitude_scale = 0.1 * sin(c + time) + 0.6;
        signal_offset = cos(c + 0.08 * time) * 0.2;
        phase_offset = sin(c + time) + 0.02 * time + c;
        
        if((result = smoothstep(0., 0.35 + 0.1 * sin(c), abs(uv.x - f(uv.y)))) < 0.01)
        {
            accum++;
        }
    }
    
    
      
      
          for(float c = 0.1; c < 156.5; c += c)
    {
        amplitude_scale = 0.1 * sin(c + time) + 0.6;
        signal_offset = cos(c + 0.08 * time) * 0.2;
        phase_offset = sin(c + 0.03 * time) + 0.2 * time + c;
        
        if((result = smoothstep(0., 0.5 + 0.2 * sin(c), abs(uv.x - f2(uv.y)))) < 0.01)
        {
            accum++;
        }
    }
    
   col.g += float(accum) / 9.;
      
      col += pal( float(accum) / 8., vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
    col.r -= float(accum) / 3.;
      

    // Output to screen
    glFragColor = vec4(vec2(1.75)-col.xy, col.z,1.0) * 0.1 * (uv.x + 5.);
    glFragColor.r *= 1.75;
}
