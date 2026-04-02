#version 420

// original https://www.shadertoy.com/view/tslXzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TAU 6.28318530718

vec2 cs(float f) {
    return vec2(cos(f), sin(f));
}

float noise(float f) {
    return fract(sin(f*1430.856+1355.2)*9898.11);
}
vec3 noise3(float f){ 
    return vec3(noise(f), noise(f*1.2+43.), noise(f*1.3+12.));
}

vec3 getColor(float i, float t) {
    vec3 c1 = noise3(floor(t) + i);
    vec3 c2 = noise3(floor(t) + i + 1.);
    return mix(c1, c2, fract(t));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 texCoord = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    float falloff =1.-length(texCoord)*.25;
    //texCoord.x += time*.1;
    
    vec3 result = vec3(0,0,0);
    float sum = 0.;

    vec3 color;
    for(float i = 1. ; i <= 5. ; i++) {
        color = getColor(float(i), time);
        float d = length(texCoord);
        float r = .18;
        if(d<r){
            d/=r;
            float v = 1.-d;
            v = pow(v, 2.) * falloff;
            //sum += v*3;
            //result = lerp(color, result, v/sum);
            result += color*v;
            sum += v;
        }
        
        float section = mix(6.,8.,sin(time*.4));
        float a = fract(atan(texCoord.y,texCoord.x)/TAU+.5)*section;
        //sum += i*.1;
        texCoord += cs((floor(a)+.5)/section*TAU)/pow(2.,i)*1.5;
        //result.r = floor(a);
        //result.g += 20.0-length(texCoord)*100.0;
        //break;
        //r = a;//TAU*(fract(time*.01)+1.);
        //float c = cos(r);
        //float s = sin(r);
        //texCoord *= mat2(vec2(c,-s),vec2(s,c));
        //texCoord = fract(texCoord)*2.-1.;
        
    }
    color = result * sum;
    glFragColor.rgb = color;
}
