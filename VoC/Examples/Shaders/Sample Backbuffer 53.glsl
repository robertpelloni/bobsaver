#version 420

#define PI 3.14152
#define PI2 6.28318530718
#define GS 3.0 //in pixel unit
uniform vec2 resolution;
uniform sampler2D backbuffer;///min:l;mag:l;s:c;t:c; 
uniform vec2 mouse;
uniform float time;
uniform float startRandom;

out vec4 glFragColor;

vec2 touch = mouse *resolution.xy;

vec2 q(vec2 v)
{
    return floor(v/GS+0.5)*GS;
}

vec2 randDir(vec2 seed)
{
    seed += vec2(1.0,1.0)*startRandom*100.0;
float angle = PI2 * fract(sin(dot(seed.xy,vec2(12.9898,78.233)))*471.522) +time;
return vec2(cos(angle),sin(angle));
}

vec3 rand01(float seed)
{
    seed += startRandom*10.0;
    vec3 ret;
    ret.x = fract(sin(seed*79007.423)*7984.12);
    ret.y = fract(sin(seed*81121.217)*4495.32);
    ret.z = fract(sin(seed*79512.122)*6173.29);
return ret;
}

vec2 dither(void)
{
return randDir(gl_FragCoord.xy + vec2(time,2.24-7.80*time));
}

vec2 toDir(vec2 rg)
    {
        return clamp(rg*2.0 - 1.0, -1.0,1.0);
    }

vec2 toCol(vec2 dir)
    {
        return clamp(dir*0.5 + 0.5,0.0,1.0);
    }

vec2 rotateDir(vec2 v,float a)
{
    float ca = cos(a);
    float sa =sin(a);
    return mat2(vec2(ca,sa),vec2(-sa,ca))*v;
}

vec3 paintMouse(vec2 fc,float s)
{
    return rand01(time)*smoothstep(0.0,1.0,1.0-length(touch-fc)/10.0);
}

bool cMax(vec3 cref,vec3 ccomp)
{
    //return dot(ccomp-cref,vec3(1.0,1.0,1.0))>=0.00;
    
    return dot(vec3(0.1,0.1,0.1),cross(cref,ccomp))>0.0;
}

void main(void) {
    vec4 fc = vec4(gl_FragCoord.xy,gl_FragCoord.xy/resolution.xy);
    
    vec2 pq = q(fc.xy) + vec2(0.1,0.1);
     vec3 c[5];
    c[0] =texture2D(backbuffer,pq/resolution.xy).xyz ;
    c[1] =texture2D(backbuffer,(pq+vec2(1.0,0.0))/resolution.xy).xyz ;//right
    c[3] =texture2D(backbuffer,(pq+vec2(-1.0,0.0))/resolution.xy).xyz ;//left
    c[2] =texture2D(backbuffer,(pq+vec2(0.0,1.0))/resolution.xy).xyz ;//up
    c[4] =texture2D(backbuffer,(pq+vec2(0.0,-1.0))/resolution.xy).xyz ;//down
    
    float coef=0.0;
    vec3 cf= vec3(0.0);
    if (cMax(c[0],c[1]))
        {
        cf+=c[2];
            coef++;
        }
    if (cMax(c[0],c[2]))
        {
        cf+=c[3];
            coef++;
        }
    if (cMax(c[0],c[3]))
        {
        cf+=c[4];
            coef++;
        }
    if (cMax(c[0],c[4]))
        {
        cf+=c[1];
            coef++;
        }
    
    vec3 color ;
        
    if (coef==0.0 )
        color = (c[1]+c[2]+c[3]+c[4])*0.25;
    else if (coef==4.0)
        color = (c[1]+c[2]+c[3]+c[4])*0.25;
    else
        color = cf/coef;
    

    

color+=paintMouse(fc.xy,50.0);

    color -= vec3(1.0,1.0,1.0)*0.000;
    glFragColor = vec4(color, 1.0);
}
