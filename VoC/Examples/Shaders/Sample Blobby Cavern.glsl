#version 420

// original https://www.shadertoy.com/view/NtfXRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCT 3
float hash(vec3 p)
{
    p  = fract(p * .1337);
    p += dot(p, p.zyx + 37.36);
    return fract((p.x + p.y) * p.z);
}
float noise(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);  
    vec3 u = smoothstep(0.,1.,f);
    
    vec2 oo = vec2(1.,0.);
    
    return mix(mix(mix(hash(i+oo.yyy),hash(i+oo.xyy),u.x),
                   mix(hash(i+oo.yxy),hash(i+oo.xxy),u.x),u.y),
               mix(mix(hash(i+oo.yyx),hash(i+oo.xyx),u.x),
                   mix(hash(i+oo.yxx),hash(i+oo.xxx),u.x),u.y),u.z);
}

float turb(vec3 p, float noiseThreshold, float noiseSoftness, int oct, float dist)
{
    float r = 0.0,
          w = 1.0, 
          s = 1.0,
          d = 0.0;
    for (int i=0; i<oct; i++)
    {
         r += w * noise(p);
         d += w;
         w *= 0.573;
         p *= 1.677;
     }
    r = abs(-1.+2.*r/d);
    return smoothstep(noiseThreshold,noiseSoftness+noiseThreshold,r)+(.1-dist);
}

float march(vec3 cp, vec3 cd){
    float dO=1.;
    vec3 p = cp;
    vec3 sp = cd;
    float sf = .05;
    for(int i=0; i<100; i++) {
        p += sp;
        float dS = turb(p, .01,.5, OCT, min(.1,dO-1.));
        sf = (1.*dS)*.1+.01;
        dO += sf;
        sp = cd*sf;
        if(dO>6.|| abs(dS)<0.001){
            p-=sp;
            sf = 0.001;
            sp = cd*sf;
            int cnt = 0;
            dS = 1.;
            while(cnt<10 && dS>0.001){
                cnt++;
                dO+=0.001;
                p+=sp;
                dS = turb(p, .01,.5, OCT, min(.1,dO-1.));
            }
            break;
        }
    }
    
    return dO;
}
vec3 norm(vec3 p, float dist){
    vec2 oo = vec2(.025,0.);
    float nx = turb(p+oo.xyy, .0,.5, OCT,dist);
    float ny = turb(p+oo.yxy, .0,.5, OCT,dist);
    float nz = turb(p-oo.yyx, .0,.5, OCT,dist);
    return -normalize(vec3(nx,ny,nz));
}
mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    vec2 ms = mouse*resolution.xy.xy/resolution.xy * 6.28;

    vec3 camera = vec3(0.);
    vec3 target = vec3(uv*(.5+.5*dot(uv,uv)),.25);
    target.yz *= Rot(-ms.y+sin(time*.25));
    target.xy *= Rot(-ms.x+cos(time*.5));
     
    vec3 cdir = normalize(camera-target);
   
    vec3 p = camera-vec3(0.,0.,time*.25);
    
    vec3 col = vec3(0.1,0.6,0.8);
    
    float depth = march(p,cdir);
    if(depth<6.){
        vec3 s = p+cdir*depth;
        vec3 l = s-p;
        float fo = max(0.,1.-.25*dot(l,l));
        float light = 0.;
        if(fo>0.){
            vec3 n = norm(s, 0.1);
            l = normalize(l);
            light = (.5+.5*dot(n,l))*fo;
        }
        col = mix(vec3(light),col,-.5+depth/4.);
   }

    glFragColor = vec4(col,1.0);
}
