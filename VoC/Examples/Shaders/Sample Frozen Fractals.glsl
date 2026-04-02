#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdKXDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979
#define AA 3

int sn;     // index of snowflake

vec3 fractal(vec2 p){
    p.x=-p.x-(cos(time)+5.0)/3.0;
    vec3 col=vec3(0.0);
    vec2 z = vec2(0.0);
    int i;
    for (i=0;i<64;i++){

        // different iteration functions generate different snowflakes
        if (sn==0) z=vec2(z.x*z.x-z.y*z.y,2.0*z.x*z.y)+p;
        else if (sn==3) z=vec2(z.x*z.x-z.y*z.y,-2.0*z.x*z.y)+p;
        else if (sn==1) z=vec2(abs(z.x*z.x-z.y*z.y),2.0*z.x*z.y)+p;
        else if (sn==4) z=vec2(abs(z.x*z.x-z.y*z.y),-2.0*z.x*z.y)+p;
        else if (sn==2) z=vec2(z.x*z.x-z.y*z.y,-abs(2.0*z.x*z.y))+p;

        // color function for Mandelbrot (https://www.shadertoy.com/view/wl2SWt)
        float h = dot(z,z);
        if (h>1.8447e+19){
            float n = float(i)-log2(.5*log2(h))+4.;
            float m = exp(-n*n/20000.);
            n = mix(4.*pow((log(n+1.)+1.),2.),n,m);
            m = 5.*sin(.1*(n-6.))+n;
            col += vec3(
                pow(sin((m-8.)/20.),6.),
                pow(sin((m+1.)/20.),4.),
                (.8*pow(sin((m+2.)/20.),2.)+.2)*(1.-pow(abs(sin((m-14.)/20.)),12.))
            );
            break;
        }
    }
    if (i==64) col=vec3(1.0);
    return col;
}

void main(void)
{
    float s = 0.3*length(resolution.xy);
    vec3 col=vec3(0.0);
    sn = int(time/(2.*PI))%5;
    for (int u=0;u<AA;u++){
        for (int v=0;v<AA;v++){
            vec2 p = (gl_FragCoord.xy+vec2(u,v)/float(AA)-0.5*resolution.xy)/s;
            // rotation and mirroring
            float m = length(p);
            float a = abs(mod(atan(p.y,p.x)+time,PI/3.0)-PI/6.0);
            col += fractal(vec2(m*cos(a),m*sin(a)));
        }
    }
    glFragColor = vec4(col/float(AA*AA),1.0);
}
