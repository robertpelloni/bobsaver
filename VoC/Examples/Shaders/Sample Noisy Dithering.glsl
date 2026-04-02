#version 420

// original https://www.shadertoy.com/view/flXGW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Noisy Dither
//Lopea
//2021

#define time time

//IQ's Gradient noise algorithm
/////////////////////////////////////////////////////////////////////////////
vec2 random(vec2 st)
{
    st = vec2( dot(st,vec2(127.1,331.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    vec2 a  = random(i);
    vec2 b = random(i + vec2(1,0));
    vec2 c = random(i + vec2(0, 1));
    vec2 d = random(i + vec2(1, 1));
    
    vec2 u = f * f * f *(f *(f*6. - 15.)+10.);
    
    return mix(mix ( dot( a, f), dot(b, f - vec2(1, 0)), u.x),
        mix ( dot( c, f-vec2(0,1)), dot(d, f - vec2(1, 1)), u.x), u.y);

}
/////////////////////////////////////////////////////////////////////////////

//fractal brownian motion
float fbm(vec2 uv)
{
    //store the result of the noise texture
    float result = 0.;
    
    //store the current amplitude value
    float amplitude = 1.;
    
    //iterate a few times to give noise a more detailed look
    for(int i = 0; i < 8; i++)
    {
        //add to the result ( with a few modifications
        result += noise(uv + vec2( time - float(i)  +10., -time/25.- float(i)/2.)) * amplitude;
        
        //shrink the noise texture for the next iteration
        uv *= 2.;
        
        //make next noise iteration less potent 
        amplitude *= 0.5;
    }
    
   
    return result;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    //set the threshold for color value, will be compared to screen space.
    float threshold = fbm(vec2(fbm(uv * 10.), fbm(uv * 10. + 3.)));
    
    //create the dithering effect by warping the screen coordinates
    float coord = sin(uv.x * 1000.) * sin(uv.y * 1000.) * .25;
    
    //compare warped screen coords to the threshold and create the color value
    vec3 color = mix(vec3(0, .04, .1), vec3(0,1,1) , vec3(step(coord, threshold)));
    
    //create an outline effect by subracting same algorithm but with a smaller threshold
    color -= step(clamp(coord, 0., 1.), threshold - .1) * vec3(1);
    
    //set the color to the pixel
    glFragColor = vec4(color , 1);
    
}
