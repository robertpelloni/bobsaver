#version 420

// original https://www.shadertoy.com/view/ldjGDw

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// Rendezvous. By David Hoskins. Jan 2014.
// A Kleinian thingy, breathing, and with pumping arteries!

#define CSize  vec3(.808, .8, 1.167)

float Hash(vec2 p)
{
    return fract(sin(dot(p, vec2(32.3391, 38.5373))) * 74638.5453);
}

float Map( vec3 p )
{
    float scale = 1.0;

    for( int i=0; i < 7;i++ )
    {
        p = 2.0*clamp(p, -CSize, CSize) - p;
        float r2 = dot(p,p);
        float k = max(1.1/r2, 1.0);
        p     *= k;
        scale *= k;
    }
    
    float rxy = length(p.xy)-5.0;
    float n = length(p.xy) * p.z;
    rxy = max(rxy, -(n) / (length(p))-.05+sin(time*2.0+23.5*p.z)*.01);
    return (rxy) / abs(scale);
}

vec3 Colour( vec3 p )
{
    float scale = 1.0;
    //vec4  col=vec4(0.0);
    float col = 0.0;
    float r2=dot(p,p);
    float rmin=1000.0;
    for( int i=0; i < 10;i++ )
    {
        vec3 p1= 2.0 * clamp(p, -CSize, CSize)-p;
        col += abs(p.z-p1.z);
        p = p1;
        r2 = dot(p,p);
        float k = max(1.1/r2,1.);
        p      *= k;
        scale *= k;
        r2 = dot(p, p);
        rmin = min(rmin, r2);
    }
    return mix(vec3((rmin)),(0.5+0.5*sin(col*vec3(.647,-1.072,5.067))),.8);//vec3(sqrt(rmin));//*col.xyz/(iters+1.);
}

float trace( in vec3 ro, in vec3 rd )
{
    float precis = 0.0008;
    float h=precis*.2;
    float t = 0.01;
    float res = 2000.0;
    bool hit = false;

    for( int i=0; i< 150; i++ )
    {
        if (!hit && t < 8.0)
        {
            h = Map(ro + rd * t);
            t += h * .75;
            if (h < precis)
            {
                res = t;
                hit = true;;
            }
            precis *= 1.03;
        }
    }
    return res;
}

//----------------------------------------------------------------------------------------
float Shadow( in vec3 ro, in vec3 rd, float dist)
{
    float res = 1.0;
    float t = 0.01;
    float h = 0.0;
    
    for (int i = 0; i < 10; i++)
    {
        if(t < dist)
        {
            h = Map(ro + rd * t);
            res = min(2.0*h / t, res);
            t += h+.007;
        }
    }    
    return clamp(res, 0., 1.0);
}

vec3 Normal( in vec3 pos)
{
    vec3  eps = vec3(0.0002,0.0,0.0);
    vec3 nor = vec3(Map(pos+eps.xyy) - Map(pos-eps.xyy),
                    Map(pos+eps.yxy) - Map(pos-eps.yxy),
                    Map(pos+eps.yyx) - Map(pos-eps.yyx));
    return normalize(nor);
}

float LightGlow(vec3 light, vec3 ray, float t)
{
    float ret = 0.0;
    if (length(light) < t)
    {
        light = normalize(light);
        ret = pow(max(dot(light, ray), 0.0), 3000.0)*1.5;
    }
        
    return ret;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    
    float time2 = sin(1.6+time*.05)*9.5;
    // camera
    vec3 origin = vec3( 1.2, time2+1.8, 2.5);
    vec3 target = vec3(.0, 0.0, 2.5);
    
    vec3 cw = normalize( target-origin);
    vec3 cp = normalize(vec3(0.0, 0.0, 1.));
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = cross(cu,cw);
    vec3 ray = normalize( p.x*cu + p.y*cv + 2.6*cw );    
    
    vec3 lightPos = origin+vec3(-0.56-cos(time2*2.0+1.3)*.3, -1.5, .25+cos(time2*2.0)*.3);
    float intensity = .8+.3*sin(time2*10.0);

    // trace    
    vec3 col = vec3(0.0);
    float t = trace(origin, ray);
    if(t < 2000.0)
    {
        vec3 pos = origin + t * ray;
        vec3 nor = Normal(pos);

        vec3  light1 = lightPos-pos;
        float lightDist = length(light1);
        vec3  lightDir = normalize(light1);
                
        float key = clamp( dot( lightDir, nor ), 0.0, 1.0 ) * intensity;
        float spe = max(dot(reflect(ray, nor), lightDir), 0.0);
        float amb = max(nor.z*.1, 0.0);
        float ao = clamp(Shadow(pos, lightDir, lightDist) / max(lightDist-1.5, 0.2), 0.0, 1.0);

        vec3 brdf  = vec3(1.0)*amb;
        brdf += vec3(1.0)* key * ao;

        col =  Colour(pos) * brdf + pow(spe, 18.0)*ao*.4;
        col *= exp(-0.5*max(t-1.0, 0.0));
    }
    col += LightGlow(lightPos-origin, ray, t) * intensity;
    col = clamp(col, 0.0, 1.0);
    col = mix( col, smoothstep( 0.0, .5, col ), .5);
    col = sqrt(col);
    
    t = 50.0*q.x*q.y*(1.0-q.x)*(1.0-q.y);
    col *= pow(t, 0.25);

    
    glFragColor=vec4(col,1.0);
}
