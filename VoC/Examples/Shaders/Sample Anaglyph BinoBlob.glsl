#version 420

// original https://www.shadertoy.com/view/3stSR4

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Simple shader to test stereoscopic rendering
    Use glasses with red on the left eye and cyan on the right eye
*/

// put to 2 or more to get antialiasing
#define AA 1
// put to 1 to get less artifacts but more noise
#define DITHER 0

    #define time2 (time*0.2)
    #define factor 1.0

mat2 rot(float a) {
    float ca=cos(a);
    float sa=sin(a);
    return mat2(ca,sa,-sa,ca);    
}

float box(vec3 p, float s) {
    p=abs(p)-s;
    return max(p.x, max(p.y,p.z));
}

float box(vec2 p, float s) {
    p=abs(p)-s;
    return max(p.x, p.y);
}

float map(vec3 p) {
    
    float t3=time2*2.0;
    t3=pow(smoothstep(0.0,1.0,fract(t3)),10.0)+floor(t3);
    t3*=2.0;
    t3 += sin(time2*0.5)+0.5*factor;
    
    vec3 bp=p;
    
    float m=10000.0;
    for(int i=0;i<4; ++i) {
        float t=0.7+float(i) + time2*0.5;
        p.xz*=rot(t + sin(p.y * 0.075 - t3)*0.2);
        p.xy*=rot(t*0.7+sin(p.z*0.043 - t3)*0.3);
        p=abs(p);
        m=min(m, min(p.x,min(p.y,p.z)));
        p-=0.7 + sin(p.yzx*0.8 - time2*2.0)*0.4;
    }
    
    float d=m-0.0;
    d=abs(d-0.2)-0.1;
    
    float f=abs(length(p)-5.0)-0.1;
    f=min(f, abs(box(p.xz,0.5))-0.02);
    f=min(f, abs(box(p.xy,0.5))-0.02);
    f=min(f, abs(box(p.yz,0.5))-0.02);
    f=min(f, abs(box(bp,4.0))-0.1);
    d=max(d, f)-0.0;
    
     return d;   
}

float raymarch(vec3 s, vec3 r, float off) {
    float val=0.0;
    vec3 p=s;
    for(int i=0; i<80; ++i) {
         float d=abs(map(p))*off;
        if(d<0.01) {
            d=0.1;
            break;
        }
        val+=0.01/(0.8+d);
        p+=r*d;
    }
    return val;
}

#define ZERO (min(frames,0))

float rnd(vec2 uv) {
    return fract(dot(sin(uv*752.352+uv.yx*364.588), vec2(127.842)));
}

void main(void)
{
    vec3 sum=vec3(0);
    
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 uv = gl_FragCoord-resolution.xy*0.5 + o;
#else    
        vec2 uv = gl_FragCoord.xy-resolution.xy*0.5;

#endif
        
        float dither  =0.6;
        #if DITHER
            dither = 0.55+rnd(uv)*0.1;
        #endif

        //uv /= resolution.y;
        uv /= resolution.x*0.56;

        vec3 s=vec3(0,0,-25.0 + sin(time2*0.8)*0.0);
        vec3 t=vec3(0);

        float t2=time2*0.3;
        s.xz *= rot(t2+sin(time2)*0.2+0.2*factor);
        s.xy *= rot(-t2*1.2+sin(time2*0.7)*0.3);

        vec3 cz=normalize(t-s);
        vec3 cx=normalize(cross(cz, vec3(0,1,0)));
        vec3 cy=normalize(cross(cz, cx));

        float eyeoff=0.5; // distance between eyes

        float fov = 1.0;
        float dist = 20.0; // distance of focus
        vec3 rbase = uv.x*cx+uv.y*cy+fov*cz;
        vec3 r1=normalize(vec3(rbase + cx * eyeoff / dist));
        vec3 r2=normalize(vec3(rbase - cx * eyeoff / dist));

        vec3 col=vec3(0);
        col.x=raymarch(s - eyeoff * cx, r1, dither);
        col.y=raymarch(s + eyeoff * cx, r2, dither);
        col.z=col.y;

        //col *= pow(1.2-length(uv),1.0);

        col = smoothstep(0.0,1.0,col);
        col = pow(col, vec3(0.4545));

        sum += col;
#if AA>1
    }
    sum /= float(AA*AA);
#endif
    
    
    
    // Output to screen
    glFragColor = vec4(sum,1.0);
}
