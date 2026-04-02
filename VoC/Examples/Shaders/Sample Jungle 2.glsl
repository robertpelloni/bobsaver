#version 420

// original https://www.shadertoy.com/view/3l2cDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float hash(float x){
    return fract(sin(x*234.123+156.2));
}

float lpNorm(vec3 p, float n)
{
    p = pow(abs(p), vec3(n));
    return pow(p.x+p.y+p.z, 1.0/n);
}

float map(vec3 p){
    vec2 id=floor(p.xz);
    p.xz=mod(p.xz,1.)-.5;
    p.y=abs(p.y)-.5;
    p.y=abs(p.y)-.5;
       p.xy*=rot(hash(dot(id,vec2(12.3,46.7))));
    p.yz*=rot(hash(dot(id,vec2(32.9,76.2))));
       float s = 1.;
    for(int i = 0; i < 6; i++) {
        float r2=1.2/pow(lpNorm(p.xyz, 5.0),1.5);
        p-=.1;
        p*=r2;
        s*=r2;
        p=p-2.*round(p/2.);
    }
    return .6*dot(abs(p),normalize(vec3(1,2,3)))/s-.002;
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<200;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001) return t;
        if (t>=far) return far;
    }
    return far;
}

float calcShadow( vec3 light, vec3 ld, float len ) {
    float depth = march( light, ld, 0.0, len );    
    return step( len - depth, 0.01 );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy* 2.0 - resolution.xy) / resolution.y;
    vec3 p,
          ro=vec3(2.-time*.2,1.8,-time*.3),
          w=normalize(vec3(.0,-1.2,-1)),
          u=normalize(cross(w,vec3(0,1,0))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,1));
    vec3 col;
    vec3 bg=mix(vec3(.15,.05,.05),vec3(.1,.1,.4),uv.y*.5+.5);
    float maxd=20.0, t=march(ro,rd,0.0,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=vec3(0.2,0.9,0.2)+cos(p*0.5)*0.5+0.5;
        vec3 n = calcNormal(p);      
        vec3 lightPos=vec3(3);
        vec3 li = lightPos - p;
        float len = length( li );
        li /= len;
        float dif = clamp(dot(n, li), 0.0, 1.0);
        float sha = calcShadow( lightPos, -li, len );
        col *= max(sha*dif, 0.2);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
        float frn = rimd+2.2*(1.0-rimd);
        col *= frn*0.8;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += vec3(0.7,0.4,0.5)*pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 20.0);
    }
    col=mix(bg,col,exp(-t*.2));
    glFragColor.xyz = mix(bg,col,exp(-t*.2));
}
