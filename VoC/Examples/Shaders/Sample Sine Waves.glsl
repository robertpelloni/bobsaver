#version 420

// original https://www.shadertoy.com/view/4lGXWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float horizontal(vec2 uv, float r)
{
    float result = abs(uv.y)-r;
    float res2 = 1.0-result;
    float res3 = result * -1.0;
    res3 = 1.0 - res3;
    result = res2 * res3;
    //result = pow(result,8800.0);
    //result += 1.0;
    result = smoothstep(.01/resolution.y,0.,1.-result);
    return result;
}

float gradient(vec2 uv, float r)
{
     float result = length(vec2(0.0,uv.y));
    float res2 = 1.0-result;
    float res3 = res2*-1.0;
    result = res2 * result;
    result *= 4.0; 
    return result;
    
}

float horiwaves(vec2 uv, float frequency, float Amplitude)
{
    float result = sin(uv.x*frequency);
    return result*Amplitude*sin(uv.x);
}

vec3 makewave(vec2 uv,float frequency, float amplitude, float zoffset, vec3 color, float speed)
{
    uv.x += time*speed;
    float mask = horiwaves(uv,frequency,amplitude);
    float result = horizontal(uv-mask,zoffset);
    //result = clamp(result,0.0,1.0);
    vec3 colorpass = result*color;
    return colorpass;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float SW = ((sin(time) + 1.0)*0.5)-.50;
    float grad = gradient(uv,0.5);
    uv.x -= 2.0;
    //SW *= mask;
    vec3 color1 = makewave(uv,15.0,0.20*sin(time),0.5,vec3(1.0,0.1,0.0),0.5);
    vec3 color2 = makewave(uv,12.0,0.40*sin(time+1.2),0.40,vec3(0.1,1.0,0.0),0.5);
    vec3 color3 = makewave(uv,20.0,0.30*sin(time+2.5),0.35,vec3(1.0,1.0,0.0),0.5);
    vec3 color4 = makewave(uv,5.0,0.50*sin(time+2.0),0.50,vec3(1.0,0.0,1.0),0.5);
    vec3 gradient = vec3(uv.y);
    vec3 finalColor = (color1-vec3(0.1)) + (color2-vec3(0.1)) + (color3-vec3(0.1)) + (color4-vec3(0.1));
    //glFragColor = vec4(vec3(uv,0.0),1.0);
    glFragColor = vec4(finalColor,1.0);
}
