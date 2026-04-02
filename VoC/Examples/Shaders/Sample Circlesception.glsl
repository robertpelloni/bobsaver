#version 420

// original https://www.shadertoy.com/view/XlsyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define c30 0.86602540378
#define grid 150.0
#define smooth (50. / resolution.x)
#define timeScale 4.
#define rt      ((time+400.0) * timeScale)
#define PI      3.14159265359

vec3 getCol(float v){
    float r = sin(v);
    float g = sin(v + 0.66);
    float b = sin(v + 2.);
     return vec3(r,g,b); 
}

void main(void)
{
    vec2 st = (gl_FragCoord.xy -0.5 * resolution.xy)/ resolution.x;
    
    float lf = floor(length(st) * grid + 0.5);
    float lfff = floor(lf *PI * 2.0);
    
    float ft = rt * mix(1.0,lfff /grid / 8.0,0.8);
    float cT = cos(ft);
    float sT = sin(ft);
    st = mat2(cT,-sT,sT,cT) * st;
    
    float a = atan(st.x,st.y) + PI;    
    vec3 acol = getCol(a);
    a /= PI * 2.0;
    
    float af = floor(a * lfff + 0.5)/lfff * 2.0 * PI - PI;
    
    
    vec2 nst = lf / grid * vec2(sin(af),cos(af));
    float dist = length(st - nst) * grid;
       float col = smoothstep(smooth,-smooth,dist - 0.4);

    
    
    glFragColor = vec4(mix(acol * 0.5,acol,col),1.0);
}
