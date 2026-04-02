#version 420

// original https://neort.io/art/c1893tk3p9f8fetmtbkg

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
float lpNorm(vec3 p, float n)
{
    p = pow(abs(p), vec3(n));
    return pow(p.x+p.y+p.z, 1.0/n);
}
float scale;
float map(vec3 p)
{
    p+=vec3(1,1,time*0.2);
    float s=3.;
    for(int i=0;i<9;i++) {
        p=mod(p-1.,2.)-1.;
        float r=1.53/dot(p,p);
        p*=r;
        s*=r;
    }
    scale=s;
    return dot(abs(p),normalize(vec3(0,1,1)))/s;
}
void main(){
    vec4 display = vec4(0.0);
    vec2 uv=(gl_FragCoord.xy-.5*resolution)/resolution.y;
    vec3 rd=normalize(vec3(uv,1));
    vec3 p=vec3(0,0,-10);
    float d=1.,ix;
    for(int i=0;i<99;i++){
      p+=rd*(d=map(p));
      ix++;
      if (d<.001){break;}
    }
    if(d<.001) {
      display += 9./ix;
      display += normalize(vec4(0,100,60,0))*9./ix;
    }
    display.w=1.;
    glFragColor = display;
}
