#version 420

// original https://www.shadertoy.com/view/4lBfzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T time

void r(inout vec2 p) 
{
    float a = mod(atan(p.y, p.x) + .1963495,.39269908) - .1963495;
    p = vec2(cos(a),sin(a))*length(p);
}

float c(vec3 p, vec3 a, vec3 b, float r)
{  
    return length(((b - a)*clamp(dot(p - a, b - a) / dot(b - a, b - a),0.,1.) + a) - p) -r ;
}

float map (vec3 p)
{
    p.y = mod(p.y + 1., 2.) - 1.;
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(.7,10.);
    float a = min(max(d.x,d.y),0.0) + length(max(d,0.)); 
    a=min(a,length(vec2(length(p.xz)-1.2,p.y))-.35);
    r(p.xz);
    float b = c(p,vec3(.6,3,0),vec3(.6,-3,0),.2);
    a=max(a,-b);
    p=vec3(cos(T)*p.x-sin(T)*p.z,p.y,sin(T)*p.x+cos(T)*p.z);
    r(p.xz);    
    float g = c(p,vec3(2,-.5,0),vec3(2,.5,0),.2);
    float e = c(p,vec3(2,-.5,0),vec3(1,-.5,0),.2);
    float f = c(p,vec3(2,.5,0),vec3(1,.5,0),.2);
    return min(a,min(min(g,e),f));
}

vec4 raymarch (vec3 p, vec3 rd)
{
    for (int i=0;i<128;i++)
    {
      float t = map (p);
      if (t<0.001)  return vec4(pow(1.-float(i)/float(128),2.));         
      p+=t*rd;
    }
    return vec4(1.0-(pow(length(rd.x),2.)*2.),0,0,1);
}

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    vec2 uv = (2. * f.xy - resolution.xy) / resolution.y;
    glFragColor = raymarch(vec3 (0,T,-5.),normalize(vec3(uv,2.)));
}
