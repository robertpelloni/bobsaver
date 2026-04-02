#version 420

// original https://www.shadertoy.com/view/ttSBRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define hash(n) fract(sin(n*234.567+123.34))

float map(vec3 p){
    p.xy *= rot(time*0.1);
    p.yz *= rot(time*0.2);
    float seed=dot(floor((p+3.5)/7.)+3.,vec3(123.12,234.56,678.22));   
    p-=clamp(p,-3.5,3.5)*2.;
    p.xy *= rot(time*0.3);
    p.yz *= rot(time*0.4);
    float scale=-5.;
    float mr2=.38;
    float off=1.2;
    float s=3.;
    p=abs(p);
    vec3  p0 = p;
    for (float i=0.; i<4.+hash(seed)*6.; i++){
        p=1.-abs(p-1.);
        float g=clamp(mr2*max(1.2/dot(p,p),1.),0.,1.);
        p=p*scale*g+p0*off;
        s=s*abs(scale)*g+off;
    }
    return length(cross(p,normalize(vec3(1))))/s-.005;
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

float calcShadow( vec3 light, vec3 ld, float len ) {
    float depth = march( light, ld, 0.0, len );    
    return step( len - depth, 0.01 );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy* 2.0 - resolution.xy) / resolution.y;
    vec3 ro = vec3(0,0,13.5);
    vec3 rd = normalize(vec3(uv,-2.0));
    vec3 col = vec3(0);
    const float maxd = 40.0;
    float t = march(ro,rd,0.0,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=vec3(0.3,0.3,0.6)+cos(p*0.17)*0.5+0.5;
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
        col = mix(vec3(0),col,exp(-t*t*.003));
    }
    glFragColor.xyz = col;
}
