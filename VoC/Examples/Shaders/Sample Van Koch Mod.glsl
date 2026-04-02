#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wsVGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MOD

void main(void)
{

    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    const float reapeat = log2(9.);
    float zoomf = time;
    float zoom = 2.*exp2(max(-zoomf,-mod(zoomf,reapeat)-reapeat));
    uv*=zoom;
    vec3 col =vec3(0);
    vec2 n = normalize(vec2(2.*sqrt(.75),-1));
    uv.y-=sqrt(.75);
    uv.x=abs(uv.x);
    if(dot(uv-vec2(1.5,0),n.yx)<0.){
    //col.r++;
    uv = reflect(uv-vec2(1.5,0),n.yx)+vec2(1.5,0);
    }
    
    float k = 1.;
    int it = 10;
    for(int i = 0;i<it;i++){
        uv.x=abs(uv.x)-.5;
        #ifdef MOD
        vec2 ni = i%2==0?n*vec2(1,-1):n;
        #else
        vec2 ni=n;
        #endif
        if(dot(uv,ni)<0.)
        uv = reflect(uv,ni);

        uv*=3.;
        uv.x-=1.5;
        k*=1./3.;
    }
    uv.x+=1.5;
    k*=3.;
    uv/=3.;
    
    float d = distance(uv,vec2(clamp(uv.x,-0.,1.),0.))*k/zoom;
    
    col+=mix(vec3(0,0,1),vec3(1,0,0),sign(uv.y)*.5+.5);
    col-= smoothstep(3./resolution.y,0.,d);

    glFragColor = vec4(col,1.0);
}
