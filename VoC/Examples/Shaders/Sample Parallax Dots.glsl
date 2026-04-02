#version 420

// original https://www.shadertoy.com/view/3lsGRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float grid(vec2 p,float res,float k){
     p.y+=time*k;
    vec2 u = fract(p * res)-.5;
    vec2 e = floor(p * res);
    float r = random2(e).x * 0.25;
    vec2 rnd =  random2(floor(p.y+2.) +e)-0.5;
    u -= rnd*(1.0 - r * 2.0);
    float d = length(u);
   return  smoothstep(r,r*1.2,d);   
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    float z = 1.0;
    for(float i = 3.; i < 7.0; i++){
            z *=grid(uv,i*3.,2.0-0.3*i);
    }
    glFragColor = vec4(z);
}
