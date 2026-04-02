#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( float n ) { return fract(sin(n)*753.5453123); }

// Slight modification of iq's noise function.
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + p.y*157.0;
    return mix(
                    mix( hash(n+  0.0), hash(n+  1.0),f.x),
                    mix( hash(n+157.0), hash(n+158.0),f.x),
            f.y);
}
float fbm(vec2 p, vec3 a)
{
     float v = 0.0;
     v += noise(p*a.x)*.50;
     v += noise(p*a.y)*.50;
     v += noise(p*a.z)*.125;
     return v;
}

float snow(vec2 uv,float scale,float speed)
{
    uv.x+=time*2.*speed/scale; 
    uv.y+=1.0;
    uv*=scale;vec2 s=floor(uv*0.6),f=fract(uv*0.6),p;float k=40.,d;
    p=0.5+.27*sin(31.*fract(sin((s+p+scale)*mat2(7.2,2.3,1.4,2.1))*7.3))-f;d=length(p);k=min(d,k);
    k=smoothstep(0.,k,sin(f.x+f.y)*0.0020);
        return k*(speed*0.98+0.02);
}

vec3 split(vec2 uv,float score)
{
    vec3 crit;
    //crit.x = (uv.x-mouse.x*2.0*0.0+0.0*1.0);
    
    //crit.x = (sin(uv.x + 0.0*fbm( uv + 0.5*time, vec3(1.0,2.0,4.0 ))) * 1.0) ;
    //crit.x = uv.x-mouse.x*2.0+1.0+0.1*(fbm( uv + 0.5*time, vec3(4.7,3.7,12.7 )*(1.0+2.0*abs(score)))-0.5);
    crit.x = uv.x+0.1*(fbm( uv + 0.5*time, vec3(4.7,3.7,12.7 )*(1.0+2.0*abs(score)))-0.5);
    crit.y = max(0.0,1.0-abs(crit.x*1.0));
    crit.x = sign(clamp(crit.x,-1.0,1.0));
    
    float scoreb = 1.0+min(score,0.0)+2.0*max(score,0.0);
    float scorer = 1.0-max(score,0.0)-2.0*min(score,0.0);    
    crit.z = mix(scoreb,scorer,crit.x*0.5+0.5);
    return crit;
}

void main(void){
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/resolution.xy; 
    vec3 finalColor=vec3(0);
    float c=smoothstep(0.1,0.0,clamp(uv.x*.01+.99,0.,.99));
    
    //vec3 sp = split(uv,mouse.x*2.0-1.0);
    vec3 sp = split(uv,0.0);
    float s = sp.x;
    float speed = sp.z;
    c+=snow(uv,s*2.,speed)*1.0;
    c+=snow(uv,s*4.,speed)*0.8;
    c+=snow(uv,s*6.,speed)*0.6;
    c+=snow(uv,s*8.,speed)*0.6;
    c+=snow(uv,s*10.,speed)*0.6;
    c+=snow(uv,s*12.,speed)*0.4;
    c+=snow(uv,s*14.,speed)*0.2;    
    
     c = clamp(c*200.0,0.2,1.2)-0.2;
    float cs = (sp.x+1.0)*0.5;
    vec3 colorLeft = vec3(c*0.4+0.6,0.0,0.0);
    vec3 colorRight = vec3(0.0,0.0,c*0.4+0.6);    
    
    finalColor = mix(colorLeft,colorRight,1.0-cs);
    finalColor += vec3(1.0,1.0,1.0)*(sp.y*c+1.0*pow(max(sp.y-0.95,0.0)*20.0,8.0));
    
    glFragColor = vec4(finalColor,1);
}
