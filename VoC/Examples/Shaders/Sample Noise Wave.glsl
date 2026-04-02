#version 420

// original https://www.shadertoy.com/view/4dffzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(in vec2 position) {
    return fract(sin(dot(position.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Value Noise courtesy of Book of Shaders
// https://thebookofshaders.com/11/
float noise2d(vec2 uv) {
    
    vec2 pos = floor(uv);
    vec2 fractional = fract(uv);
    
    // four corners
    float a = noise(pos);                    // bottom left
    float b = noise(pos + vec2(1., 0.));    // bottom right
    float c = noise(pos + vec2(1., 1.));    // top right
    float d = noise(pos + vec2(0., 1.));    // top left
    
    vec2 intermix = smoothstep(0., 1., fractional);
    
    float value = mix(a, b, intermix.x);
    value += (d - a) * intermix.y * (1.0 - intermix.x);
    value += (c - b) * intermix.x * intermix.y;
    
    return value;
}

// Fractal noise courtesy of iq
// https://www.shadertoy.com/view/XdXGW8
float fractalNoise2d(vec2 uv) {
    uv *= 3.0;
    uv.x -= time / 5.0;
    uv.y += sin(time / 5.0) * 2.0;
    
    mat2 rotate = mat2(1.6 - sin(time / 100.0) / 10.0, 1.2, -1.2, 1.6);
    
    float value = 0.5 * noise2d(uv);
    uv *= rotate;
    value += 0.25 * noise2d(uv);
    uv *= rotate;
    value += 0.125 * noise2d(uv);
    uv *= rotate;
    value += 0.0625 * noise2d(uv);
    
    return value;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.y *= resolution.y/resolution.x;
    
    // use josemorval paper sheet for reference
    float dist,dist1,mask,l,final = 1.0;
    //This parameter controls how many sheets are in the picture
    float s = 0.01;
    
    float amp,freq;
    uv.y -=resolution.y/resolution.x;
    
    float value = fractalNoise2d(uv)*5.;
    
    //This parameter controls when the algorithm stop drawing sheets (-1 is no sheet, 1 all sheets)
    float factorSheets = resolution.y/resolution.x;
    
    for(float f = -resolution.y/resolution.x; f < factorSheets; f+=s){
        uv.y += s;
        //This parameter controls the frequency of the waves, modulated by an exp along the x-axis 
        freq = 5.0*exp(-10.0*(f*f)) + value*sin(time);
        //This parameter controls the amplitude of the waves, modulated by an exp along the x-axis 
        amp = 0.12*exp(-10.0*(f*f)) + value / 20. *cos(time);
        dist = amp*pow(sin(freq*uv.x + time + 100.0),2.0)*exp(-5.0*uv.x*uv.x)-uv.y;
        mask = 1.0-smoothstep(0.0,0.005,dist);

        //Draw each line of the sheet
        dist1 = abs(dist);
        dist1 = smoothstep(0.0,0.01,dist1);
        
        final = mix(dist1, -dist1*final,mask);
    }

    glFragColor = vec4(final*2.,final,final*uv.y*3., 1.0);
}
