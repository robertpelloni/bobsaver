#version 420

// original https://www.shadertoy.com/view/ldVfWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float heart2D( vec2 uv){
    uv *= 0.5;
    uv.x = abs(uv.x);
    uv.y = -0.15 -uv.y*1.2 + uv.x*(1.0-uv.x);
    float c= length(uv)-0.5;
    return c;
}

vec2 animate( vec2 uv, float speed){
    float tt = mod(time,1.5)/1.5;
    float ss = pow(tt,.2)*0.5 + 0.5;
    ss = 1.0 + ss*speed*sin(tt*6.2831*3.0 + uv.y*0.5)*exp(-tt*4.0);
    uv *= vec2(0.5,1.5) + ss*vec2(0.5,-0.5);
    return uv;
}

void main(void) {
    
    vec2 P = 5. * (gl_FragCoord.xy - resolution.xy / 2.) / min(resolution.x, resolution.y); //uv
     float s=1.5; // speed of the animated heart
    
    vec2 uv = animate(P,s);
    float d = heart2D(uv);
    vec3 col = 0.9 + sin(time+P.xyx+vec3(0,2,4));

    glFragColor = vec4(mix(col, vec3(1.), clamp(d / 0.04, 0.4, 1.0)),1.0);
    
}
