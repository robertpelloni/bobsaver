#version 420

// original https://www.shadertoy.com/view/tllSWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//--------------------------------------------------------
//Noise functions
//--------------------------------------------------------

float naturalNoise(vec2 p, vec2 seed)
{
    return fract(sin (p.x*seed.x+ p.y*seed.y)*5647.);
}

float smoothNoise(vec2 p, vec2 seed)
{
    vec2 lv = fract(p);
    vec2 id = floor(p);
    
    lv = lv*lv*(3.-2.*lv);
    float bl = naturalNoise(id, seed);
    float br = naturalNoise(id + vec2(1,0) , seed);
    float b = mix(bl, br, lv.x);
    
    float tl = naturalNoise(id+vec2(0,1),seed);
    float tr = naturalNoise(id+vec2(1,1),seed);
    float t = mix(tl, tr, lv.x); 
    
    return mix(b,t,lv.y);
}

float superSmoothNoise(vec2 p, vec2 seed)
{
    float c = smoothNoise(p*4., seed);
    c += smoothNoise(p*8.2, seed)*0.5;
    c += smoothNoise(p*16.7, seed)*0.25;
    c += smoothNoise(p*32.4, seed)*0.125;
    c += smoothNoise(p*64.5, seed)*0.0625;
    c += smoothNoise(p*130.2, seed)*0.03125;
    c+= (naturalNoise(p, seed))*.1;
    c /= 2.03125;
    
    return c;
}

//--------------------------------------------------------
//Color Process functions
//--------------------------------------------------------

vec3 rgbToVertex(vec3 col)
{
    return col/255.;
}

vec3 colorize(float c, vec3 color0, vec3 color1)
{
    return color0 + c*(color1-color0);
}

vec3 sweepColor(float c, vec2 uv, vec3 color0, vec3 color1)
{
    vec3 color2 = colorize(cos((time+30.)*0.18)-uv.x+0.5, color0, color1);
    vec3 color3 = colorize(cos((time+30.)*0.1)+uv.y-0.5, color1, color0);
    
    return colorize(c, color2, color3);
}

//--------------------------------------------------------
//Main function
//--------------------------------------------------------

void main(void)
{
    //Set uv coordinate system
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv-0.5;
    uv.x = uv.x * (resolution.x/resolution.y);

    //Warp space
    float scale = 3.+sin((time)*0.02)*1.3;
    uv *= scale;
    uv.x += 5.*cos(time*.01);
    uv.y += 7.*sin(time*.005);    
    
    //Generate and animate seed
    vec2 seed = vec2(102,6574);
    //vec2 seed = vec2(102,6574) + time*(cos(time)*.000001);
    //vec2 seed = vec2(102,6574) + time*.005;
    
    //Generate noise
    float c = superSmoothNoise(uv, seed);
    
    //Coloring Noise
    vec3 color0 = rgbToVertex(vec3(128.+sin(time*0.25)*50.));
    vec3 color1 = rgbToVertex(vec3(31.));
    
    vec3 col = sweepColor(c, uv/scale, color0, color1);
    //vec3 col = vec3(c);

    //Output color
    //vec3 col = vec3(c);   
    glFragColor = vec4(col,1);
}
