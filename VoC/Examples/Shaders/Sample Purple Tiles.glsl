#version 420

// original https://www.shadertoy.com/view/WdB3Wd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// from gold noise
float PHI = 1.61803398874989484820459 * 00000.1; // Golden Ratio   
float PI  = 3.14159265358979323846264 * 00000.1; // PI
float SQ2 = 1.41421356237309504880169 * 10000.0; // Square Root of Two

float rand(vec2 coordinate, float seed)
{
    return fract(tan(distance(coordinate*(seed+PHI), vec2(PHI, PI)))*SQ2);
}

float isolate_tile(vec2 uv, vec2 tile_size2, float isox, float isoy)
{
    if(uv.x < tile_size2.x * isox || uv.x > tile_size2.x * isox + tile_size2.x)
        return 0.0;
    
    if(uv.y < tile_size2.y * isoy || uv.y > tile_size2.y * isoy + tile_size2.y)
        return 0.0;
    
    return 1.0;
}

void main(void)
{
    vec3 palette[6];
    palette[0] = vec3(109.0, 31.0, 165.0) / 255.0;
    palette[1] = vec3(154.0, 71.0, 203.0) / 255.0;
    palette[2] = vec3(123.0, 39.0, 143.0) / 255.0;
    palette[3] = vec3(122.0, 74.0, 235.0) / 255.0;
    palette[4] = vec3(203.0, 163.0, 255.0) / 255.0;
    palette[5] = vec3(97.0, 37.0, 143.0) / 255.0;
    
    vec3 gradient[4];
    gradient[0] = vec3(37.0, 6.0, 100.0) / 255.0;
    gradient[1] = vec3(252.0, 194.0, 255.0) / 255.0;
    gradient[2] = vec3(188.0, 66.0, 208.0) / 255.0;
    gradient[3] = vec3(165.0, 110.0, 228.0) / 255.0;
    
    // tweakables
    float tile_size = 0.025;
    float x_offset = 12.0;
    float y_tiles = 24.0;
    float centre_width = 16.0;
    
    vec2 aspect = resolution.xy / resolution.xx;
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 col = vec3(0.0, 0.0, 0.0);

    // tile mask
    vec2 tile_size2 = vec2(tile_size, tile_size) / aspect;
    vec2 mm = mod(uv * aspect, tile_size);
    vec2 mv = smoothstep(0.0, tile_size, mm);
    
    float edge = 0.025;
    
    vec2 tile = step(mv, vec2(edge) * aspect);
    
    // tile isolate centre
    for(int i = 0; i < 70; ++i)
    {        
        float ep = 0.00001;
        float xx = floor(rand(vec2(time * ep + float(i), time * ep + float(i) * 5.0), float(i)) * centre_width);
        
        float yy = floor(rand(vec2(time * ep + float(i) * 3.0, time * ep + float(i)), float(i)) * y_tiles);
    
        col.rgb += isolate_tile(uv, tile_size2, x_offset + xx, yy);
    }
    
    // tile isolate sides
    for(int i = 0; i < 25; ++i)
    {        
        float ep = 0.000002;
        float xx = floor(rand(vec2(time * ep + float(i), time * ep + float(i) * 5.0), float(i)) * 40.0);
        
        float yy = floor(rand(vec2(time * ep + float(i) * 3.0, time * ep + float(i)), float(i)) * 16.0);
    
        col.rgb += isolate_tile(uv, tile_size2, xx, yy + 4.0);
    }
    
    // tile animation
    float yanim = mod(floor(time * 30.0), 40.0);
    for(int i = 0; i < 16; ++i)
    {
        for(int j = 0; j < 16; ++j)
        {
            float xx = floor(rand(vec2(float(j), float(j)), 0.0)* 10.0);
            float yy = mod(yanim + float(i) + float(j) * 2.0, 40.0);
            col.rgb += isolate_tile(uv, tile_size2, float(j) + 12.0, yy + xx);
        }
    }
     
    col.rgb *= clamp(1.0 - (tile.x + tile.y), 0.0, 1.0);
    vec3 inv_tile = clamp(1.0 - col.rgb * 0.1, 0.0, 1.0);
    
    if(length(col.rgb) > 0.99)
    {        
        float px = floor(uv.x / tile_size2.x);
        float py = floor(uv.y / tile_size2.y);
        float rp = mod( floor(rand(vec2(px, py), 0.0) * 126.0), 6.0);
        
        col.rgb = vec3(0);
        
        for(int pp = 0; pp < 6; ++pp)
            if(length(rp - float(pp)) < 0.2)
                col.rgb += palette[pp];
            
        col.rgb += (mm.x * 2.0 / tile_size2.x + mm.y * 2.0 / tile_size2.y) * 0.1;
        col.rgb *= 0.8;
    }
    
    // gradient background
    vec2 ndc = (uv * 2.0 - 1.0);
    
    float r = clamp( 1.0 - length(ndc*aspect), 0.0, 1.0);
    vec2 r2 = clamp( vec2(r + sin(time) * 0.2, r + cos(time)), 0.0, 1.0); 
    
    // col.rgb *= 1.0 - vec3(r2.x, r2.y, r) * 1.0 - inv_tile;
    
    vec3 bg = mix(gradient[0], gradient[1], r2.x);
    bg = mix(gradient[2], bg, r2.y);
    bg = mix(gradient[0], bg, r);
    bg = mix(bg, gradient[1], max((1.0 - uv.y) * sin(time) * 0.7, 0.0));
    
    col.rgb += bg * inv_tile;
    
    // tile modulate
    col.rgb *= 1.0 - bg * (1.0 - inv_tile);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
