#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define SIZE 1.2
uniform sampler2D backbuffer;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rand2(vec2 co){
    return fract(19.16*co+fract(358.42*co.yx));
}

void main( void ) {
    vec2 uv;
    vec2 mousePos;
    vec3 outColor;
    
    uv = gl_FragCoord.xy / resolution.xy - vec2(0.5);
    uv.y *= resolution.y / resolution.x;
    
    mousePos = mouse - vec2(0.5);
    mousePos.y *= resolution.y / resolution.x;
    float e = 0.03*SIZE;
    mousePos += e*rand2(12.56*time*mousePos)-0.5*e;
    
    float oldY = texture2D(backbuffer, gl_FragCoord.xy / resolution.xy).a;
    float y = 0.03 / (0.4+pow(20.*distance(uv, mousePos)/SIZE, 1.91));
    y += oldY*0.995;
    y -= 0.002;
    outColor = hsv2rgb(vec3(0.66*pow(oldY,0.9)+0.48, 0.9, 1.));
    glFragColor = vec4(outColor*smoothstep(0.01,0.8,y), y);
}
