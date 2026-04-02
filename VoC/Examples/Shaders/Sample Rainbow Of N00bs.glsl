#version 420

// original https://www.shadertoy.com/view/MtjGRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323

//Random
float rand(vec2 uv)
{
    float dt = dot(uv, vec2(12.9898, 78.233));
    return fract(sin(mod(dt, PI / 2.0)) * 43758.5453);
}

//HSL
vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

//My function for rainbow
float grid(float val, float scale)
{
    return mix(floor(val*scale)/scale,val,0.2);
}

//Clouds from (https://www.shadertoy.com/view/MlS3z1)
const int iter = 8;
   
float turbulence(vec2 Coord, float octave, int id)
{
    float col = 0.0;
    vec2 xy;
    vec2 frac;
    vec2 tmp1;
    vec2 tmp2;
    float i2;
    float amp;
    float maxOct = octave;
    for (int i = 0; i < iter; i++)
    {
        amp = maxOct / octave;
        i2 = float(i);
        xy = id == 1 || id == 4? (Coord + 50.0 * float(id) * time / (4.0 + i2)) / octave : Coord / octave;
        frac = fract(xy);
        tmp1 = mod(floor(xy) + resolution.xy, resolution.xy);
        tmp2 = mod(tmp1 + resolution.xy - 1.0, resolution.xy);
        col += frac.x * frac.y * rand(tmp1) / amp;
        col += frac.x * (1.0 - frac.y) * rand(vec2(tmp1.x, tmp2.y)) / amp;
        col += (1.0 - frac.x) * frac.y * rand(vec2(tmp2.x, tmp1.y)) / amp;
        col += (1.0 - frac.x) * (1.0 - frac.y) * rand(tmp2) / amp;
        octave /= 2.0;
    }
    return (col);
}
//____________________________________________________

//Draw on screen
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float time = time;
    //Rainbow's positions
    vec2 rainbowuv = vec2(((uv.x*4.)-1.5)+(sin((time*1.0)+uv.y*PI)/3.),0.);
    //Make a rainbow
    vec3 rainbow = clamp(hsl2rgb(vec3(grid(rainbowuv.x+rainbowuv.y,8.)-0.05,1.,0.5))*vec3(1.7,1.4,1.2),0.,1.);
    //Make a rainbow mask
    float rainbowmask = 1.-(float((rainbowuv.x+rainbowuv.y) < 0.)+float((rainbowuv.x+rainbowuv.y) > 1.));
    
    //Sky
    vec3 sky = clamp(vec3(0.2,sin(uv.y),1.)+0.3,0.,1.);
    
    //Sky+Rainbow
    vec3 skyandrainbow = (mix(sky,rainbow,rainbowmask));
    
    //Clouds
    vec2 Coord = gl_FragCoord.xy;
    float cloud1 = turbulence(Coord, 128.0, 1);
    float cloud2 = turbulence(Coord+2000., 128.0, 1);
    float cloudss = clamp(pow(mix(cloud1,cloud2,0.5),30.)/9.,0.,1.);
    
    //Output
    glFragColor = vec4(skyandrainbow+cloudss,1.0);
}
