#version 420

// original https://www.shadertoy.com/view/3dScRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 rotateXYZ(vec3 t)
{
      float cx = cos(t.x);
      float sx = sin(t.x);
      float cy = cos(t.y);
      float sy = sin(t.y);
      float cz = cos(t.z);
      float sz = sin(t.z);
      mat3 m=mat3(
        vec3(1, 0, 0),
        vec3(0, cx, -sx),
        vec3(0, sx, cx));

      m*=mat3(
        vec3(cy, 0, sy),
        vec3(0, 1, 0),
        vec3(-sy, 0, cy));

      return m*mat3(
        vec3(cz, -sz, 0),
        vec3(sz, cz, 0),
        vec3(0, 0, 1));
}

//SDF-Functions
float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float softmin(float f1, float f2, float val)
{
      float e = max(val - abs(f1 - f2), 0.0);
      return min(f1, f2) - e*e*0.25 / val;     
}

float map(vec3 p)
{
      vec3 origin=p;
      p=rotateXYZ(vec3(1.5,0,0))*p;

      p.z-=1.5;
      float myplane=sdRoundBox(p,vec3(20,40,.01),.1);
      p.z+=1.5;
      p=rotateXYZ(vec3(1,time,sin(time*.5)*.5))*origin;
      p.y+=.5;
      float mycube=sdRoundBox(p,vec3(.75/2.),.1);
      return(softmin(myplane,mycube,1.));
}
vec3 normal(vec3 p)
{
      vec2 eps=vec2(.005,0);
      return normalize(vec3(map(p+eps.xyy)-map(p-eps.xyy),
                            map(p+eps.yxy)-map(p-eps.yxy),
                            map(p+eps.yyx)-map(p-eps.yyx)));
}

// LIGHT
float diffuse_directional(vec3 n,vec3 l, float strength)
{
      return (dot(n,normalize(l))*.5+.5)*strength;
}

float specular_directional(vec3 n, vec3 l, vec3 v, float strength)
{
      vec3 r=reflect(normalize(l),n);
      return pow(max(dot(v,r),.0),128.)*strength;
}

float ambient_omni(vec3 p, vec3 l)
{
      float d=1.-abs(length(p-l))/100.;
      return pow(d,32.)*1.5;
}

//SHADOW
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.0001 )
            return .0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

// MAINLOOP
void main(void)
{  
    vec2 uv= gl_FragCoord.xy/resolution.xy-.5;
    uv.x/=resolution.y/resolution.x;
    vec3 ro=vec3(.0,.0,-3.5); 
    vec3 p=ro;
    vec3 rd=normalize(vec3(uv,1.));
    float shading=.0;
    bool hit=false;

    vec3 color;
    while(p.z<20.)
    {
        float d=map(p);
        if(d<.0001)
        {
            hit=true;
            break;
        }
        p += rd*d;
    }

    float t=length(ro-p);
    if (hit)
    {
        shading=length(p*10.);
        vec3 n=normal(p);
        vec3 l1=vec3(1,.5,-.25);
        float rl=ambient_omni(p,l1)*diffuse_directional(n,l1,.25)+specular_directional(n,l1,rd,.9);
        color=vec3(rl)+vec3(.1,.4,.1);
        vec3 pos = ro + t*rd;
        color=mix(vec3(.0),color,softshadow(pos,normalize(l1),.01,10.0,20.)*.25+.75);
    }
    color*=mix(color,vec3(1.,1.,1.),1.-exp(-.1*pow(t,128.)));
    color-=t*.05;

    glFragColor=vec4(color,1.);
}
