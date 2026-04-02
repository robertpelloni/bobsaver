#version 420

// original https://www.shadertoy.com/view/stsXRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define OCT 2
#define DEPTH 8.
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
    float dp=.25;
    vec3 sp = cd*dp;
    vec3 p = cp+sp;
    float d = 1.;
    float r = 1.;
    int cnt = 0;
    while(cnt<20 && d<DEPTH){
        r = turb(p, .001, .125, OCT, min(.1,d-1.));
        d +=r*dp+.1;
        p +=r*sp+.1;
        if(r<0.01){
            d+=r/0.01 *2.;
            break;
        }

        cnt++;
    } 
    return d;
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
    
    float slow = time*.25;
    vec3 kal = vec3(sin(slow+3.14),sin(slow*.91+1.95),sin(slow*.87+.45));
    vec3 col = mix(vec3(1.85*turb(target, .417, .02, OCT+1,.1)),.5+.5*kal,march(p,cdir)/DEPTH*1.5);

    col *=mix(vec3(1.),vec3(.75,.15,.01), dot(uv, uv));

    glFragColor = vec4(col,1.0);
}
