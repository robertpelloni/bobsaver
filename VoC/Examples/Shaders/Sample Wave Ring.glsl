#version 420

// original https://www.shadertoy.com/view/sdf3Df

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define WAVE_SPEED .7

float random11(float t){
    return fract(t*12575.825)*2521.5;
}

vec2 random22(vec2 c_){
    float x = fract(sin(dot(c_, vec2(75.8,48.6)))*1e5);
    float y = fract(sin(dot(c_, vec2(85.8,108.6)))*1e5);
    return vec2(x,y)*2.-1.;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float noise(vec2 coord){
    vec2 i = floor(coord);
    vec2 f = fract(coord);
    
    f = f*f*f*(f*(f*6.-15.)+10.); 
    
    float returnVal = mix(    mix( dot(random22(i), coord-i), 
                                 dot(random22(i+vec2(1., 0.)), coord-(i+vec2(1., 0.))), 
                                 f.x),
                            mix( dot(random22(i+vec2(0., 1.)), coord-(i+vec2(0., 1.))), 
                                 dot(random22(i+vec2(1., 1.)), coord-(i+vec2(1., 1.))), 
                                 f.x),
                              f.y);

    return returnVal; //-1 ~ 1
}

vec2 noiseVec2(vec2 coord){
    coord += time*WAVE_SPEED;
    
    // -1 ~ 1
    return vec2( noise((coord+vec2(10.550,71.510))), 
                noise((coord+vec2(-710.410,150.650))));
}

float ring(vec2 p, float size){
    float radius = 5.;
    float brightness = 0.648;
    float t = random11(size);
    float r = 1./(radius*abs(size*length(p)-0.632));
    
    return r*brightness;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv *= 8.;
    uv +=  noiseVec2(uv*-0.520);
    
    float size = sin(time)*.2+0.6;    
    float depth = sin(size*.06)*1.5+1.5;
    float r = ring(uv-4., size)*depth;

    vec3 bgcol = vec3(0.01);
    vec3 ring_col = vec3(0.049,0.114,0.265);
    vec3 col = mix(bgcol, ring_col, r);
    glFragColor = vec4(col,1.0);
}
