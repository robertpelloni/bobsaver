#version 420

// original https://www.shadertoy.com/view/7sXGRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MARCH_STEP = 35;
const int FBM_STEP = 5;

float hash(vec2 uv){
    float a = dot(uv, vec2(231.02384, 339.23918));
    return fract(sin(a)*3039.39482);
}

float noise(vec2 uv){
    vec2 pf = floor(uv);
    vec2 pr = fract(uv);
    vec2 s = pr*pr*(3.0 - 2.0*pr);
    float a = hash(pf);
    float b = hash(pf + vec2(1.0, 0.0));
    float c = hash(pf + vec2(0.0, 1.0));
    float d = hash(pf + vec2(1.0, 1.0));
    return mix(mix(a,b,s.x), mix(c,d,s.x), s.y);
}

float fbm(vec2 p){
    float res = 0.0;
    float amp = 1.0;
    p += vec2(noise(p+time), noise(p+3.0))*0.2;
    for(int i=0; i<FBM_STEP; i++){
        vec2 v = vec2(1.0, 0.45)*time*2.0;
        res += amp * abs((2.0*noise(p+v))-1.0);
        amp *= 0.5;
        p *= 2.0;
    }
    res = min(res*0.6, 1.0);
    return 1.0 - res;
}

float GetDist(vec3 p){
    vec2 uv = p.xz + vec2(0.3, 0.0)*time;
    vec2 uv2 = p.xz + vec2(-0.4, -0.15)*time;
    float a = fbm(uv*0.5)*0.3 + fbm(uv2)*0.2;
    return max(p.y - a, 0.0);
}

vec3 GetNormal(vec3 p){
    vec2 d = vec2(0.001, 0.0);
    vec3 n = vec3(GetDist(p + d.xyy) - GetDist(p - d.xyy),
                    GetDist(p + d.yxy) - GetDist(p - d.yxy),
                        GetDist(p + d.yyx) - GetDist(p - d.yyx));
    return normalize(n);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0 - resolution.xy)/max(resolution.x, resolution.y);
    vec3 cp = vec3(sin(time*0.34), 4.5 + sin(time)*0.8, -5.0);
    vec3 dir = vec3(uv.x, uv.y -0.34 + cos(time*0.89)*0.056, 1.0);
    
    vec3 ray = cp;
    float hit=0.0;
    float dist = 100.0;
    vec3 normal = vec3(0.0, 0.0, 0.0);
    float alpha = 0.0;
    float z = 0.0;
    
    for(int i=0; i<MARCH_STEP; i++){
        dist = GetDist(ray);
        if(dist < 0.001){
            alpha = 1.0;
            normal = GetNormal(ray);
            break;
        }
        z += dist;
        ray += dist*dir;
    }
    
    z = min(z*0.01, 1.0);
    vec3 zColor = z*vec3(0.6, 0.8, 1.0) + uv.y*0.5;
    
    normal = normalize(normal);
    
    float fre = 1.0 - dot(normal, normalize(cp));
    fre = max(pow(fre, 2.0),0.0);
    
    //なんかしらんけど上手くいかなくて誤魔化した
    fre = clamp(fre, 0.0, 1.0);
    if(fre==1.0) fre = 0.0;
    //-----------------------------------------------
    
    
    float diff = dot(normal, vec3(0.0, 1.0, 0.0))*0.4 + 0.6;
    diff = max(diff, 0.0);
    
    
    vec3 col = mix(vec3(0.01, 0.35, 0.7), vec3(0.05, 0.68, 1.0), diff) + zColor + fre;
    
    glFragColor = vec4(col,1.0);
}
