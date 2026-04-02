#version 420

// original https://www.shadertoy.com/view/ttdyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float SEED=345.145334;
const float BUBBLE_COUNT=81.;

float random(float i){
    return fract(sin(dot(vec2(i,i-SEED),vec2(i+12.2468,52.2455))));
}

float circle(vec2 pos,float radius){
    return length(pos)-radius;
}

void main(void) {
    vec2 uv=gl_FragCoord.xy*2./resolution.xy-1.;
    uv.x*=resolution.x/resolution.y;
    
    float d=circle(uv,.0);
    for(float i=0.;i<BUBBLE_COUNT;i+=1.){
        vec2 firstOff=vec2(random(i+SEED*.02),random(i+SEED*.05))-.5;
        vec2 off=firstOff*sin(time*random(i+SEED)+random(i+SEED*.1))*random(i+SEED*1.5)*4.;
        float dTemp=circle(uv+off,random(i+SEED)*.19);
        d=min(d,dTemp);
    }
    d=abs(d);
    float finalCirc=.005/d;
    
    vec2 uvCol=vec2(cos(time*.2)*.5+.5)+uv;
    
    vec3 col=vec3(uvCol,.5);
    col*=finalCirc;
    vec3 foreGround=vec3(.1216,.502,1.);
    col+=foreGround*.1*-uv.y;
    
    glFragColor=vec4(col,1.);
}
