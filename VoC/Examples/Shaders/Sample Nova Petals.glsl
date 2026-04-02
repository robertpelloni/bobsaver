#version 420

// original https://www.shadertoy.com/view/MlVyzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define brightness 40.
#define speed .3
#define rings 1024
#define blur .1
#define offset 6.
#define peaks 10.
#define peakStrength .5;
#define twisting 1.

float rectSin(float p){
    return sin(p) / 2. + .5;
}

float circle(float r, vec2 pos){
    return abs(r - length(pos));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 nuv =  uv * vec2(2) - vec2(1);
    nuv.x /= (resolution.y / resolution.x);

    vec3 col = vec3(0);
    int iter = rings;
    for(int i = 0; i < iter; i++){
        float prog = float(i) / float(iter);
        float angle = atan(nuv.x,nuv.y);
        float radius = pow(rectSin(time * speed + prog * offset),2.);
        radius += pow(radius,.3) * abs(rectSin(time / 1. + (angle + rectSin(time - radius) * twisting) * peaks)) * peakStrength;
        vec3 ringColor = vec3(
            (1.5 - prog - radius) / (radius + .1),
            rectSin(radius) / (radius + .1),
            pow(prog,2.) + pow(1. - prog,1.));
        ringColor += ringColor * smoothstep(0.1,1.,pow(mod(prog , .25) * 4.,9.)) * radius;
        
        col +=  ringColor * smoothstep(1.,0.,circle(radius,nuv) / blur);
    }
    col /= sqrt(length(col));
    col /= (float(rings) / log(1. / blur));
    col = col * brightness;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
