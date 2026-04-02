#version 420

// original https://www.shadertoy.com/view/3tKSRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author Reva - 2020-03-02

float random(in float num){
    float rnd = fract(sin(num*23.123 + (step(0.0,mod(time,3.0)))*floor(time/3.0))*9382.2942);
    return rnd;
}

float random2(in vec2 st){
    float rnd = fract(sin(dot(floor(st),vec2(12.762,8.329)))*3523.20392);
    return rnd;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = vec2(0.5) - uv;
    uv.x *= 200.0;
    uv.y *= (sin(time * 0.2) + 1.1)*6.0;
    uv.x += random(floor(uv.y)) * (step(1.0,mod(uv.y,2.0))*2.0 - 1.0) * time * 10.5;
    uv.y *= fract(random(floor(uv.y))*10.0);

    // Time varying pixel color
    vec3 col = vec3(step(random(floor(uv.y)+0.2),random2(uv)));
    col *= vec3(fract(uv.y),random(floor(uv.x)),random(floor(uv.y)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
