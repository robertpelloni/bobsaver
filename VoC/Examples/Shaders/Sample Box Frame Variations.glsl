#version 420

// original https://www.shadertoy.com/view/7t3XW2

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Box frame variations by kastorp

#define edge(v) length(max(vec3(v.x,v.y,v.z),0.0))+min(max(v.x,max(v.y,v.z)),0.0)

float boxFrame1( vec3 p, float b, float e, float k )
{
  p = abs(p  );
  vec3 m=step(p,p.zxy)*step(p,p.yzx);
  p -= b  -m*b*k;
  vec3 q = abs(p+e)-e;  
  float d =1e5;
  d=min(d, edge(vec3(p.x,q.y,q.z)));
  d=min(d, edge(vec3(q.x,p.y,q.z)));
  d=min(d, edge(vec3(q.x,q.y,p.z)));
  return d;
}

float boxFrame2( vec3 p, float b, float e , float k)
{
  p = abs(p  );
  vec3  m=step(p.zxy,p)*step(p.yzx,p);  
    p -= b*((1.-k) +m*.4);
  vec3 q = abs(p+e )-e;  
  float d =1e5;
  if(m.x==0.) d=min(d, edge(vec3(q.x,p.y,p.z)));
  if(m.y==0.) d=min(d, edge(vec3(p.x,q.y,p.z)));
  if(m.z==0.) d=min(d, edge(vec3(p.x,p.y,q.z)));
  return d;
}

float boxFrame3( vec3 p, float b, float e, float k )
{
  p = abs(p  );
  vec3  m=step(p.zxy,p)*step(p.yzx,p);  
    p -= b*((1.-k) +m*k);
  vec3 q = abs(p+e )-e;  
  float d =1e5;
  if(m.x!=0.) d=min(d, edge(vec3(q.x,p.y,p.z)));
  if(m.y!=0.) d=min(d, edge(vec3(p.x,q.y,p.z)));
  if(m.z!=0.) d=min(d, edge(vec3(p.x,p.y,q.z)));
  return d;
}

float boxFrame4( vec3 p, float b, float e, float k )
{
 
  p = abs(p  );
  vec3 m=step(p,p.zxy)*step(p,p.yzx);
  p -= b -m*b*(1.-k);   
  vec3 q = abs(p+e)-e; 
  p-=m*b*(1.-k);
  float d =1e5;
  d=min(d, edge(vec3(p.x,q.y,q.z)));
  d=min(d, edge(vec3(q.x,p.y,q.z)));
  d=min(d, edge(vec3(q.x,q.y,p.z)));
  return d;
}

float boxFrame5( vec3 p, float b, float e , float k)
{
  p = abs(p  );
  vec3 m=step(p,p.zxy)*step(p,p.yzx);
    p -= b  -m*b*k;
  vec3 q = abs(p+e)-e;  
  float d =1e5;
  if(m.x==1.)d=min(d, edge(vec3(q.x,p.y,p.z)));
  if(m.y==1.)d=min(d, edge(vec3(p.x,q.y,p.z)));
  if(m.z==1.)d=min(d, edge(vec3(p.x,p.y,q.z)));
  return d;
}
float boxFrame6( vec3 p, float b, float e , float k)
{
  p = abs(p  );
  vec3 m=step(p,p.zxy)*step(p,p.yzx);
    p -= b  -m*b*k;
  vec3 q = abs(p+e)-e;  

  float d =1e5;

  if(m.x==0.)d=min(d, edge(vec3(q.x,p.y,p.z)));
  if(m.y==0.)d=min(d, edge(vec3(p.x,q.y,p.z)));
  if(m.z==0.)d=min(d, edge(vec3(p.x,p.y,q.z)));
  return d;
}

float boxFrame7( vec3 p, float b, float e , float k)
{
  p = abs(p  );
  vec3  mn=step(p.zxy,p)*step(p.yzx,p),  mx=step(p,p.zxy)*step(p,p.yzx);;
  p -= b*((1.-k)+mn*k-mx*k);
  vec3 q = abs(p+e )-e;  
  float d =1e5;
  if(mn.x==0.)d=min(d, edge(vec3(p.x,q.y,q.z)));
  if(mn.y==0.)d=min(d, edge(vec3(q.x,p.y,q.z)));
  if(mn.z==0.)d=min(d, edge(vec3(q.x,q.y,p.z)));
  return d;
}

float boxFrame8( vec3 p, float b, float e, float k )
{
  p = abs(p  );
  vec3  m=step(p.zxy,p)*step(p.yzx,p);  
    p -= b*((1.-k)+m*k);
  vec3 q = abs(p+e )-e;  
  float d =1e5;
  if(m.x==0.) d=min(d, edge(vec3(p.x,q.y,q.z)));
  if(m.y==0.) d=min(d, edge(vec3(q.x,p.y,q.z)));
  if(m.z==0.) d=min(d, edge(vec3(q.x,q.y,p.z)));
  return d;
}

