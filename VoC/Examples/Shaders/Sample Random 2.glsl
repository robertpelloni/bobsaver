#version 420

// original https://www.shadertoy.com/view/Nsf3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////
uint seed = 0u;
void hash(){
    seed ^= 2747636419u;
    seed *= 2654435769u;
    seed ^= seed >> 16;
    seed *= 2654435769u;
    seed ^= seed >> 16;
    seed *= 2654435769u;
}
void initRandomGenerator(vec2 uv){
    seed = uint(uv.y*resolution.x + uv.x)+uint(time*6000000.0);
}

float random(){
    hash();
    return float(seed)/4294967295.0;
}
/////////////////////////////////////////////////////////////////////

void main(void)
{
    initRandomGenerator(gl_FragCoord.xy);
    vec3 col = vec3(random());
    glFragColor = vec4(col, 1.0);
}
