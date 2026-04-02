#version 420

// original https://www.shadertoy.com/view/XlVSz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TAU = 6.2831853071;
const float PI = 3.14159265359;
const float GOLD = 1.6180339887;
const float N = 0.998;                // particle move distance
const float S = 0.1;                // Speed
const float PS = 20.0;                // particle size

vec4 lerp(float t, vec4 A, vec4 B){
     return (A*(1.0-t))+(B*t);
}

void main(void)
{
    float ratio = resolution.x/resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x *= ratio;
    uv.x += 0.5-(ratio*0.5);
    
    vec2 ce = vec2(0.5,0.5);                            // center
    
    float particlePower = 0.0;
    for(float p = 0.0; p < N; p+=0.001){
        float pAngle = p*1000.0*GOLD;
        float pDist = mod((time*S+p),N);
        vec2 point = vec2(sin(pAngle),cos(pAngle))*pDist;
        point = point+ce;
        float pd = length(vec2(point.x-uv.x,point.y-uv.y));
        //glFragColor = lerp(pd*PS,glFragColor,vec4(0.0,0.0,1.0,1.0));
        particlePower += clamp(((.08*clamp(pDist,0.4,0.65))-pd)*PS,0.0,0.5);
    }
    particlePower = clamp(particlePower*1.3,0.0,1.0);
    float r = particlePower;
    float b = 0.5*(1.0-(particlePower));
    glFragColor = vec4(r,r+(b*0.5),(b*0.6),0.0);
}
