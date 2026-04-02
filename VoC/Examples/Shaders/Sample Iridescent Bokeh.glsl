#version 420

// original https://www.shadertoy.com/view/fdjXWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define C_PI 3.14159265359

vec3 hash13(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec3 flower(vec2 p, float t, float id){

    vec3 r = hash13(id+floor(t)*13.);    

    float lT = fract(-t);
    float ilT = 1.-lT;
    
    lT*=lT;
    
    float fade = sin(lT*C_PI);
    fade = smoothstep(0.0,0.1,fade);
    fade*=fract(t);

    p+=vec2(r.xy-0.5)*pow(lT,.25);

    p*=lT*5.;

    float l = length(p);
    float m = smoothstep(.4,0.,l);

    float a = atan(p.y,p.x);

      
    a = sin(a*r.x*1.23  + time*0.123) * 
        sin(a*r.y*2.321 + time*0.456) *
        sin(a*r.z*1.123 + time*0.589) *
        sin(a);

    l = mix(l,a*(r.x-0.5)*3.*ilT,r.z*0.5+0.2);
    
    float s1  = smoothstep(.5,0.,l);
    float s2  = smoothstep(0.01,0.,l);
    float s = (s1-s2)*m;

    vec3 c1 =  vec3(sin(s *vec3(0.987,0.765,0.543)*C_PI*1.4));
    vec3 c2 =  vec3(sin(s2*vec3(0.13*r.x,0.865*r.y,0.943*r.z)*6.664));

    vec3 sOut = (c1*mix(c2,vec3(1.),r.y*0.5+0.5)*c1)*fade;
    

    return  sOut*l;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 s = vec3(0.);

    const float amount = 20.;
    float del = 1./amount;

    for(float i = 1.; i <= amount; i++){

     s+=flower(uv,time*0.05 + del*i,i);
    
    }

    glFragColor = vec4(pow(s*3.,vec3(0.4545)),1.);
}
