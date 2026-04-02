#version 420

// original https://www.shadertoy.com/view/wtt3Rf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Convention:
// vec2s ending with 'c'
// are in circular coords
// ex: pc = vec2(angle of p, length of p)

#define time (time / 3.0)

#define PI2 6.28
#define PI 3.1416

// Point to polar coord
vec2 p_to_pc(vec2 p){
    return vec2(atan(p.y, p.x), length(p));
}

// Polar coord to point
vec2 pc_to_p(vec2 pc){
    return vec2(pc.y * cos(pc.x), pc.y * sin(pc.x));
}

// I use these fields to create and tweak the snowflakes
vec2 fieldA(vec2 pc){
    // Modify angle and distance
    pc.y += 0.02 * floor(cos(pc.x * 6.0 ) * 5.0);
    pc.y += 0.01 * floor(10.0 * cos(pc.x * 30.0));
    pc.y += 0.5 * cos(pc.y * 10.0);
    
    // Take back to position
    return pc;
}

// Different values of f happen to give quite different
// snowflake shapes. Interesting...
vec2 fieldB(vec2 pc, float f){
    // Modify angle and distance
    pc.y += 0.1 * cos(pc.y * 100.0 + 10.0);
    pc.y += 0.1 * cos(pc.y * 20.0 + f);
    pc.y += 0.04 * cos(pc.y * 10.0 + 10.0);
    
    return pc;
} 

vec4 snow_flake(vec2 p, float f){
    
    vec4 col = vec4(0.0);

    vec2 pc = p_to_pc(p * 10.0);
    
    
    pc = fieldA(fieldB(pc, f));
    
    p = pc_to_p(pc);
    
    float d = length(p);
    
    if(d < 0.3){
        col.rgba += vec4(1.0);
    }
    
    return col;
}

vec4 snow(vec2 p){
   
    vec4 col = vec4(0.0);

    p.y += 1.5 * time;
    
    p = fract(p + 0.05) - 0.5;
    
    p *= 1.0;
    
    
    p.x += 0.01 * cos(p.y * 3.0 + p.x * 3.0 + time * PI2);
    
    
    // Just me pseudo randomly adding snowflakes
    // Could be optimized by not calling the function 8 times
    // (using some field distortion )
    col += snow_flake(p, 1.0);
    col += snow_flake(p + vec2(0.2, -0.1), 4.0);
    col += snow_flake(p * 2.0 + vec2(-0.4, -0.5), 5.0);
    col += snow_flake(p * 1.0 + vec2(-0.2, 0.4), 9.0);
    col += 2.0 * snow_flake(p * 1.0 + vec2(0.4, -0.4), 5.0);
    col += snow_flake(p * 1.0 + vec2(-1.2, 1.2), 9.0);
    col += snow_flake(p * 1.0 + vec2(2.4, -1.2), 5.0);
    col += snow_flake(p * 1.0 + vec2(-1.2, 1.1), 9.0);
   
    
    return col;
}

void main(void) {
    
    vec2 uv = gl_FragCoord.xy / resolution.x;
    float x = uv.x;
    float y = uv.y;
    
    vec2 p = vec2(x, y) - vec2(0.5);
       
    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
    
    col += 0.3 * snow(p * 2.0);
    col += 0.2 * snow(p * 4.0 + vec2(time, 10.0));
    col += 0.1 * snow(p * 8.0);
    
    col.a = 0.1;
    
    glFragColor = col;
}
