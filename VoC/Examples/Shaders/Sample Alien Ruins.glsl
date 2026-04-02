#version 420

// original https://www.shadertoy.com/view/WtlSzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
const float PI = 3.1415926;
const float GOLDEN = PI*(3.-sqrt(5.));
vec2 rot(vec2 p, float a){
    return vec2(p.x*cos(a)-p.y*sin(a),p.x*sin(a)+p.y*cos(a));
}
vec2 moda(vec2 p, float m){
    float a=atan(p.y,p.x)+PI/m;
    a=mod(a-m/2.,m)-m/2.;
    return vec2(cos(a),sin(a))*length(p);
}
vec2 pmod(vec2 p, float m){
    float a=PI/m-atan(p.y,p.x);
    float r=2.*PI/m;
    a=floor(a/r)*r;
    return rot(p,a);
}
float PseudoKleinian(vec3 p)
{
    vec3 CSize = vec3(0.92436, 0.90756, 0.92436);
    float size = 1.;
    vec3 c = vec3(.0);
    float de = 1.;
    vec3 offset = vec3(.0);
     vec3 ap = p + vec3(1.);
    for(int i=0; i<10; i++)
    {
        ap = p;
        p -= 2. * clamp(p, -CSize, CSize);
        float r2 = dot(p, p);
        float k = max(size / r2, 1.);
        p *= k;
        de *= k;
        p += c;
    }
    float r = abs(0.5 * abs(p.z - offset.z) / de);
    return r;
}
float map(vec3 p){
    float d;
    vec3 q=p.yxz;
    for(int i=0;i<3;++i){
        q.xy=pmod(q.xy,PI/.2);
        q.xz=moda(q.xz,1.1+.1*sin(.001*time));
    }
    d=PseudoKleinian(q)-.0001;
    return d;
}
vec3 norm(vec3 p){vec2 e=vec2(.01,.0);return .000001+map(p)-vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx));}
float rnd(float x){return fract(sin(x+23.45)*87.65);}
float dots(vec3 p, float j) {
    p*=4.+sin(j);
    p.x += rnd(floor(p.y));
    p*=PI*PI*PI;
    return clamp(0.1-length(vec2(sin(p.x),cos(p.y))),0.0,1.0)*10.3;
}
float ao(vec3 p, vec3 q, float d){return clamp((map(p+q*d))/d,.0,1.);}
float sss(vec3 p, vec3 q, float d){return clamp(3.*(map(p+q*d)),.0,1.);}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x,resolution.y);
    vec3 col = vec3(0.0);
    vec3 ro=vec3(1.0,-3.0,-.5-sin(time))
    ,ta=vec3(-1.0,.0,-1.1);
    ro.xy=rot(ro.xy,.1*time);
    ta.xz=rot(ta.xz,.1*time);
    vec3 fwd=normalize(ta-ro)
    ,up=vec3(0.,1.,.0);
    vec3 side=normalize(cross(fwd,up));
    up=normalize(cross(side,fwd));
    vec3 rd=normalize(p.x*side+p.y*up+fwd*.6);
    vec3 ray=ro,N;
    int j;
    for(int i=0;i<128;++i){
        float d=max(map(ray),.0007);
        if(d<.001){N=norm(ray);break;}
        ray+=d*rd;
        j=i;
    }
    col=clamp(abs(6.*fract(128.*(.1*floor(length(ray.xy)))+vec3(.0,.6,.3))-3.)*.8-1.,0.,1.)*1.8;
    col+=pow(1.-float(j)/128.,3.);
    col+=length(ray-ro)/8.;
    col*=max(dot(N,normalize(ro-ray)),.0)+.125;
    col=smoothstep(col,vec3(1.2*abs(sin(step(PI,mod(time,2.*PI))))),.4-col);
    col*=ao(ray,rd,.2)*.2+ao(ray,rd,.4)*.4;
    col+=sss(ray,rd,.2)+sss(ray,rd,.3)*.4+sss(ray,rd,.6)*.6;
    
    vec3 col2 = vec3(0);
    for(int j=1;j<16;++j) {
        float dist=float(j)*.2/length(ray.xz);
        if(dist>256.) break;
        vec3 vp=vec3(ro.x,.5,.5)+rd*dist;
        vp.xy=rot(vp.xy,sin(vp.z*2.0+time*.02));
        col2 += dots(.05*vp, float(j))*clamp(1.0-dist/float(32), .0,1.);
    }
    col.rg+=col2.rg;
    col=mix(col,col.brg,vec3(sin(time)));

    glFragColor = vec4(col,1.0);
}
