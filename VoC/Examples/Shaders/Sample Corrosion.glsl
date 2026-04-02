#version 420

// original https://www.shadertoy.com/view/4sVyzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-- 2D Worley noise. -------------------------------------------------------

float r(float n)
{
     return fract(cos(n*72.42)*173.42);
}

vec2 r(vec2 n)
{
     return vec2(r(n.x*63.62-234.0+n.y*84.35),r(n.x*45.13+156.0+n.y*13.89)); 
}

float worley2D(in vec2 n)
{
    float dis = 2.0;
    for (int y= -1; y <= 1; y++) 
    {
        for (int x= -1; x <= 1; x++) 
        {
            // Neighbor place in the grid
            vec2 p = floor(n) + vec2(x,y);

            float d = length(r(p) + vec2(x, y) - fract(n));
            if (dis > d)
            {
                 dis = d;   
            }
        }
    }
    
    return 1.0 - dis;
}

//--------------------------------------------------------------------------

#define NUM_OCTAVES 8

float fbm ( in vec2 _uv) 
{
    // Starting value
    float v = 1.;
    
    // Starting amplitude.
    float a = 1.;
    
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(1.25), sin(1.25),
                    -sin(1.25), cos(1.25));
    
    // Stable upward shift.
    vec2 shift = -vec2(0., -time);
    
    for (int i = 0; i < NUM_OCTAVES; ++i) 
    {
        v += a * worley2D(_uv);
        _uv = _uv * rot * 2. + shift * 0.5;
        
        // Amplitude is halved on each octave.
        a *= 0.5;
    }
    
    return v;
}

// Colors.
vec3 LightCyan = vec3(0.000, 0.864, 0.825);
vec3 AquaBlue = vec3(0.000, 0.478, 0.800);
vec3 RustyBrown = vec3(0.530, 0.360, 0.000); 

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = -1.0 + 2.0 * q;
    uv.x *= resolution.x/resolution.y;
    uv *= 4.;

    float w = fbm(uv - fbm(uv * 3.) * fbm(uv));
    
    // Draw the min distance.
    vec3 col = vec3(w / 4.0);

    // Color mix.
    col = mix(LightCyan,
              RustyBrown,
              clamp((col * col) * 2.5, 0.1, 1.0));

    // Output to screen
    glFragColor = vec4((col * col) * 1.65, 1.0);
}
