#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdVfWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 4.*atan(1.);

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec2 rand(vec2 n) { 
    float a = fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
    float b = fract(cos(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
    return vec2(a,b);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv =  10.* ( 2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;

    float r = length(uv);
    
    if (int(floor(r)) % 2 == 0) {
        float freq = rand(vec2(floor(r),1)).y;
        uv *= rotate(freq*time);
    }
    else {
        float freq = rand(vec2(floor(r),-1)).y;
        uv *= rotate(-freq*time);
    }
    
    float theta = atan(uv.y,uv.x)+pi;

    float n = 7.;    
    float eps = 30./resolution.y;
    float dt = abs(mod(theta+pi/n,2.*pi/n)-pi/n);
    float ct = smoothstep(2.*eps,eps,dt*r);
    
    float dr = abs(fract(r+0.5)-0.5);
    float cr = smoothstep(2.*eps,eps,dr);
    
    float cc = max(ct,cr);
    
    vec2 dc = rand(vec2(floor(n*theta/(2.0*pi)),floor(r)));
    vec3 col = mix(vec3(dc.x,.5,dc.y),vec3(0.),cc);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
