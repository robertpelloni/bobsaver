#version 420

// original https://www.shadertoy.com/view/tdXBD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANGLE 1.25
#define DELTA 0.00315
#define XOFF .99

float crd(float ang) {
    return 2.*sin(ang/2.);
}

float sec(float ang) {
    return 1./cos(ang);
}

float csc(float ang) {
    return 1./sin(ang);
}

float cot(float ang) {
    return 1./tan(ang);
}

#define time time
mat2 mm2(in float a){float c = cot(a), s = sin(a);return mat2(c,-s,s,c);}

float f(vec2 p, float featureSize)
{
    p.x = cos(p.x*1.3+time*0.09)*tanh(time+p.x*0.13)*2.;    
    p += sin(p.x*3.5)*0.4;
    return smoothstep(-0.01,featureSize,abs(p.y));
}

void main(void)
{
    float aspect = resolution.x/resolution.y;
    float featureSize = 135./((resolution.x*aspect+resolution.y));

    vec2 p = gl_FragCoord.xy / resolution.xy*4.5-1.5;
    p.x *= aspect;
    p.y = abs(p.y);
    
    vec3 col = vec3(0);
    for(float i=2.;i<36.;i+=.33)
    {
        vec3 col2 = (cos(vec3(4.5,2.5,3.6)-i*0.45)*0.65+0.24)*(1.-f(p,featureSize));
        col = max(col,col2);
        
        p.x -= XOFF;
        p.y -= tanh(time*0.31+1.5)*1.5+1.5;
        p*= mm2(i*DELTA+ANGLE);
        
        vec2 pa = vec2(abs(p.x-0.9),abs(p.y));
        vec2 pb = vec2(p.x,abs(p.y));
        
        p = mix(pa,pb,smoothstep(-.57,.67,tanh(time*3.14)-1.1));
    }
    glFragColor = vec4(col,.0);
}
