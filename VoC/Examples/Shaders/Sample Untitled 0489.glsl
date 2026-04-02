#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

float c(vec2 uv)
{
    uv.x *= sin(1.+uv.y*.125)*0.5;
    float t =  time*0.4;
    uv.x = uv.x*64.0;
    float dx = fract(uv.x);
    uv.x = floor(uv.x);
    uv.y *= 0.15;
    float o=sin(uv.x*215.4);
    float s=cos(uv.x*33.1)*.3 +.7;
    float trail = mix(145.0,15.0,s);
    float yv = 1.0/(fract(uv.y + t*s + o) * trail);
    yv = smoothstep(0.0,1.0,yv*yv);
    yv = sin(yv*PI)*(s*5.0);
    float d = sin(dx*PI);
    return yv*(d*d);
}

void main(void)
{ 
 vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
 vec3 col = vec3(1.1,0.9,0.9)*c(uv);
 glFragColor=vec4(col,1.);
}
