#version 420

// original https://www.shadertoy.com/view/fsSXRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 m(float a){
    float s=sin(a);
    float c=cos(a);
    return mat2(c,s,-s,c);
}

float hash(float n){
    return fract(sin(n)*43758.5453);
}

float noise(in vec3 x){
    vec3 p=floor(x);
    vec3 f=fract(x);

    f=f*f*(3.0-2.0*f);

    float n=p.x+p.y*57.0+113.0*p.z;

    float res=mix(mix(mix(hash(n+0.0),hash(n+1.0),f.x),
            mix(hash(n+57.0),hash(n+58.0),f.x),f.y),
            mix(mix(hash(n+113.0),hash(n+114.0),f.x),
            mix(hash(n+170.0),hash(n+171.0),f.x),f.y),f.z);

    return res;
}

float fbm(vec3 p){
    float f;
    f=0.500000*noise(p);
    p.xy*=m(time)*2.02;
    f+=0.25000*noise(p);
    p.yz*=m(time)*2.03;
    f+=0.1250*noise(p);
    return f;
}

float scene(vec3 p){
    return 0.1-length(p)*0.05+fbm(p*0.3);
}

void main(void) {
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro=vec3(0.0,0.0,-30.0);
    vec3 ta=vec3(0.0);
    vec3 ww=normalize(ta-ro);
    vec3 uu=normalize(cross(vec3(0.0,1.0,0.0),ww));
    vec3 vv=normalize(cross(ww,uu));
    vec3 dir=normalize(uv.x*uu+uv.y*vv+1.5*ww);
    vec4 color=vec4(0.0);

    const int nbSample=64;
    const int nbSampleLight=6;

    float zMax=40.0;
    float step=zMax/float(nbSample);
    float zMaxl=20.0;
    float stepl=zMaxl/float(nbSampleLight);
    vec3 p=ro;
    float t=1.0;
    float absorption=100.0;
    vec3 sun_direction=normalize(vec3(0.0,1.0,0.0));

    for(int i=0;i<nbSample;i++)
    {
        float density=scene(p);
        if(density>0.0)
        {
            float tmp=density/float(nbSample);
            t*=1.0-tmp*absorption;
            if(t<=0.01)
                break;

                float tl=1.0;
                for(int j=0;j<nbSampleLight;j++){
                    float densityLight=scene(p+normalize(sun_direction)*float(j)*stepl);
                    if(densityLight>0.0)
                        tl*=1.0-densityLight*absorption/float(nbSample);
                    if(tl<=0.01)
                        break;
                }

                color+=vec4(0.1)*tmp+vec4(0.7,0.0,1.0,1.0)*80.0*tmp*t;
            }
            p+=dir*step;
        }
        glFragColor=color;
}
