#version 420

// original https://www.shadertoy.com/view/wtXSzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.0)
#define TAU PI*2.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec3 hue(float h)
{
    return cos((vec3(0,2,-2)/3.+h)*TAU)*.5+.5;
}

vec3 cLine(vec3 ro, vec3 rd, vec3 a, vec3 b)
{
    vec3 ab =normalize(b-a),ao = a-ro;
    float d0 = dot(rd, ab), d1 = dot(rd, ao), d2 = dot(ab, ao);
    float t = (d0*d1-d2)/(1.0-d0*d0)/length(b-a);
    t= clamp(t,0.0,1.0);
    vec3 p = a+(b-a)*t-ro;
    return vec3(length(cross(p, rd)), dot(p,rd),t);
}

float hash(float n)
{
    return fract(sin(n)*5555.0);
}

vec3 randVec(float n)
{
    vec3 v=vec3(1,0,0);
    v.xy*=rot(asin(hash(n+=215.3)*2.-1.));
    v.xz*=rot((hash(n)*2.-1.)*PI);
    return v;
}

vec3 randCurve(float t,float n)
{
    vec3 p = vec3(0);
    for (int i=0; i<4; i++)
    {
        p += randVec(n+=365.)*sin((t*=1.3)+sin(t*0.6)*0.5);
    }
    return p;
}

vec3 func(float t,float n)
{
    vec3 p = randCurve(-t*2.+time,2576.)*2.;
    vec3 off = randVec(n)*(t+0.05)*0.6;
    float time=time+hash(n)*8.0;
    return p+off*sin(time+0.5*sin(0.5*time));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy) /resolution.y;
    vec3 ro = vec3(0,0,5);
    ro.xz*=rot(time*0.1);
    vec3 w=normalize(-ro);
    vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 rd = mat3(u,cross(u,w),w)*normalize(vec3(uv,3));
    vec3 col = hue(0.6)*0.2*(1.0-length(uv)*0.5);
    vec3 de;
    float ITR=40.;
    for(float i=0.; i<1.;i+=1.0/8.0)
    {
        de = vec3(1e9);
        float off=hash(i+256.);
        for(float j=0.0;j<1.0;j+=1.0/ITR)
        {
            float t=j+off*0.5;
            vec3 c = cLine(ro, rd, func(t,off), func(t+1.0/ITR,off));
            if (de.x*de.x*de.y>c.x*c.x*c.y)
            {
                   de=c;
                   de.z = j + c.z/ITR;
            }
        }
        
        float s = pow(max(0.0,0.6-de.z),2.0)*0.1;
        if(de.y>0.)
            col+=mix(vec3(1),hue(i),0.8)*(1.0-de.z*0.9)*smoothstep(s+0.07,s,de.x)*0.7;
            //col = mix(mix(vec3(1),hue(i),0.6)*(1.0-de.z*0.9),col,smoothstep(s,s+0.04,de.x)); 
    }
    glFragColor = vec4(min(vec3(1),col),1.0);
}
