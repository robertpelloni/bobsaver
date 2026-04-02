#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MtBfWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_CIRCLES 16

float aspectScreen = 1.0;
vec2  pixels = vec2(0.0, 0.0);
float radTime = 0.0;

vec3 circle (vec2 center, float radio, vec3 color){

    vec2 pos = pixels - center;
    pos.y *= aspectScreen; 
        
    color *= smoothstep (radio+0.001, radio, length(pos));
    return color;

}

void main(void)
{
    pixels = gl_FragCoord.xy / resolution.xy;
    aspectScreen = resolution.y / resolution.x;
    radTime = (3.14159 * time )/ 180.0;
    
    radTime *=80.0; // Rotaion Velocity

    vec3 color;
    vec2 circlePos[MAX_CIRCLES];

    // Circles declaration
    float sizeSin = 0.07 * sin(time) + 0.1;
    float sizeCos = 0.05 * cos(time) + 0.1;
    
    // Position of circles
    float phase = 0.0; // In radians
    for (int i=0; i< MAX_CIRCLES; i++){
        circlePos[i] = vec2 (aspectScreen * 0.25*sin(radTime+phase)+0.5,
                             0.25*cos(radTime+phase) + 0.5);
        phase = float(i+1) * (3.14159 * 2.0) / float(MAX_CIRCLES);
    }
    // Color Construction
    color  = vec3(0.0,0.0,0.0); // Black Background
    for (int i=0; i< MAX_CIRCLES; i++){
        float blueColor = float(i) * 0.1;
        float redColor = 1.0 - blueColor;
        if (color == vec3 (0.0,0.0,0.0)){ // Protection for no add Blending
            if (i % 2 == 0){
                color += circle(circlePos[i], 0.4*sizeCos, vec3 (redColor,1.0,blueColor));
            }else{
                   color += circle(circlePos[i], 0.4*sizeSin, vec3 (redColor,0.0,blueColor));
            }
        }
    }
    glFragColor = vec4(color,1.0);
}
