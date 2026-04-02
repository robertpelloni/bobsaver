#version 420

// original https://www.shadertoy.com/view/ltS3zD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float r(vec3 p)
{
     return fract(cos(dot(p,vec3(4.59,6.23,-5.36)))*347.34);
}
float sr(vec3 p)
{
    vec3 f = floor(p);
    vec3 s = smoothstep(vec3(0.0),vec3(1.0),fract(p));
    float h1 = mix(r(f),r(f+vec3(1.0,0.0,0.0)),s.x);
    float h2 = mix(r(f+vec3(0.0,1.0,0.0)),r(f+vec3(1.0,1.0,0.0)),s.x);
    float sq = mix(h1,h2,s.y);
    h1 = mix(r(f+vec3(0.0,0.0,1.0)),r(f+vec3(1.0,0.0,1.0)),s.x);
    h2 = mix(r(f+vec3(0.0,1.0,1.0)),r(f+vec3(1.0,1.0,1.0)),s.x);
    return mix(sq,mix(h1,h2,s.y),s.z);
}

vec2 model(vec3 p)
{
    float n = (sr(p/4.0)*0.65+sr(p)*0.2+sr(p*4.0)*0.1+sr(p*16.0)*0.05)+p.y*0.1;
     //float n = noise(p,distance(p,vec3(time,1.0,0.0)));
    vec2 v = vec2(pow(n,0.8)-0.5,n*0.2);  
    return v.xy*vec2(1.0,float(v.x<0.0));
}
vec3 color(vec3 p)
{
    vec3 c = vec3(vec2(sr(p)*0.1+0.7),sr(p/4.0)*0.1+0.75); 
    return c;
}
vec3 background(vec3 d)
{
     float sky = dot(d,vec3(0.0,1.0,0.0))*0.25+0.75;
    return sky*vec3(0.5,0.7,0.9);
}
vec3 raymarch(vec3 p,vec3 d)
{
    float r = 1.0;
    vec2 t = vec2(1.0,0.0);
    vec4 c = vec4(background(d),0.0);
    for(int i=0;i<60;i++)
    {
        t = model(p+d*r);
        r += max(t.x,0.05);
        c.a += t.y*min(r*0.02,1.0);
        c.rgb = mix(c.rgb,color(p+d*r),clamp(c.a,0.0,1.0));
        if (r>20.0 || c.a > 1.0) break;
    }
    return c.rgb;
}
mat3 calcLookAtMatrix(vec3 ro, vec3 ta, float roll)//Function by Iq
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = ( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = ( cross(uu,ww));
    return mat3( uu, vv, ww );
}
void main(void)
{
    vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    vec2 m = mouse.xy/resolution.xy*vec2(2.0,2.0)+vec2(-1.0,-1.0);
    uv += m;
    vec3 p = vec3(time,1.0,0.0);
    vec3 d = normalize(calcLookAtMatrix(p,vec3(0.0),0.0)* vec3(uv.xy,2.0));
    glFragColor = vec4(raymarch(p,d),1.0);
}
