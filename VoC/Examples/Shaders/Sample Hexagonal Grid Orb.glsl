#version 420

// original https://www.shadertoy.com/view/cst3zj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hexCount 3.
#define rotSpeed 0.2
#define moveSpeed vec2(0.5, 1.)

#define palette 2

#if(palette == 1)
    #define hexCol vec3(0.25, 0.75, 0.5)
    #define glowCol vec3(0., 0.25, 0.5)
#elif(palette == 2)
    #define hexCol vec3(0.25, 0.75, 0.5)
    #define glowCol vec3(0., 0.15, 0.25)
#elif(palette == 3)
    #define hexCol vec3(0.5, 0.5, 0.)
    #define glowCol vec3(0.25, 0.15, 0.)
#elif(palette == 4)
    #define hexCol vec3(0.5, 0.5, 0.)
    #define glowCol vec3(0.5, 0.25, 0.)
#elif(palette == 5)
    #define hexCol vec3(0.5, 0.5, 0.5)
    #define glowCol vec3(0., 0., 0.25)
#else
    #define hexCol vec3(1.)
    #define glowCol vec3(1.)
#endif

vec2 gridDist(vec2 pos){
    vec2 grid = vec2(2.*sqrt(3.), 2.);
    return vec2(
        abs(pos - round(pos/grid)*grid)
    );
}

float hexDist(vec2 pos){
    vec2 d1 = gridDist(pos);
    vec2 d2 = gridDist(pos - vec2(sqrt(3.), 1.));
    
    vec2 apothem = vec2(sqrt(3.)/2., .5);
    
    return min(
        max(d1.y, dot(d1, apothem)),
        max(d2.y, dot(d2, apothem))
    );
}
float zoomFunc(float len){
    //return 0.5;
    return sqrt(1.5 - len*len);
    //return 1. + cos(len*3.1415/2.);
    //return 1. + 2.*smoothstep(1., 0.75, len);
}
void main(void)
{
    vec2 pos = (gl_FragCoord.xy*2. - resolution.xy)/resolution.y;

    float len = length(pos);

    vec2 hexCoord = pos/zoomFunc(len);
    float angle = time*rotSpeed;
    hexCoord *= mat2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle)
    );
    hexCoord = hexCoord*hexCount + moveSpeed*time;
    
    float hexDist = hexDist(hexCoord);

    float hexAmt = 0.;
    hexAmt += smoothstep(0.9, 0.95, hexDist);
    hexAmt += pow(hexDist, 5.);
    hexAmt *= smoothstep(1., 0.9, len);
    
    float glowAmt = sqrt(1. - len*len);
    
    vec3 col = hexCol*hexAmt + glowCol*glowAmt;

    glFragColor = vec4(col, 1.);
}
