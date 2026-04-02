#version 420

// original https://www.shadertoy.com/view/MlSBWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 lookat(vec3 d, vec3 up)
{
    vec3 w = normalize(d),u = normalize(cross(w,up));
    return (mat3(u,cross(u,w),w));
}

vec2 rayCastPlane(vec3 ro, vec3 rd, vec3 pos, vec3 nor, vec3 up)
{
    float z = dot(pos-ro,nor)/dot(rd,nor);
    vec3 p=ro+rd*z, a=p-pos, u=normalize(cross(nor,up)), v=normalize(cross(u,nor));
    return vec2(dot(a,u),dot(a,v));
}

vec3 hsv(float h, float s, float v)
{
    return mix(vec3(1),clamp((abs(fract(h+vec3(3,2,1)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

vec3 knot(float t)
{
    t *= radians(360.);
    return vec3(sin(t)+2.*sin(2.*t),cos(t)-2.*cos(2.*t),-sin(3.*t));
}

float de(vec2 p)
{
    return abs(length(p)-0.1);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    float t = time*0.05;
    vec3 ro = knot(t);
    ro += normalize(ro).zxy*0.5;
    vec3 ta = knot(t+0.05);    
    ta += normalize(ta).zxy*0.3;
    vec3 rd = lookat(ta-ro,ro.xzy)*normalize(vec3(p,2));    
    vec3 col = vec3(0.3,0.3,0.5)*p.y*p.y;
    const int s = 200;
    for(int i=0;i<s;i++)
    {
        float t = float(i)/float(s);
        vec3 d = normalize(knot(t-0.001)-knot(t+0.001));
        vec2 b = rayCastPlane(ro,rd,knot(t),d,d.yzx);
        col = mix(col,hsv(float(i)/float(s),0.8,1.0),smoothstep(0.01,0.0,de(b)));
    }
    vec3 d = normalize(knot(t-0.001)-knot(t+0.001));
    vec2 b = rayCastPlane(ro,rd,ta,ta-rd,(ta-rd).yzx);
    col = mix(col,hsv(fract(0.5+t),0.8,1.0),smoothstep(0.035,0.0,min(de(b),de(b*2.))));
    
    glFragColor = vec4(col, 1.0);
}
