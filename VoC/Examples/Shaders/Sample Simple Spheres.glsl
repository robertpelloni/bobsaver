#version 420

// original https://www.shadertoy.com/view/ttfSWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sphereNum 10.
#define sRadius 1.

float mt;

vec3 lightPos;
int numLights = 0;
 
vec3 spherePos[int(sphereNum)];
bool blinkID[int(sphereNum)];
int lightID[int(sphereNum)];

vec2 random(vec2 p)
{
    vec3 a = fract(p.xyx*vec3(221.37, 143.45, 339.61));
    a += dot(a, a+37.73);
    return fract(vec2(a.x*a.y, a.y*a.z));
}

float shadowSphere(vec3 ro, vec3 rd, vec3 p, float radius)
{
    vec3 d = p-ro;
    float b = dot(d, rd);
    if(b<0.)
        return 1.0;
       vec3 c = ro+rd*b;
    float s = length(c-p)/radius;
    return max(0.,(min(1.,s)-.7)/.3);
}

float shadow(vec3 ro, vec3 rd, float id)
{
    float v = 1.;
    for(float i=0.; i<sphereNum;i++)
    {
        if(blinkID[int(i)])
            continue;
        if(i!=id)
        {    
            float tt = mt+i*2.;
            float ds = shadowSphere(ro, rd, spherePos[int(i)], sRadius);
            v*=ds;
            if(ds==0.)
                return 0.;
        }
    }
    return v*v*(3.-2.*v);
}
vec3 sphere(vec3 ro, vec3 rd, vec3 p, float radius, float id)
{
    
    vec3 d = ro-p;
    float a = dot(rd, rd);
    float b = dot(d, rd);
    float c = dot(d,d)-radius*radius;
    
    float disc = b*b-a*c;
    if(disc<0.)
        return vec3(-1.);
    
    float sqrtDisc = sqrt(disc);
    float invA = 1.0/a;
    
    vec3 hit = (ro+(rd*(-b-sqrtDisc)*invA));
    
    if(blinkID[int(id)])
        return vec3(1.,length(p+hit-ro),0.);
    
    vec3 norm = normalize(hit-p);
    vec3 ref = reflect(rd,norm);

    float dist = length(hit-ro);
 
    float litv = 0.;
    vec3 light = normalize(lightPos-(hit));
    float lit = 0.;
    float spec = 0.;

    float shade = shadow(hit, light, id);
    if(shade>0.)
    {

        lit = max(0.,dot(light, norm))*shade;
        spec = pow(max(0.,dot(light, ref)),100.);
        litv+=lit*.5+spec;
    }
    for(int i=0; i<numLights; i++)
    {
        vec3 light = normalize(spherePos[lightID[int(i)]]-(hit));
        float lit = 0.;
        float spec = 0.;

        float shade = shadow(hit, light, id);
        if(shade>0.)
        {

            lit = max(0.,dot(light, norm))*shade;
            spec = pow(max(0.,dot(light, ref)),3.);
            litv+=(lit+spec)*.2;
        }
    }
    ref +=time*.2;
    ref *=3.;
    float fresnel = (1.-dot(norm,-rd));
    float wall = fresnel*fresnel*fresnel*smoothstep(.3,0.0,min(4.*length(.5-fract(ref.x)),4.*length(.5-fract(ref.y))));
    vec3 v = vec3(max(0.,litv+wall));
    

    return vec3(v.x, length(p+hit-ro),0.);
}
void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float lens = .99;
    uv *=lens+(1.-lens)*pow(dot(uv,uv),2.);
 
    vec2 suv = 4.*uv;
    suv +=time*.2;
    float muv = smoothstep(.1,0.0,min(4.*length(.5-fract(suv.x)),4.*length(.5-fract(suv.y))));
    vec3 col = vec3(.5+.2*muv);
    
    vec3 ro = vec3(0.,0.,-10.-(35.*(mouse*resolution.xy.y/resolution.y)));
    vec3 rd = normalize(vec3(uv.x,uv.y,3.));
    
    lightPos = vec3(3.,10.+sin(time*.2)*10.,-5.);
    
    mt = time*.75+sin(time*.5)*.7+2.*mouse.x*resolution.xy.x/resolution.x;
    
    float dep = 1000.;
    float halo = 0.;
    numLights = 0;
    for(float i=0.; i<sphereNum;i++)
    {
        float blink = fract(mt*length(random(vec2(i+1.))))<.1?1.0:0.;
        float tt = mt+i*2.;
        vec3 sp = vec3(4.*sin(tt*2.),4.*cos(tt*1.5),4.*cos(tt*2.));
        spherePos[int(i)] = sp;
        blinkID[int(i)] = blink>0.;
        if(blinkID[int(i)])
        {
            lightID[numLights]= int(i);
            numLights++;
            halo = max(0.,1.0-length(ro+rd*dot(sp-ro,rd)-sp)*.15);
        }
        
    }
    float keepHighest = 0.;
    for(float i=0.; i<sphereNum;i++)
    {
        if( blinkID[int(i)])
        {
            vec3 sd = ro+rd*dot(spherePos[int(i)] -ro,rd)-spherePos[int(i)];
            halo = 1./dot(sd,sd)*.25;
        }
        
        vec3 d = sphere(ro, rd, spherePos[int(i)] , sRadius, i);
        keepHighest = max(keepHighest, d.y);
        if(d.x>-1.)
            if(d.y<dep)
            {
                dep = d.y;
                d.y = (d.y-(ro.z+20.))/80.;
                col =mix(vec3(d.x,d.x,d.x),vec3(.5),d.y)+vec3(blinkID[int(i)]?1.:0.);
            }
        if(dep>keepHighest&&blinkID[int(i)])
        {
            col+=halo;//halo*halo*+(3.-2.*halo)*.1;
        }
    }
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
