#version 420

// original https://www.shadertoy.com/view/MsdSDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//mix from https://www.shadertoy.com/view/XsXGzn
//and https://www.shadertoy.com/view/MsBSDz

//#define LUCKY

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 col = vec3(1.0,1.0,1.0);
    float time = time*.2;

    for(int i = 20; i>0; i--)
    {     
        vec2 shape = uv - vec2(.5,.45);  
        shape.x+=cos(float(i)/3.5-time*1.3)/2.5;
        shape.y+=sin(float(i)/2.5-time*1.7)/2.5;

        vec2 sh2=shape*vec2(2.,1.2);//*2.-1.;
        float t=time*1.5;
        float lucky=1.0;
#ifdef LUCKY
        lucky=1.3;
#endif    
        float a = atan(sh2.x,sh2.y)*lucky;
        float r = length(sh2);
        float s = 0.5 + 0.5*sin(3.0*a + t);
        float g = sin(1.57+3.0*a+t);
        float d = 0.15 + 0.3*sqrt(s) + 0.15*g*g;
        float h = clamp(2.*r/d,0.0,1.0);
        float f = 1.0-smoothstep( 0.95, 1.0, h );
        h *=1.0-0.5*(1.0-h)*smoothstep(0.95+0.5*h,1.0,sin(3.0*a+t));
        col *= h;
        col.y+=.02;
        col = mix( col, 1.2*vec3(0.1*h,0.12+0.5*h,0.1), f-.01 );
    }
    glFragColor = vec4(col,1.0);
}
