#version 420

// original https://www.shadertoy.com/view/wst3RH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

// https://www.shadertoy.com/view/Xlf3zf
float DE(vec3 p0)
{
    //float time =0.0;
    float time =time;
    vec3 p=p0+sin(p0.yzx*4.0+2.4*sin(p0.zxy*5.0+time)+time*0.7)*0.5;
    float d=length(p)-1.0;
    return d;
}

float map(vec3 p)
{
    p.xz*=rot(time*0.2);
    p.yz*=rot(time*0.1);
    return DE(p);
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)  );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,3);
    vec3 rd = normalize(vec3(uv,-2));
    vec3 col = vec3(0.3,0.3,0.5)*uv.y*uv.y;
    
    vec3 center = vec3(0);//vec3(sin(time),0,0);
    float r=1.8;
    float h=1.0;
    vec3 p;
 
    if(length(cross(rd,center-ro))<r)
    {
        float ITR=300.;
           vec3 g= normalize(center-ro);
        vec3 pos=center+g*r;   
           for(float i=0.;i<ITR;i++)
        {
            float z = dot(pos-ro,rd);
            vec3 q = ro+rd*z;
            float d = map(q-center);
            h = min(h,max(d,0.0));
            if(d<0.01)p = q-center;
            pos -= g*(r/ITR)*2.0;
        }
    }
    if (h<0.01)
    {
        float d=map(p);
        vec3 nor = calcNormal(p);
        vec3 li = normalize(vec3(1));
        col = vec3(0.2,0.8,1.0);
        float dif = clamp(dot(nor, li), 0.3, 1.0);
        float amb = max(0.5 + 0.5 * nor.y, 0.0);
        float spc = pow(clamp(dot(reflect(normalize(p - ro), nor), li), 0.0, 1.0), 50.0);
        col *= dif * amb ;
        col += spc;
        col = clamp(col,0.0,1.0);
    }
    col = pow(col, vec3(0.6));
    glFragColor = vec4(col, 1.0);
}