float boxFrame9( vec3 p, float b, float e , float k)
{
  p = abs(p  );
  vec3  mn=step(p.zxy,p)*step(p.yzx,p),  mx=step(p,p.zxy)*step(p,p.yzx);;
  p -= b*((1.-k) +mn*k-mx*k);
  vec3 q = abs(p+e )-e;  
  float d =1e5;
  if(mn.x==0.)d=min(d, edge(vec3(q.x,p.y,p.z)));
  if(mn.y==0.)d=min(d, edge(vec3(p.x,q.y,p.z)));
  if(mn.z==0.)d=min(d, edge(vec3(p.x,p.y,q.z)));
  return d;
}

float boxFrame10( vec3 p, float b, float e , float k)   
{
    p = abs(p  );
    return .5*(min(min(p.x,p.y),p.z)+max(max(p.x,p.y),p.z) -b);
}

float boxFrame11( vec3 p, float b, float e , float k)   
{
    p = abs(p)-b*.8;
    vec2 a =vec2(.3*sin(time));
    p*=mat3(cos(a.x),sin(a.x),0,-sin(a.x),cos(a.x),0,0,0,1);
    p*=mat3(1,0,0,0,cos(a.y),sin(a.y),0,-sin(a.y),cos(a.y));
    return edge(p);
    
}

float mt=0.;
#define mmin(a,b,c) (a.x<b ?a:vec2(b,c))
float map(vec3 p) {
        
    vec2 d= vec2(p.y,.0); float k=sin(time)*.25+.25;
     d= mmin(d,boxFrame4(p - vec3(0.7,.6,0.7) ,.4,.03,k),1.);
     d= mmin(d,boxFrame2(p - vec3(-0.7,.6,0.7),.4,.03,k),2.);
     d= mmin(d,boxFrame3(p - vec3(-0.7,.6,-0.7),.4,.03,k),3.);
     d= mmin(d,boxFrame1(p - vec3(0.7,.6,-0.7),.4,.03,k),4.);
     d= mmin(d,boxFrame5(p - vec3(2.1,.6, 0.7),.4,.03,k),5.);
     d= mmin(d,boxFrame6(p - vec3(2.1,.6,-0.7),.4,.03,k),.6);
     d= mmin(d,boxFrame7(p - vec3(-2.1,.6, 0.7),.4,.03,k),7);
     d= mmin(d,boxFrame8(p - vec3(-2.1,.6,-0.7),.4,.03,k),8);
     mt=d.y;
    return d.x;
}

vec3 calcN(vec3 p, float t) {
    float h = .001 * t;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .5773 * (2. * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h);
    }

    return normalize(n);
}

float calcShadow(vec3 p, vec3 ld) {
    float s = 1., t = .05;
    for (float i = 0.; i < 40.; i++)
    {
        float h = map(p + ld * t);
        s = min(s, 15. * h / t);
        t += h;
        if (s < .001) break;
    }

    return clamp(s, 0., 1.);
}

float ao(vec3 p, vec3 n, float h) {
    return map(p + h * n) / h;
}

vec3 vignette(vec3 c, vec2 fc) {
    vec2 q = fc.xy / resolution.xy;
    c *=  1.;//.5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
    return c;
}
vec3 getRayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

vec3 lights(vec3 p, vec3 rd, float d) {
    vec3 lightDir = normalize( vec3(5.,17.-mouse.x*resolution.x/resolution.x*6.,8.) );
    vec3 ld = normalize(lightDir*6.5 - p), n = calcN(p, d) ;

    float ao = .1 + .9 * dot(vec3(ao(p, n, .1), ao(p, n, .4), ao(p, n, 2.)), vec3(.2, .3, .5)),
    l1 = max(0., .2 + .8 * dot(ld, n)),
    l2 = 0.,
    spe = max(0., dot(rd, reflect(ld, n))) * .1,

    fre = smoothstep(.7, 1., 1. + dot(rd, n));

    // Combine.
    l1 *= .1 + .9 * calcShadow(p+.01*n, ld);
    vec3 lig = ((l1 + l2) * ao + spe) * vec3(1.) *2.5;
    return mix(.3, .4, fre) * lig;
}

vec3 march(vec3 ro, vec3 rd) {
    // Raymarch.
    vec3 p;

    float d = .01;
    for (float i = 0.; i < 120.; i++) {
        p = ro + rd * d;
        float h = map(p);

        if (abs(h) < .0015)
            break;

        d += h; // No hit, so keep marching.
    }
    
    return lights(p, rd, d) * exp(-d * .085)*(p.y<0.01? vec3(0.2,0.15,0.2):.5+.5*cos(vec3(2,0,4)+mt*.75));
}

void main(void)
{
    
    float t=-time*.5;
    vec3 ro = vec3(3.*cos(t), 2.+3.*mouse.y*resolution.y/resolution.y, 3.*sin(t));
    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    glFragColor = vec4(vignette(pow(march(ro, getRayDir(ro, vec3(-0.), uv)), vec3(.45)), gl_FragCoord.xy), 0);
}
