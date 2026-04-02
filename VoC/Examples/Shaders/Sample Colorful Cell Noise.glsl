#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dsXWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

void main(void) {

    vec2 U = gl_FragCoord.xy;

    float t = time/3.0;
    //float t2 = PI*(floor(t/5.0) + cubicInOut(fract(t/5.0)));
    
    vec2 R = resolution.xy;
    vec2 uv = 1.25*(U-0.5*R)/R.y;
    
    //uv *= 1.2 + 0.4*sin(t2);
    
    //float angle = t2;
    
    //uv *= mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    uv *= 5.0;
    
    vec2 id = floor(uv);
    vec2 gv = fract(uv);

    vec3 col = vec3(0);
    
    float mD = 10.0;
    
    vec2 thisPoint = random2(id);
    
    vec2 cellID = vec2(0,0);
    
    for (int k = 0; k < 25; k++) {
        vec2 offs = vec2(k%5-2,k/5-2);
        
        vec2 neighborPos = random2(id+offs)+offs;
        
        neighborPos += cos(2.0*t + 6.2831*neighborPos);

        vec2 diff = gv-neighborPos;
        
        float d = length(diff);
        
        if (mD > d) {
            mD = d;
            cellID = fract(neighborPos);
        }
    }
    
    vec3 colorGrad = 1.5*vec3(smoothstep(-5.,5.,uv.x),
                          0,
                          smoothstep(5.,-5.,uv.x)); 

    vec3 cellGrad = vec3(0,sin(PI*cellID.y),0);
    
    vec3 mixStuff = colorGrad;
    
    vec3 mixed = mix(cellGrad, colorGrad, colorGrad); 
    
    
    col += smoothstep(1.5,0.,mD)*mixed;
    
    glFragColor = vec4(col,1.0);
}
