#version 420

// original https://www.shadertoy.com/view/7dfGWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653589793
float PHI=1.61803398874989484820459;// Φ = Golden Ratio

float random(in vec2 xy,in float seed){
    float f=length(fract((cross((cross(fract(xy.yxy*PHI*seed)+seed,fract(xy.xyx/seed)+seed)*PHI),vec3(5./PHI,7./PHI,3./PHI)))));
    return fract(f*seed);
}

float noise(vec2 st){
    vec2 st0=floor(st);
    vec2 st1=.5-cos((st-st0)*PI)*.5;
    float a0=random(vec2(int(st0.x),int(st0.y)),1.);
    float a1=random(vec2(int(st0.x)+1,int(st0.y)),1.);
    
    float a2=random(vec2(int(st0.x),int(st0.y)+1),1.);
    float a3=random(vec2(int(st0.x)+1,int(st0.y)+1),1.);
    
    float b0=(a1-a0)*st1.x+a0;
    
    float b1=(a3-a2)*st1.x+a2;
    return(b1-b0)*st1.y+b0;
}

float LineHeight(vec2 uv){
    return noise(uv);
}
#define lines 20.
#define height 0.5
#define edges 0.1
#define horizontalEdges 0.05

bool HitsLines(vec2 uv,float vOffset){
    if(uv.x < horizontalEdges || uv.x > 1.-horizontalEdges)
        return false;
    uv.x = uv.x * (1.-horizontalEdges*2.) + horizontalEdges;
    for(float i=lines;i >= 0.;i--){
        vec2 nuv = uv + vec2(0,((i + 0.5)/(lines)-1.) * (1.-edges*2.) - edges);
        vec2 check = vec2(uv.x* 20. + time * (abs(lines/2.-i) * -0.25 + 1.125),i * 10.);
        float h = (LineHeight(check + vec2(0,vOffset))-0.5) * height * (1.-pow(abs(2.*(uv.x - 0.5)) + 0.15,0.25));
        if(h > nuv.y)
            return false;
        if(h < nuv.y && h > nuv.y - 0.004)
            return true;
    }
    return false;
}
void main(void) {
    float r = (HitsLines(gl_FragCoord.xy/resolution.xy, 0.25))?0.5:0.;
    float g = (HitsLines(gl_FragCoord.xy/resolution.xy, -0.25))?0.5:0.;
    float b = (HitsLines(gl_FragCoord.xy/resolution.xy, -0.5))?0.5:0.;
    glFragColor=(HitsLines(gl_FragCoord.xy/resolution.xy,0.))?vec4(1,1,1,1):vec4(r,g,b,1);
}
