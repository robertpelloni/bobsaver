#version 420

// original https://www.shadertoy.com/view/ttlyRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// set to '0' for manual controls
#define animated 1 

//number of swatches
const int numcolors = 7;

//manual controls

    //initial value
    const float h_pos = 0.5;
    const float s_pos = 0.5;
    const float v_pos = 0.5;

    //swatch width
    const float h_width = 0.2;
    const float s_width = 0.3;
    const float v_width = 0.4;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float swatchmask(vec2 uv, float aspect)
{
    vec2 swatchuv = vec2( fract(uv.x * float(numcolors)), (uv.y - 0.5) * aspect + 0.5);
    float swatchmask = 1.- abs(swatchuv.x * 2. - 1.);
    swatchmask = min(swatchmask, 1. - abs(swatchuv.y * 2. - 1.));
    swatchmask = ceil(swatchmask-0.05); 
    return clamp(swatchmask, 0., 1.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float aspect = resolution.y / resolution.x * float(numcolors); 
    
    float voffset = floor(uv.x * float(numcolors)) / float(numcolors-1) * 2. - 1.;
    
    float hue, saturation, value;
    
    if (animated == 1) 
    {    
        float T = time * 3.1415 + 6.;
        hue = fract(T*0.05) + voffset * (sin(T*0.1) * 0.15 + 0.1);
        saturation = (sin(T*0.3)*0.3+0.4) + voffset * sin(T*0.15) * 0.6;
        value = (sin(T*0.4)*0.15+0.4) + voffset * sin(T*0.2) * 0.3;    
    }
    else
    {
        hue = h_pos + voffset * h_width;
        saturation = s_pos + voffset * s_width;
        value = v_pos + voffset * v_width;
    }
    
    vec3 col = hsv2rgb( vec3( hue, saturation, value) );
                       
    col = mix( vec3(0.25), col, vec3(swatchmask(uv, aspect)) );
                       
    glFragColor = vec4(col, 1.0);
}
