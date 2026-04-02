#version 420

// original https://www.shadertoy.com/view/wsfyR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float G1=0.0, G2=0.0;

vec3 rot(vec3 p,vec3 a,float t) 
{
    a=normalize(a);
    vec3 v = cross(a,p),u = cross(v,a);
    return u * cos(t) + v * sin(t) + a * dot(p, a);   
}

float lpNorm(vec2 p, float n)
{
    p = pow(abs(p), vec2(n));
    return pow(p.x+p.y, 1.0/n);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float smin( float a, float b, float k ) 
{
    float h = clamp(.5+.5*(b-a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1.-h);
}

float deTetra(vec3 p) 
{
    vec2 g=vec2(-1,1)*0.577;
    return pow(
        pow(max(0.0,dot(p,g.xxx)),8.0)
        +pow(max(0.0,dot(p,g.xyy)),8.0)
        +pow(max(0.0,dot(p,g.yxy)),8.0)
        +pow(max(0.0,dot(p,g.yyx)),8.0),
        0.125);
}

float deStella(vec3 p) 
{
    p=rot(p,vec3(1,2,3),time*3.0);
    return smin(deTetra(p)-1.0,deTetra(-p)-1.0,0.05);
}

#define Circle 2.0
vec2 hash2( vec2 p )
{
    p = mod(p, Circle*2.0); 
    return fract(sin(vec2(
        dot(p,vec2(127.1,311.7)),
        dot(p,vec2(269.5,183.3))
    ))*43758.5453);
}

// https://www.shadertoy.com/view/ldl3W8
vec3 voronoi(vec2 x)
{
    x*=Circle;
    vec2 n = floor(x);
    vec2 f = fract(x);
    vec2 mg, mr;
    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        vec2 o = hash2( n + g );
        o = 0.5 + 0.5*sin( time + 6.2831*o );
        vec2 r = g + o - f;
        float d = dot(r,r);
        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }
    md = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
        vec2 o = hash2( n + g );
        o = 0.5 + 0.5*sin( time + 6.2831*o );
        vec2 r = g + o - f;
        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }
    return vec3( md, mr );
}

float voronoiTorus(vec3 p){
    vec2 size = vec2(12,5);
    vec2 q = vec2(length(p.xz) - size.x, p.y);
    vec2 uv=vec2(atan(p.z, p.x),atan(q.y, q.x))/3.1415;
    vec3 vr=voronoi(uv*vec2(20,4));
    vec2 p2=vec2(length(vr.yz)-0.5, sdTorus(p,size));
    return lpNorm(p2,5.0)-0.08; 
}

float map(vec3 p)
{   
    vec3 offset = vec3(6,0,0);
    float de = min(voronoiTorus(p-offset),voronoiTorus(p.xzy+offset));
    vec3 co = vec3(cos(time),0,sin(time))*10.0;
    float s1= abs(sin(time))*3.0+2.0;
    float deSG = min(deStella((p-co-offset)/s1),deStella((p-(co-offset).xzy)/s1))*s1;
    G1 +=0.1/(0.1+deSG*deSG*10.0);
    float deS = min(deStella(p-co-offset),deStella(p-(co-offset).xzy));
     G2 +=0.1/(0.1+deS*deS*10.0);
    de=min(de,deS);    
    return de;
}

vec3 calcNormal(vec3 pos)
{
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

float softshadow(in vec3 ro, in vec3 rd)
{
    float res = 1.0;
    float t = 0.05;
    for(int i = 0; i < 32; i++)
    {
        float h = map(ro + rd * t);
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.1);
        if(h < 0.001 || t > 5.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 ro=vec3(0,5,-10);
    ro= vec3(cos(time*0.5+0.5*cos(time*.3))*8.0-6.,sin(time*0.8+0.5*sin(time*0.3))+4.0,sin(time*0.3+1.2*sin(time*0.3))*10.);
    ro*=2.5;
    vec3 w = normalize(-ro),u=normalize(cross(w,vec3(0,1,0))),v=cross(w,u);
    vec3 rd=mat3(u,v,w)*normalize(vec3(uv,2.0));
    vec3 col= mix(vec3(0),vec3(0.2,0.05,0.05),length(uv*vec2(1,1.2))*0.25);
    float t=1.0,d;
    for(int i=0;i<96;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001||t>60.0) break;
    }
    if(d<0.001)
    {
        col=vec3(0.5,0.5,0.55);
        vec3 p=ro+rd*t;
        vec3 n = calcNormal(p);
        vec3 li = normalize(vec3(2.0, 3.0, 3.0));
        float dif = clamp(dot(n, li), 0.0, 1.0);
        dif *= softshadow(p, li);
        col *= max(dif, 0.3);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
        float frn = rimd + 2.2 * (1.0 - rimd);
        col *= frn*0.8;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 60.0);
         col+=vec3(1,0.2,0)*G1*.05;
        col+=vec3(1,0,0)*G2*.03*(sin(time*5.0)*0.5+0.6);
           col = mix( col, vec3(0.2), 1.0-exp( -0.0005*t*t ) );
    }
    glFragColor = vec4(col, 1.0);
}
