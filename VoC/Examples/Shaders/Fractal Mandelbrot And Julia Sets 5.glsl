#version 420

// original https://www.shadertoy.com/view/wscGz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 2
#define MAX_ITER 1024

vec3 colorf(float n) {
    float m = 5.0*sin(0.1*(n-6.0))+n;
    return vec3(
        pow(sin(0.05*(m-8.0)),6.0),
        pow(sin(0.05*(m+1.0)),4.0),
        (0.8*pow(sin(0.05*(m+2.0)),2.0)+0.2)*(1.0-pow(abs(sin(0.05*(m-14.0))),12.0))
    );
}

vec3 Iter(vec2 z, vec2 c)
{
    for (int i=0;i<MAX_ITER;i++){
        z = vec2(z.x*z.x-z.y*z.y, 2.0*z.x*z.y)+c;
        float h = dot(z,z);
        if (h>1.8447e+19){
            float n = float(i)-log2(0.5*log2(h))+4.0;
            return colorf(n);
        }
    }
    return vec3(0.0);
}

void main(void)
{
    float d = length(resolution);
    float m = 7.0/d, s = 0.06*d;
    vec2 b = resolution.xy-sqrt(resolution.xy*vec2(s));
    
    vec2 c = abs(asin(sin(0.017*time)))*vec2(cos(time)-0.4,0.8*sin(time));
    
    vec3 col=vec3(0,0,0);
    for (int u=0;u<AA;u++){
        for (int v=0;v<AA;v++){
            vec2 p = gl_FragCoord.xy+vec2(u,v)/float(AA);
            float sd = max(b.x-p.x,b.y-p.y);
            if (abs(sd)<0.04*s)  // red border
                col+=vec3(1.0,0.0,0.0);
            else if (sd<0.0){  // Mandelbrot
                p = 2.75*(p-b);
                vec2 z = (p-0.5*resolution.xy)*m;
                if (length(z-c)<0.06) col+=vec3(1.0,0.0,0.0);  // red dot
                else col += Iter(vec2(0.0),z);
            }
            else{  // Julia
                vec2 z = (p-0.5*resolution.xy)*m;
                col += Iter(z, c);
            }
        }
    }
    col/=float(AA*AA);
    glFragColor=vec4(col,1.0);
}
