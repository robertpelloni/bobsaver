#version 420

// original https://www.shadertoy.com/view/MtXfRB

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define FOV 1.0
float random (in vec3 _st) {
    return fract(sin(dot(_st.xyz,
                         vec3(12.9898,78.233,82.19)))*
        43758.5453123);
}
float noise (in vec3 _st) {
    vec3 i = floor(_st);
    vec3 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec3(1.0, 0.0,0.0));
    float c = random(i + vec3(0.0, 1.0,0.0));
    float d = random(i + vec3(1.0, 1.0,0.0));

    float e = random(i + vec3(0.0, 0.0,1.0));
    float g = random(i + vec3(1.0, 0.0,1.0));
    float h = random(i + vec3(0.0, 1.0,1.0));
    float j = random(i + vec3(1.0, 1.0,1.0));
    f = (1.0-cos(f*3.1415))/2.0;
   // f = pow(abs(f-0.5)*2.0,vec3(2.0,2.0,2.0))*0.5*sign(f-0.5)+0.5;
   // f = (1.0-cos(clamp(f*2.0,0.0,1.0)*3.1415))/4.0+(1.0-cos(clamp(f*2.0-1.0,0.0,1.0)*3.1415))/4.0;
    
    // float a1 = mix(a, b, u.x) 
     //       (c - a)* u.y * (1.0 - u.x) +
     //(d - b) * u.x * u.y;
     float a1 = mix(a,b,f.x);
     float a2 = mix(c,d,f.x);
     float a3 = mix(e,g,f.x);
     float a4 = mix(h,j,f.x);

     float a5 = mix(a1,a2,f.y);
     float a6 = mix(a3,a4,f.y);

    return mix(a5,a6,f.z);
}

float fbm ( in vec3 _st) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0,22.5,44.0);
    float r = 1.0;
    for (int i = 0; i < 4; ++i){
        v += a * noise(_st);
        r += a;
        _st =  shift + _st*2.0;
        _st = (sin(r)*_st+cos(r)*_st);
        a *= 0.5;
    }
    return v;
}
vec4 getint(vec3 cam,vec3 ray,vec3 pos,vec3 norm){
    float d = dot(pos-cam,norm)/dot(ray,norm);
    
    vec3 posa = ray* d;
    return vec4(posa,sign(d)*0.5+0.5);
    
    }
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy-0.5;
    
    vec2 mouse=vec2(0.0);
    vec2 look = (mouse*resolution.xy-mouse*resolution.xy)/resolution.xy*3.1415*2.0+3.1415;
    look=mix(vec2(3.1415),look,0.0);
    look.y=look.y*0.5+3.1415/2.0+3.4415;
    look.x = -look.x + 3.1415;
    
    //xy = mouse when clickdown
    //zw = mouse when clickfirst
    vec3 screen = vec3(0.0);//
    screen.x = uv.x;
    screen.y = -sin(look.y)*FOV+cos(look.y)*uv.y*(resolution.y/resolution.x);
    screen.z = cos(look.y)*FOV+sin(look.y)*uv.y*(resolution.y/resolution.x);
   float temp = screen.x;
    screen.x = cos(look.x)*screen.x+sin(look.x)*screen.z;
    
    screen.z = -sin(look.x)*temp+cos(look.x)*screen.z;
    
    
   
    vec3 ray = normalize(screen);
    vec3 y = vec3(0.0,0.0,0.0);
    vec3 pass = vec3(100.0);
    vec3 ye = vec3(0.0);
    float b = 0.0;
    for(float i = 0.0;i<1.0;i+=0.005){
        vec4 pos = getint(vec3(0.0,0.0,0.0),ray,vec3(0.0,-2.0+i,0.0),vec3(0.0,1.0,0.0));
        vec3 ac = vec3(pos.x,time,pos.z);
        float thy = fbm(ac);
        bool is =thy>i&&thy<i+0.1;
        
        
       // ref = i;
        if((pos.w==1.0)&&(length(pos.xyz)<length(pass.xyz))&&(is)){y=vec3(1.0);pass=pos.xyz;b=i;ye = ac;}
    }
    vec3 post = vec3(pass.x,fbm(ye),pass.z);
    vec3 aa = vec3(pass.x+0.1,fbm(ye+vec3(0.1,0.0,0.0)),pass.z);
    vec3 ab = vec3(pass.x,fbm(ye+vec3(0.0,0.0,0.1)),pass.z+0.1);
    vec3 norma = (normalize(cross(post-aa , post-ab)));
    float res = pow(max(dot(reflect(ray,norma),vec3(0.0,1.0,0.0)),0.0),100.0);
    float ref = dot(norma,vec3(0.0,-1.0,0.0));
    glFragColor = vec4(y*ref+res,1.0)*vec4(0.6,0.5,0.8,1.0);//texture(iChannel0,pass.xz);
    
}
