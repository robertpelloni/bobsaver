#version 420

// original https://www.shadertoy.com/view/ftGfDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N_tile 30.

vec3 mix4ColorGradient(float ratio, vec3 start, vec3 mid1, vec3 mid2, vec3 end){
    return
    mix(
        mix(
            mix(start, mid1, ratio/.33), mix(mid1, mid2, (ratio - .33)/.66), 
            step(.33, ratio)), 
        mix(mid2, end, (ratio-.66)/.33), 
            step(.66, ratio));
}

vec2 hash( vec2 p )
{
    //p = mod(p, 4.0); // tile
    p = vec2(dot(p,vec2(175.1,311.7)),
             dot(p,vec2(260.5,752.3)));
    return fract(sin(p+455.)*18.5453);
}

vec3 random_color(vec2 p)
{
    return vec3(hash(p).x, hash(2.*p).x, hash(3.*p).x);
}

vec3 make_cell(vec2 tile_coord, vec2 tile_idx, vec3 background_noise){
    
    vec3 res = vec3(0, 0, 0);
    float length_coord = length(tile_coord);
    float l_inf_coord = max(abs(tile_coord.x), abs(tile_coord.y));
    float radius = (0.35 + hash(tile_idx).x*.5)/2.;
    
    float activation_int = 1.-smoothstep(radius-0.04, radius+0.04, length_coord);
    float activation_contour = smoothstep(.47, .5, l_inf_coord);
    
    vec3 color_int = activation_int*random_color(tile_idx);
    vec3 color_cell = (1.-activation_int)*background_noise*(1.-activation_contour);
    vec3 color_ext = activation_contour*vec3(0., 0., 0.);

    res = color_int+color_cell+color_ext;
    return res;
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = hash(i).x;
    float b = hash(i + vec2(1.0, 0.0)).x;
    float c = hash(i + vec2(0.0, 1.0)).x;
    float d = hash(i + vec2(1.0, 1.0)).x;
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float fbm( in vec2 x)
{    
    float t = 0.0;
    for( int i=0; i<6; i++ )
    {
        float f = pow( 2.0, float(i) );
        float a = pow( f, -1. );
        t += a*noise(f*x);
    }
    return t*1.-.4;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.yy - .5;

    vec2 pos = vec2(uv*6.0);

    vec2 tile_coord = fract(uv*N_tile)-.5;
    vec2 tile_idx = floor(uv*N_tile)-.5;
    
 
    // Use the noise function
    float reshape = 16.;
    
    vec2 tmp = sin( vec2(0.27+time/2000.,0.23)*time + .1*length(tile_idx)*vec2(2.1,2.3))+tile_idx*.1;
    
    float n = fbm(tmp+fbm(tmp));
    
    
    vec3 color_low = vec3(5., 0., 40.);
    vec3 color_mid1 = vec3(30., 80., 20.);
    vec3 color_mid2 = vec3(210., 20., 60.);
    vec3 color_high = vec3(210., 230., 0.);
    
    
    vec3 background_color = mix4ColorGradient(n, color_low, color_mid1, color_mid2, color_high);
    background_color = normalize(background_color);
    
    
    vec3 color = make_cell(tile_coord, tile_idx, background_color);
    
    

    // Output to screen
    glFragColor = vec4(color, 1.0);
}
