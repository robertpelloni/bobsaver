#version 420

// original https://www.shadertoy.com/view/XtscRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define c30 0.86602540378
#define grid 15.0
#define timeScale 1.
#define rt (timeScale * time)
#define PI      3.14159265359

void main(void)
{
    vec2 st = (gl_FragCoord.xy -0.5 * resolution.xy)/ resolution.y;
    float a = (atan(st.x,st.y) + PI) /PI /2.;
    float l = length(st);
    l -= abs(cos(l + rt))*sin(rt);
    
    float lin = abs(fract(cos(a * PI*8.0 ) + cos(l*10.)*0.3) - 0.5) * 2.0;
    
    float f = smoothstep(0.5,-0.5,lin -pow((cos(fract(l*3.0 + rt)*3. + 5.)),5.));
    f = smoothstep(lin,0.,f);
    float f2 = smoothstep(0.5,-0.5,lin -pow((cos(fract(l*2.0 + rt)*3. + 5.)),5.));
    f2 = smoothstep(lin,0.,f2);
    float f3 = smoothstep(0.5,-0.5,lin -pow((cos(fract(l*4.0 + rt)*3. + 5.)),5.));
    f3 = smoothstep(lin,0.,f3);
    
    vec3 col = vec3(f,f2,f3);
    
    glFragColor = vec4(col,1.0);
}
