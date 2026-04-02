#version 420

// original https://www.shadertoy.com/view/3lsfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

float grid(in float _offset, in vec2 _uv){
    float gridx = smoothstep(0.01,0.01,sin(_uv.x-_offset));
    float gridy = smoothstep(0.01,0.01,sin(_uv.y-_offset));
    return gridx * gridy;
}

float lines(in float _offset, in vec2 _uv){
    float lines = smoothstep(0.0,0.1,sin(_uv.x-_offset));
    return lines;
}

float stripes(in float _offset, in vec2 _uv){
    float stripes = step(smoothstep(0.2,0.5,sin(_uv.y-_offset)),.5);
    return stripes;
}

float box(vec2 _uv, vec2 _size, float _smoothEdges){
    _size = vec2(0.5)-_size*0.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_uv);
    uv *= smoothstep(_size,_size+aa,vec2(1.0)-_uv);
    return uv.x*uv.y;
}

vec2 tile(in float _zoom, in vec2 _uv){ 
    _uv *= _zoom;
    
     _uv.x += step(1.0, mod(_uv.y,2.0)) * -abs(sin(time)) * floor(sin(time)*cos(time));
    _uv.x += step(1.0, mod(_uv.y+1.0,2.0)) * abs(sin(time)) * floor(sin(time)*cos(time));
    _uv.y += step(1.0, mod(_uv.x,2.0)) * -abs(sin(time)) * ceil(sin(time)*cos(time));
    _uv.y += step(1.0, mod(_uv.x+1.0,2.0)) * abs(sin(time)) * ceil(sin(time)*cos(time));

    return fract(_uv);
}

vec2 rotate2d(in float _angle, in vec2 _uv){
    _uv -= .5;
    _uv *=  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
    _uv += 0.5;
    return _uv;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= 1.735;

    // Time varying pixel color
    vec3 col = vec3(0.0);
    
    uv = rotate2d(PI*-.45, uv);
    
    //Tile for grids
    vec2 uv0 = tile(4.1, uv);
    vec2 uv01 = tile(4.1, uv + vec2(2.5));
    vec2 uv02 = tile(4.1, uv + vec2(5.0));
    
    vec2 uv03 = tile(4.1, uv + vec2(7.245));
    
    //Grids
    float grid0 = grid(.1, uv0);
    float grid01 = grid(.1,uv01);
    float grid02 = grid(.1,uv02);
    
    float grid03 = grid(.025,uv03);
    
    //Boxes
    float box0 = box(uv0-vec2(.05), vec2(.125), .01);
    float box01 = box(uv01+vec2(.445), vec2(.125), .01);
    float box02 = box(uv02-vec2(.05), vec2(.125), .01);
    float box03 = box(uv02-vec2(-0.2,.05), vec2(.125), .01);
    float box04 = box(uv02-vec2(-0.45,.05), vec2(.125), .01);
    float box05 = box(uv01+vec2(-0.3,.445), vec2(.125), .01);
    float box06 = box(uv01+vec2(.2,.445), vec2(.125), .01);
    float box07 = box(uv0-vec2(.3,.05), vec2(.125), .01);
    float box08 = box(uv0-vec2(-.45,.05), vec2(.125), .01);
    
    //lines to subtract from grids
    vec2 uv0rot = rotate2d(PI*.2,uv);
    float lines0 = lines(0.5, uv0rot*500.0);
    
    //stripes
    float stripes0 = 1.0 - stripes(0.335, uv*vec2(25.75));
    
    col += clamp(grid0 * grid01 * grid02 + (1.0-lines0),0.0,1.0);
    col -= box0 + box01 + box02 + box03 + box04 + box05 + box06 + box07 + box08;
    col -= stripes0 * .5;
    col *= clamp(1.0 - (vec3(1.0-grid03) - (1.0-lines0)),0.0,1.0);
    col += clamp(vec3(1.0-grid03,0.0,0.0) - (1.0-lines0),0.0,1.0);
    col *= clamp((1.0-lines0),0.9,1.0);
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
