#version 420

// original https://www.shadertoy.com/view/wlKBWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Evan Nave 2021
// Iterative Functions in GLSL: https://www.shadertoy.com/view/MtBGDW
// 'Mythic Bird' Graph: http://www.atomosyd.net/spip.php?article98
#define SCALE 20.0
#define ITERATION 80
#define PI 3.14159265359

float g(float x, float u){
    return u*x + ((2.*(1. - u)*pow(x, 2.)) / (1. + pow(x, 2.)));
}

//Mythic Bird
vec2 mythicEQ(vec2 c,float t){
    vec4 z = vec4(c.x*1.6, -c.y, 0.0, 0.0);
    vec3 zi = vec3(0.0);
    vec4 ms = vec4(0.0);//mouse*resolution.xy / resolution.x;
    
    float a = 0.0009;
    float b = 0.005 - 0.5;
    float u = -0.801;
    
    //Animation
    u += cos(t*0.1 + 15.7)*0.25 + 0.25;
    
    if(ms.z > 0.0){ u =  -0.801 + cos(ms.x*PI*2.0 + 15.7 + PI)*0.25 + 0.25; }
    
    float m = -3.5;
    
    for(int i=0; i<ITERATION; i++){
        zi.x = z.y + g(z.x, u) + a*z.y*(1. - b*pow(z.y, 2.) + m);
        zi.y = -z.x + g(zi.x, u);
        if(length(zi.xy)>80.0)break;
        z.w++;
        z.xyz=zi;
    }
    z.w/=float(ITERATION);
    return 1.0-z.wx;
}

mat2 rotate2D(float x){
    return mat2(cos(x), -sin(x), sin(x), cos(x));
}

void main(void) {
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    float rt = -time*0.1 + 0.5;
    
    //Grid UVs and offset correction for Mythic Bird rotation
    vec2 gv = fract(uv*2.0*rotate2D(rt)) -0.5;
    vec2 rc = vec2(cos(rt)*0.1, sin(rt)*0.1);
    
    //Mythic Bird
    float mb = mythicEQ(rotate2D(rt)*(uv + rc)*SCALE,time).x;
    
    mb = 1.0 - mb;
    mb = smoothstep(0.00, 1., mb);
    mb = pow(mb, 1.0);
    mb *= 1.0 - length(uv*0.9) + mb*0.5;
    
    col = vec3(mb*0.1, mb*0.5, mb*0.9);
    
    //Radial Mask
    float cm = length(uv) + 0.1 - 0.2*mb/0.005;
    cm = smoothstep(0., 3., cm);
    col = mix(col, vec3(0.1, 0.5, 0.5), cm + 0.2 - mb*mb);
    
    //Dots to make it pretty
    float circles = 1.0 - smoothstep(0., 0.02, length(gv) - 0.2 + (1.0 - length(uv*0.6)) - 0.2);
    col = mix(col, col*1.1, circles);
    
    //Gamma
    col = pow(col, vec3(0.64545));
    
    glFragColor = vec4(col, 1.0);
}
