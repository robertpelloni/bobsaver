#version 420

// original https://www.shadertoy.com/view/td2BRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Defines

#define COLOR_SKY vec3(.1,.2,.6)
#define COLOR_CLOUDS vec3(.98,.96,.92)
#define COLOR_DARK_SOMETHING vec3(.1,.01,.1)
#define SCREEN_GAMMA 2.2

// Function prototypes

float hash(float value); // Produces random values
float hash(vec2 value); // Produces random values
float noise(vec2 position); // A single layer of noise
float value_noise(vec2 position, int octaves); // Multiple layers of noise
mat2 rotate2D(float a); // Returns 2D rotation matrix

void main(void)
{
    // Normalized pixel coordinates
    vec2 uv = gl_FragCoord.xy/resolution.yy;
    vec2 position = uv;
    
    // Rotate and translate the camera using some random sine waves
    position*=rotate2D(time*.1)*pow(2.0,sin(time*.1));
    position = position*7.0+sin(vec2(time, time+2.0));
    
    // Add some distorsion, often used for chaging the texture
    float distort_amount = sin(time*.3)*.5+.5; // set to 0 to disable distorsion
    position = position + distort_amount*vec2(
        2.0*value_noise(position*.23+time*.1, 8),
        4.0*value_noise(position*.14-time*.1, 8));
    
    // This is where the texture is sampled.
    float noise_value = value_noise(position, 16);
    noise_value=mix(noise_value, value_noise(position*.2+4.0, 16),.5);

    // Apply gradient 1 which makes it look like clouds
    vec3 col = mix(COLOR_CLOUDS, COLOR_SKY, smoothstep(.2,.7,noise_value));

    // Apply another gradient
    vec3 col2 = mix(COLOR_CLOUDS, COLOR_DARK_SOMETHING, pow(abs(noise_value-(sin(time*2.0)*.1+.5))*2.0,.2));
    
    // Mix between the two gradients
    col=mix(col,col2, smoothstep(-.2,.2, sin(time+uv.x*.2))); // cooment out for clouds only
    
    // Gamma correction
    col=pow(col, vec3(1.0/SCREEN_GAMMA));

    // Output to screen
    glFragColor = vec4(col,1.0);
}

mat2 rotate2D(float a){
    float c=cos(a), s=sin(a);
    return mat2(c,s,-s,c);
}

// https://en.wikipedia.org/wiki/Value_noise
float value_noise(vec2 position, int octaves){
    float value = 0.0;
    // Sum together various layers of noise
    for (int i=1; i<octaves; i++)
    {
        float scale = pow(2.0,float(i)); // At different scales
        float contrib = 1.0/scale; // Weighted accordint to scale
        value += noise(position*scale)*contrib;
    }
    return value;
}

float noise(vec2 position){
    // Fractional part is used for interpolation
    vec2 fractional_part = fract(position);
    // Integral part is used for sampling the hash function
    vec2 integral_part = position-fractional_part;
    
    // Generate 4 sample points
    float sample_00=hash(integral_part);
    float sample_10=hash(integral_part+vec2(1,0));
    float sample_11=hash(integral_part+vec2(1,1));
    float sample_01=hash(integral_part+vec2(0,1));
    
    // Interpolate them so we have nice and stable continuous texture
    return mix(
        mix(sample_00, sample_10, fractional_part.x),
        mix(sample_01, sample_11, fractional_part.x),
        fractional_part.y
    );
}

float hash(vec2 v) 
{ 
    // Random numbers thrown together to produce other random numbers
    return fract(hash(v.x*.97+v.y*.98)*143.94213); 
}

float hash(float v) 
{ 
    // Even more pseudo randomness
    return fract(fract(v*11.3334)*fract(v*91.73362341)*43.123*429.32234643);  
}

