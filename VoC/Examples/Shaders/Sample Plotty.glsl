#version 420

// original https://www.shadertoy.com/view/7dcGRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define max2(v) max((v.x),(v.y))
#define cos1(x) (cos((x))*.5+.5)

const float pi = acos(-1.);
const float pi2 = pi*2.;

mat2 rot(float a)
{
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}

float circle(vec2 p, float r)
{return length(p)-r;}

float box(vec2 p, vec2 b)
{
p=abs(p)-b;
return max(p.x,p.y)+length(max(p,0.));
}

float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

float sdf(float d, float w)
{
    return smoothstep(0.,w,d);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/max2(resolution.xy);
    
    float w = fwidth(uv.y);

    vec3 col = vec3(0);
    
    
    
    float d[] = float[](1e3,1e3);
    
    {
        vec2 p = uv;
        float k = cos(time*2.);
        k = 2.*abs(k)-1.;
        p.y -= k*.45;
        float f = circle(p,.1);
        
        d[0] = min(d[0],circle(p,.1));
        p = rot(cos(time*2.+pi)*pi2)*p;
        d[1] = min(d[1],box(p,vec2(.1-w*7.5))-w*15.);
    }
    
    {
        vec2 p = uv;
        float k = 24.;
        d[0] = smin(d[0],-p.y,k);
        d[1] = smin(d[1],p.y,k);               
    }
    
    float mask = sdf(uv.y,w*2.);
    
    float d0 = sdf(d[0],w);
    float d1 = sdf(d[1],w);
    float fd = mix(1.-d0,d1,mask);
    
    col += fd;

    
    glFragColor = vec4(col,1.0);
}
