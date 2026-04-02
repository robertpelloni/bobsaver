#version 420

// original https://www.shadertoy.com/view/tl2fzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hash(n) fract(sin(n*234.567+123.34))

float Scale;
float g=.0;
float map(vec3 p){
    float de=10.;
    p.z-=time*1.5;
    float seed=dot(floor((p.xz+4.)/8.),vec2(123.12,234.56));   
    p.xz=mod(p.xz-4.,8.)-4.;
    p=abs(p)-2.;
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;
     if(p.x<p.y)p.xy=p.yx;
    float scale=-5.+hash(seed)*.5;
    float mr2=.45+hash(seed+123.)*.05;
    float off=1.3+hash(seed+456.)*.1;
    float s=3.;
    vec3  p0 = p;
    for (int i=0; i<9; i++){
        p=1.-abs(p-1.);
        float k=clamp(mr2*max(1.2/dot(p,p),1.),0.,1.);
        p=p*scale*k+p0*off;
        s=s*abs(scale)*k+off;
        if(i==2){
            float d=length(hash(seed+147.)<.5?p.xz:p.xy)/s-.001;
            g += 1./max(1e-4,d*d*7e5); // Distance glow by balkhan
        }
    }
    Scale=log2(s);
    return length(hash(seed+147.)>.5?p.xz:p.xy)/s-.001;
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
    for(int i=0;i<80;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001) return t;
        if (t>=far) return far;
    }
    return far;
}

float calcShadow(vec3 light, vec3 ld, float len){
    float depth = march(light,ld,0.0,len);    
    return step(len - depth, 0.01);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy* 2.0 - resolution.xy) / resolution.y;
    vec3 ro = vec3(sin(time*.3+.3*sin(time*.2)),7,8);
    vec3 ta = vec3(0,0,0);
    vec3 w = normalize(ta-ro);
    vec3 u = normalize(cross(w,normalize(vec3(0.3*sin(time*.1),1,0))));
    vec3 rd = mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    vec3 bg = vec3(0.03,0.03,0.08);
    vec3 col = bg;
    const float maxd = 80.0;
    float t = march(ro,rd,0.0,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=cos(vec3(1,3,6)+Scale*50.)*0.5+0.5;
        col*=1.8;
        vec3 n = calcNormal(p);      
        vec3 lightPos=vec3(20);
        vec3 li = lightPos - p;
        float len = length( li );
        li /= len;
        float dif = clamp(dot(n, li), 0.5, 1.0);
        float sha = calcShadow( lightPos, -li, len );
        col *= max(sha*dif, 0.4);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
        float frn = rimd+2.2*(1.0-rimd);
        col *= frn*0.9;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += vec3(0.5,0.4,0.9)*pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 50.0);
        col += vec3(0.7,0.3,0.1)*g*(1.5);
        col = mix(bg,col,exp(-t*t*.002));
        col = clamp(col,0.,1.);
        
    }
    glFragColor.xyz = col;
}
