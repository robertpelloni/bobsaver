#version 420

// original https://www.shadertoy.com/view/MlBGWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time*.5
#define resolution resolution.xy

vec3 ldir;
float ot;

float tree(vec2 p) {
    p=p*.72+vec2(0.,1.32);
    ot=1000.;
    for (int i=0; i<28; i++) {
        float l=dot(p,p);
        ot=min(ot,abs(l-.6));
        p.x=abs(p.x);
        p=p/l*2.-vec2(.38,.2);
  
    }
    return dot(p,p)*.02;
}

float light(vec2 p) {
    vec2 d=vec2(0.,.003);
    float d1=tree(p-d.xy)-tree(p+d.xy);
    float d2=tree(p-d.yx)-tree(p+d.yx);    
      vec3 n1=vec3(0.,d.y,d1);
      vec3 n2=vec3(d.y,0.,d2);
      vec3 n=normalize(cross(n1,n2));
      float diff=max(0.,dot(ldir,n))*.6;
    vec3 r=reflect(vec3(0.,0.,1.),ldir);
    float spec=pow(max(0.,dot(r,n)),25.)*.4;
      return (diff+spec+.15)*max(0.4,1.-tree(p));
}

void main(void)
{
    vec2 p = gl_FragCoord.xy/resolution.xy-.5;
    vec2 aspect=vec2(resolution.x/resolution.y,1.);
      p*=aspect;
    p*=1.+sin(time)*.2;
    float a=2.+cos(time*.3)*.5;
    mat2 rot=mat2(sin(a),cos(a),-cos(a),sin(a));
    p*=rot;
    p+=vec2(sin(time),cos(time))*.2;
    vec3 lightpos=vec3(sin(time*3.)*.8,cos(time)*.9,-1.);
    lightpos.xy*=aspect*.5;
    ldir=normalize(vec3(p,-tree(p))+lightpos);
      float l=light(p);
      ot=max(1.-ot*.7,0.);
    vec3 col=l*vec3(ot*ot*1.45,ot*.9,ot*ot*.55);
    col+=pow(max(0.,.2-length(p+lightpos.xy))/.2,3.)*vec3(1.2,1.1,1.);
    col*=pow(max(0.,1.-length(p+lightpos.xy)*.3),2.5);
    glFragColor = vec4(col+.03, 1.0 );
}

