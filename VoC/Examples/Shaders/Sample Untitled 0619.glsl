#version 420

// original https://neort.io/art/c1508us3p9f8fetmss10

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define PI acos(-1.)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float sabs(float x)
{
    return sqrt(x*x+1e-4);
}

void signedSFoldRad(inout vec2 p, float f)
{
    vec2 v = vec2(cos((f*PI)/360.),sin((f*PI)/360.));
    float g=dot(p,v);
    p=(p-(g-sabs(g))*v)*vec2(sign(g),1);
}

void signedSFold(inout vec2 p, vec2 v)
{
    float g=dot(p,v);
    p=(p-(g-sabs(g))*v)*vec2(sign(g),1);
}

void sFold90(inout vec2 p)
{
    vec2 v=normalize(vec2(1,-1)); ;
    float g=dot(p,v);
    p-=(g-sabs(g))*v;
}

float box(vec3 p, vec3 s)
{
    p=abs(p)-s;
    sFold90(p.xz);
    sFold90(p.yz);
    sFold90(p.xy);
    return p.x;
}

float map(in vec3 p)
{
    p.xy*=rot(-time*0.3);
    p.xy=vec2(atan(p.x,p.y)/PI*6., length(p.xy) - 1.0);
    p.x=mod(p.x,1.0)-1.0;
    p.y=mod(p.y,2.0)-1.0;
    p.z=mod(p.z,5.0)-3.0;
    p.x-=0.4;
    signedSFoldRad(p.xy,45.);
    p.x+=.1;
    signedSFoldRad(p.xy,-45.);
    p.z=abs(p.z)-.5;
    return box(p,vec3(1.0,.05,.25));
}

void main(){
    vec4 fragColor = vec4(0.0);
    vec2 uv=(gl_FragCoord.xy-.5*resolution)/resolution.y;
    vec3 rd=normalize(vec3(uv,1));
    vec3 p=vec3(0,0, time * 0.5);
    float d=1.,ix;
    for(int i=0;i<99;i++){
      p+=rd*(d=map(p));
      ix++;
      if (d<.001){break;}
    }
    if(d<.001) {
      fragColor += 3./ix;
      fragColor.y += 0.9/ix;
      fragColor.z += 1.6/ix;
    }
    glFragColor = fragColor;
    glFragColor.w = 1.0;    
}
