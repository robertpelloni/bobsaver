#version 420

// original https://www.shadertoy.com/view/fdV3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//reference: https://gaz.hateblo.jp/entry/2019/05/11/092204

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec3 trans(vec3 p){
    return mod(p, 8.0) - 4.0;
}

float deBox(vec3 p)
{
    return length(max(abs(p)-vec3(1),0.0));   
}

float de1(vec3 p)
{
    p *= vec3(sin(sin(time-.5 + sin(time+.5))),sin(sin(time + cos(time))),sin(cos(time + sin(time))));

    return deBox(p);
}

float de2(vec3 p){

    vec3 b1 = p;
    b1.x = 1.;
    vec3 b2 = p;
    b2.y = 1.;
    vec3 b3 = p;
    b3.z = 1.;

    return min(deBox(b1), min(deBox(b2), deBox(b3)));
}

float map(vec3 p)
{
    p.xy*=rot(time*.3);
    p = trans(p);
    
    return max(de1(p), de2(p));
}

vec3 doColor(vec3 p)
{
    return vec3(0.,0.1,0.2);
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    vec3 ro=vec3(0,0,time*3.);
    vec3 rd=normalize(vec3(uv,1));
    //camera
    vec3 ta=vec3(0,0,0); //target
    vec3 w=normalize(ta-ro);
    vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 v=cross(u,w);
    mat3 lookat=mat3(u,v,w);
    rd=lookat*rd;
    //
    float d,i,t=0.0;
    vec3 p=ro;
    vec3 col=vec3(0);
    for(i=1.0;i>0.0;i-=1./100.0)
    {
        t+=d=map(p);
        if(d<0.001)
        {
            col += doColor(p);
            col += pow(i , 1.); 
            break;
        }
        p+=rd*d;
    }
    
    glFragColor=vec4(col,1.0);
}
