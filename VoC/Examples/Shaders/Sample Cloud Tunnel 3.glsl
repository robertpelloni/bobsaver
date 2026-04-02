#version 420

// original https://www.shadertoy.com/view/tdGBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Using code from

//Morgan McGuire for the noise function
// https://www.shadertoy.com/view/4dS3Wd

#define time time
#define depth 70.0
#define fogSize 25.0
float fogCoef=1.0/(depth-fogSize);
float PI=acos(-1.0);

float random (in float x) {
    return fract(sin(x)*1e4);
}

float noise(in vec3 p) {
    const vec3 step = vec3(110.0, 241.0, 171.0);

    vec3 i = floor(p);
    vec3 f = fract(p);

    // For performance, compute the base input to a
    // 1D random from the integer part of the
    // argument and the incremental change to the
    // 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix( mix(mix(random(n + dot(step, vec3(0,0,0))),
    random(n + dot(step, vec3(1,0,0))),
    u.x),
    mix(random(n + dot(step, vec3(0,1,0))),
    random(n + dot(step, vec3(1,1,0))),
    u.x),
    u.y),
    mix(mix(random(n + dot(step, vec3(0,0,1))),
    random(n + dot(step, vec3(1,0,1))),
    u.x),
    mix(random(n + dot(step, vec3(0,1,1))),
    random(n + dot(step, vec3(1,1,1))),
    u.x),
    u.y),
    u.z);
}

mat2 rot(float a) {
    float ca=cos(a);
    float sa=sin(a);
    return mat2(ca,sa,-sa,ca);
}

float cloud(in vec3 p, vec3 centerPos, float scale,float radius ) {
    float l = length(p*0.1);
    vec3 d = vec3(p.x+sin(l+time)*2.0,p.y+sin(l)*2.0,0.0);
    float coef = max(length(d)-1.5,0.0);
    float c=1.0;
    float n1=1.0;
    for(int i=0; i<8; ++i) {
        n1+=1.0/c*abs(noise((p*c+time*1.0)*scale));
        c*=2.0;
    }
    return n1+(coef);
}

float mapHyper(vec3 p){
    return cloud(p,vec3(0,0,0),0.5,0.1);
}  

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    vec3 s=vec3(0.5,0.5,100);
    float t2=(time*1.5);
    s.xz *= rot(sin(t2)*0.005);
    vec3 t=vec3(0,0,0);
    s.x += cos(t2*0.2)*0.10*sin(time*0.01);
    s.y += sin(t2*0.2)*0.10*sin(time*0.01+10.0);
    vec3 cz=normalize(t-s);
    vec3 cx=normalize(cross(cz,vec3(0,1,0)));
    vec3 cy=normalize(cross(cz,cx));
    vec3 r=normalize(uv.x*cx+uv.y*cy+cz*0.7);
    s.z+=time*-8.0;
    
    vec3 p=s;
    float d;
    float seuil=5.1;
    float c= 0.0;
    float distMax =50.0;
    float steps = 300.0;
    float color = 0.0;
    float cl;
    float dist = clamp((1.0-dot(vec3(0,0,-1.0),r))*4.0,0.0,1.0);
    int cc =int(mix(300.0,1000.0,dist));
    float uu =mix(1.0,0.25,dist);
    vec3 p3 = vec3(0);
    for(int i=0; i<cc; ++i) {
        float d2 ;
        float d;
        if(color<0.001)d = mapHyper(p);
        c =d;  
        if( c>seuil )
        {vec3 p2 =p;
            if(p3.x==0.0)p3=p;
            for(int j;j<20;j++)
            {
                if(color<0.2)d2= mapHyper(p2);
                else
                d2 = 5.2;
                if(d2>seuil)
                {
                    color = color*0.8 + d2*0.02*0.2;
                }
                p2 +=normalize(vec3(-0.0,-0.0,-5.0))*0.42;
            } 
        }
        cl = 1.0-color;
        p+=r*distMax/steps*uu;
        //p+=r*distMax/float(cc)*uu;
    }

    vec2 off=vec2(1.1,0.0);
    vec3 n=normalize(mapHyper(p3)-vec3(mapHyper(p3-off.xyy), mapHyper(p3-off.yxy), mapHyper(p3-off.yyx)));

    //compositing
    vec3 col=vec3(0);
    col = mix(vec3(0.0,0.0,0.2),vec3(0.88,0.88,0.9),max(cl-0.5,0.0)*2.0);
    float fog =  clamp((length(p3-s)-fogSize)*fogCoef,0.0,1.0);
    col = mix(col,vec3(0.88,0.88,0.9),fog);
    glFragColor = vec4(col,1.0);
}
