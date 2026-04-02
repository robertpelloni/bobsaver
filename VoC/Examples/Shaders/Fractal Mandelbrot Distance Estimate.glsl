#version 420

// original https://www.shadertoy.com/view/4dlyRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform int frames;

out vec4 glFragColor;

//math
vec2 cmult(vec2 z1, vec2 z2) {
    return vec2(z1.x*z2.x - z1.y*z2.y, z1.x*z2.y + z1.y*z2.x);
}

const int maxIter = 300;
float mandelbrot(vec2 c) {
    vec2 z = vec2(0.0, 0.0);
    vec2 zd = vec2(0.0, 0.0);
    for(int i = 0; i < maxIter; i++) {
        if(length(z) > 10.0) break;
        zd = 2.0*cmult(z, zd) + vec2(1.0, 0.0);
        z = cmult(z, z) + c;
    }
    
    float d = 0.5*length(z)*log(length(z))/length(zd);
    return d;
}

void main(void)
{
    vec2 offset = vec2(-0.749, 0.101);
    float scale = 1.0/pow((0.01*float(time*60)), 3.0);
    //float scale = 1.0/pow((0.01*float(frames)), 3.0);
    vec2 uv = scale*(2.0*gl_FragCoord.xy - resolution.xy) / resolution.y + offset;
    
    float d = mandelbrot(uv);
    float color = clamp(8.0*d/scale, 0.0, 1.0);
    color = pow(color, 0.2);
    
    glFragColor = vec4(vec3(color), 1.0);
}
