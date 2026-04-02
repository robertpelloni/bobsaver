#version 420

// original https://www.shadertoy.com/view/llyBRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//PROJECT: Daily shader practice :: Shader #004
// AUTHOR: Angel Ortiz, angelo12@vt.edu
//   DATE: 30/11/18 
//  NOTES: Learning about the different types of noise, I was fooling around with simplex
//         noise and the step function and saw a shape that reminded me of military camo
//         this could be a great way of procedurally generating camo textures given a set
//         of color palettes.

vec2 random2D(vec2 val){
    val = vec2(dot(val, vec2(127.1, 311.7)),
               dot(val, vec2(242.51, 184.2)));
    
    float scale = 182364.0;
    return 1.0 -  2.0 * fract(sin(val) * scale);
}

float random(vec2 val){
    return fract(sin(dot(vec2(123.02, 274.73), val))* 120452.0);
}

float noise(vec2 p){
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2 i = floor( p + (p.x + p.y) * K1);

    vec2 a = p - i + (i.x + i.y)*K2;
    vec2 o = step(a.yx, a.xy);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;

    vec3 h = max( 0.5 - vec3(dot(a,a), dot(b,b), dot(c,c)), 0.0);

    vec3 n = h*h*h*h*vec3(dot(a, random2D(i +0.0)), dot(b, random2D(i + o)), dot(c, random2D(i+1.0)));

    return dot(n, vec3(100.0));
}

float simplex(vec2 p, int octaves){
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);

    float f = 0.0;
    float scale = 1.0;
    for(int i = 0; i < octaves; i++){
        scale /= 2.0;
        f += scale*noise(p);
        p *= m;
    }

    return 0.5 + 0.5*f;
}

void main(void) {
    float time = time * 1.0;
    vec2 base  = gl_FragCoord.xy / resolution.y;
    vec2 cen = base - vec2(0.5);
    vec3 col = vec3(0.0);
    
    float range = 0.4 + 0.2 * ((cos(0.1*time)+ 1.0) / 2.0);
    col = vec3(0.33, 0.37 ,0.21) * step( range, simplex(base * vec2(1.5, 2.5), 3));
    if ( dot(col, vec3(1.0)) == 0.0  ){
        col += vec3(0.71, 0.65 ,0.52) * step( range - 0.1, simplex(base * vec2(1.5, 2.5), 3));
    }

    if ( dot(col, vec3(1.0)) == 0.0  ){
        col += vec3(0.32, 0.26 ,0.22) * step( range - 0.23, simplex(base * vec2(1.5, 2.5), 3));
    }

    glFragColor = vec4(col, 1.0);
}

