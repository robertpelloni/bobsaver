#version 420

// original https://www.shadertoy.com/view/7d3SDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A very simple duck that's walking.
// Shoutout to rimina! :)

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

void rot(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x < d2.x) ? d1 : d2;
}

float llength = .4;
float lspread = .4;
float wspeedmod = 4.;
float wstridemod = .2;

struct MarchResult
{
    vec3 p;
    float id;
};

vec2 sdf(vec3 p){
   vec3 pp = p;

   pp = pp - vec3(1.+sin(time*wspeedmod*2.)*.02,.7,.0);
   float head = sdBox(pp,vec3(.5,.4,.5));
   vec3 ppp = pp - vec3(.7,-.1,.0);
   float beak = sdBox(ppp,vec3(.2,.08,.2));
   pp.z = abs(pp.z);
   pp = pp - vec3(.5,.2,.3);
   float eyes = sdBox(pp,vec3(.1,.1,.1));
   
   vec2 h = opU(vec2(eyes,1.0),opU(vec2(beak,2.0),vec2(head,3.0)));

   pp = p;
   rot(pp.xz,-sin(time*wspeedmod)*.1);
   float body = sdBox(pp,vec3(1.,.6,.8));
   pp = pp - vec3(-1.1+sin(time*wspeedmod*2.)*.02,.7,.0);
   rot(pp.xz,sin(time*wspeedmod)*.1);
   float tail = sdBox(pp,vec3(.4,.1,.6));
   body = min(tail,body); 
   vec2 b = opU(vec2(body,3.0),h);
   
   pp = p;
   rot(pp.xy,sin(time*wspeedmod)*wstridemod);
   pp = pp - vec3(0.,-1.,lspread);
   float lleg = sdBox(pp,vec3(.1,llength,.2));
   lleg = min(lleg,sdBox(pp-vec3(.2,-llength,.0),vec3(.4,.1,.2)));
   
   pp = p;
   rot(pp.xy,-sin(time*wspeedmod)*wstridemod);
   pp = pp - vec3(0.,-1.,-lspread);
   float rleg = sdBox(pp,vec3(.1,llength,.2));
   rleg = min(rleg,sdBox(pp-vec3(.2,-llength,.0),vec3(.4,.1,.2)));
   float legs = min(lleg,rleg);
   
   return opU(vec2(legs,2.0),b);

}

MarchResult march(in vec3 ro, in vec3 rd, inout float t){

    MarchResult m;
    m.p = ro+rd;
    for(int i = 0; i < 40; ++i){
        vec2 d = sdf(m.p);
        t += d.x;
        m.p += rd*d.x;
        m.id = d.y;
        
        if(d.x < 0.01 || t > 100.){
            break;
        }
        
    }
    
    return m;
}

vec3 color(in float id)
{
    if (id == 1.0)
        return vec3(0.1);
    else if (id == 2.0)
        return vec3(.8,.3,.2);
    else if (id == 3.0)
        return vec3(.8,.7,.4);
    else
        return vec3(0);
}
vec3 calcNormal( in vec3 pos) 
{
    vec2 e = vec2(0.00001, 0.0);
    return normalize( vec3(sdf(pos+e.xyy).x-sdf(pos-e.xyy).x,
                           sdf(pos+e.yxy).x-sdf(pos-e.yxy).x,
                           sdf(pos+e.yyx).x-sdf(pos-e.yyx).x ) );
}

void main(void)
{

    vec3 cp = vec3(3.,2.0,3.);
    vec3 ct = vec3(0,0,0);
    vec3 ld = vec3(-2.,0.5,2.);

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 q = -1.0+2.0*uv;
    q.x *= resolution.x/resolution.y;
    
    vec3 cf = normalize(ct-cp);
    vec3 cr = normalize(cross(vec3(0.0,1.0,0.0),cf));
    vec3 cu = normalize(cross(cf,cr));
    
    vec3 rd = normalize(mat3(cr,cu,cf)*vec3(q,radians(90.0)));
    
    vec3 p = vec3(0.0);
    
    float t;
    MarchResult m;
    m.p = vec3(0.0);
    m.id = 0.0;
    m = march(cp,rd,t);
    
    vec3 col = vec3(0.0);
    if(t < 100.){
        col = color(m.id) + (clamp(dot(calcNormal(m.p), ld), 0.0, 1.0)*0.1);
        
    }
    
    glFragColor = vec4(col,1.0);
}
