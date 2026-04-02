#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// let's try and rip https://www.shadertoy.com/view/ltjGD1 off

float pi = 3.14159265359;

void angularRepeat(const float a, inout vec2 v)
{
    float an = atan(v.y,v.x);
    float len = length(v);
    an = mod(an+a*.5,a)-a*.5;
    v = vec2(cos(an),sin(an))*len;
}

void angularRepeat(const float a, const float offset, inout vec2 v)
{
    float an = atan(v.y,v.x);
    float len = length(v);
    an = mod(an+a*.5,a)-a*.5;
    an+=offset;
    v = vec2(cos(an),sin(an))*len;
}

float mBox(vec3 p, vec3 b)
{
    return max(max(abs(p.x)-b.x,abs(p.y)-b.y),abs(p.z)-b.z);
}

vec2 frot(const float a, in vec2 v)
{
    float cs = cos(a), ss = sin(a);
    vec2 u = v;
    v.x = u.x*cs + u.y*ss;
    v.y = u.x*-ss+ u.y*cs;
    return v;
}

void rotate(const float a, inout vec2 v)
{
    float cs = cos(a), ss = sin(a);
    vec2 u = v;
    v.x = u.x*cs + u.y*ss;
    v.y = u.x*-ss+ u.y*cs;
}

float rocketRotation;

float dfRocketBody(vec3 p)
{
    rotate(rocketRotation,p.yz);
    
    vec3 p2 = p;
    vec3 pWindow = p;
    
    angularRepeat(pi*.25,p2.zy);
    float d = p2.z;
    d = max(d, frot(pi*-.125, p2.xz+vec2(-.7,0)).y);
    d = max(d, frot(pi*-.25*.75, p2.xz+vec2(-0.95,0)).y);
    d = max(d, frot(pi*-.125*.5, p2.xz+vec2(-0.4,0)).y);
    d = max(d, frot(pi*.125*.25, p2.xz+vec2(+0.2,0)).y);
    d = max(d, frot(pi*.125*.8, p2.xz+vec2(.55,0)).y);
    d = max(d,-.8-p.x);
    d -= .5;
    
    pWindow -= vec3(.1,.0,.0);
    angularRepeat(pi*.25,pWindow.xy);
    pWindow -= vec3(.17,.0,.0);
    d = min(d,mBox(pWindow,vec3(.03,.2,.55)));
    
      return d;
}

float dfRocketFins(vec3 p)
{
    rotate(rocketRotation,p.yz);
    
    vec3 pFins = p;
    angularRepeat(pi*.5,pFins.zy);
    pFins -= vec3(-1.0+cos(p.x+.2)*.5,.0,.0);
    rotate(pi*.25,pFins.xz);
    float scale = 1.0-pFins.z*.5;
    float d =mBox(pFins,vec3(.17,.03,3.0)*scale)*.5;
    return d;
}

float df(vec3 p)
{
    float proxy = mBox(p,vec3(2.5,.8,.8));
    if (proxy>1.0)
        return proxy;
    return min(dfRocketBody(p),dfRocketFins(p));
}

vec3 nf(vec3 p)
{
    vec2 e = vec2(0,0.005);
    return normalize(vec3(df(p+e.yxx),df(p+e.xyx),df(p+e.xxy)));
}

void main( void ) {
    rocketRotation = sin(time)*.1;

    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5) / resolution.yy;

    vec3 pos = vec3(.1,.1,-5);
    vec3 dir = normalize(vec3(uv,1.0));
    
    float rx = -mouse.x*8.0 + time*.04 -.9;
    float ry = mouse.y*8.0 + time*.024+6.5;
     
    rotate(ry,pos.yz);
    rotate(ry,dir.yz);
    rotate(-rx,pos.xz);
    rotate(-rx,dir.xz);  
    rotate(.1,pos.xy);
    rotate(.1,dir.xy);  
    
    float dist=0.0,tdist = .0;
    
    for (int i=0; i<100; i++)
    {
         dist = df(pos);
           pos += dist*dir;
        tdist+=dist;
        if (dist<0.000001||dist>20.0)break;
    }
    
    vec3 materialColor = vec3(.0);
    vec3 orangeColor = vec3(1.5,.9,.0);
    
    float dRocketBody = dfRocketBody(pos);
    float dRocketFins = dfRocketFins(pos);
    float dRocket = min(dRocketBody, dRocketFins);
    
    
    float r = pow (length(pos.yz), 1.5);

    vec3 normal = nf(pos);
    
        //rocket
        if (dfRocketBody(pos)<dfRocketFins(pos))
        {
            if (pos.x<-.85)
                if (pos.x<-1.30)
                    materialColor = orangeColor + vec3(0.03 / r);
                else
                    materialColor = vec3(.9,.1,.1);
            else
            {
                if ((1.7>pos.x) && (pos.x>1.0))
                    materialColor = vec3 (.6,.1,.1);
                else
                    materialColor = vec3(.6);
            }
        }
        else
        {
            materialColor = vec3(.9,.1,.1);
            if (length (pos - 0.1 * vec3(0.0, normal.yz)) > length (pos)) { 
            
                materialColor -= vec3(1.5,.9,.0) * min(0.0, pos.x + 1.3) / r;
            }
        }

    
    float ao = df(pos+normal*.125)*8.0 +
        df(pos+normal*.5)*2.0 +
        df(pos+normal*.25)*4.0 +
        df(pos+normal*.06125)*16.0;
    
    ao=ao*.125+.5;
    
    vec3 color = ao * materialColor;
 
    if (dist>1.0) color = vec3(0.0);
    

    glFragColor = vec4(color, 1.0);

}
