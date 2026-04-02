#version 420

// original https://www.shadertoy.com/view/wdsXRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define POINT_N 60

struct Point {
    vec2 position;
    vec3 colour;
};
    
vec4 dither(vec3 col, vec2 frag, int depth){    
    float cols = float(depth);
    float val = 0;//texture(iChannel0, mod(frag / 8., 1.)).r;
    return vec4((floor((col.rgb + val * (1. / cols)) * cols) / cols), 1.0);
}    

float noise(vec2 p){
    return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453);
}

// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float line(vec2 p, vec2 a, vec2 b, float t){
    vec2 m = vec2(a + b) / 2.;
    a = vec2(-(a.y - m.y), a.x - m.x) + m;
    b = vec2(-(b.y - m.y), b.x - m.x) + m;     
    float dst = abs((b.y - a.y) * p.x - (b.x - a.x) * p.y + (b.x * a.y) - (b.y * a.x)) / distance(a, b);
    return smoothstep(0., t * 1.5, dst);                          
}

void main(void)
{
    Point point[POINT_N];
    float t = time* 6.28318530718 / 2.5;
    float ratio = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= ratio;
    uv -= .5;  
    
    for (int i = 0; i < POINT_N; ++i) {
        point[i].position = vec2(noise(vec2(float(i))) * ratio + sin(float(i) * .1 + t) * .1,
                                 noise(vec2(float(i + 2))) + cos(float(i + 15) * .1 + t * .5) * .1
                                ) - .5;
        point[i].position.x += sin(point[i].position.x + t * .5) * .25;  
        point[i].colour =  hsv2rgb(vec3(noise(vec2(float(i))),
                                .5,
                                1.));                              
    }
       
    /*
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse.x *= resolution.x / resolution.y;
    mouse -= .5;
    point[POINT_N - 1].position = mouse;
    */
    
    int closestIndex = 0;
    float closestDistance = 999999.; 
    
    for (int i = 0; i < POINT_N; ++i) {
        float d = distance(uv, point[i].position);
        if (d < closestDistance){                
            closestIndex = i;             
            closestDistance = d;             
        }
    }

    glFragColor = vec4(point[closestIndex].colour, 1.) * (1. - .05 * pow(1. + closestDistance, 8.));
    float thickness = min(dFdx(uv.x), dFdy(uv.y));
    for (int i = 0; i < POINT_N; ++i) {
        glFragColor *= smoothstep(.005, .01, distance(uv, point[i].position));
        if (i != closestIndex) glFragColor *= line(uv, point[closestIndex].position, point[i].position, thickness);
    }
    glFragColor = dither(glFragColor.rgb, gl_FragCoord.xy, 255);
       
}
