#version 420

// original https://www.shadertoy.com/view/4t3XRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MARCH_EPS 0.007
#define MARCH_STEP 0.25
#define FAR 8.0

#define time time

const vec2 res = vec2(1024, 768);

float map (vec3 p) {
    p += sin(p.yzx * 5.0  - time * 0.41) * 0.15;
    p += sin(p.zxy * 9.0  - time * 0.47) * 0.065;
    p += sin(p.xyz * 17.0 - time * 1.43) * 0.0275;
    p += sin(p.yzx * 33.0 - time * 0.11) * 0.01475;
    p += sin(p.zyx * 65.0 - time * 0.17) * 0.01075;
    p += sin(p.xzy * 129. - time * 0.13) * 0.00700;
    p += sin(p.yzx * 257. - time * 0.05) * 0.00400;
    return length(p) - 1.0;
}

float trace(vec3 ro, vec3 rd, inout float close){
    float d, t = 1.2;
    
    for (int i = 0; i < 100; i++){
        d = map(ro + rd * t);
        if (abs(d) < MARCH_EPS || t > FAR) break;
        close = min(close, d);
        t += d * MARCH_STEP;
    }
    
    return (t+1.0) * step(d, MARCH_EPS) - 1.0;
}

void main(void)
{    
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    float cost = cos(time * 0.7);
    float sint = sin(time * 0.7);

    vec3 ro = 3.0 * vec3(sint, 0.0, cost);
    vec3 rd = normalize(vec3(uv, -1.5));
    
    rd.xz *= mat2(cost, sint, -sint, cost);
    
    float close = 4.0;
    float t = trace(ro, rd, close);
    if (t > 0.0){
        vec3 end = ro + rd * t;
        
        const vec2 eps = 0.01 * vec2(-1.0, 1.0);
        vec3 nml = normalize(eps.xxx * map(vec3(end + eps.xxx)) + 
                              eps.yyx * map(vec3(end + eps.yyx)) + 
                             eps.xyy * map(vec3(end + eps.xyy)) + 
                             eps.yxy * map(vec3(end + eps.yxy)));
                
        float dp, ao = (map(end + nml * 0.05) - map(end)) * 20.0;

        vec3 lig = vec3(ao * 0.3);
        dp = max(0.0, dot(nml, vec3(0.57735, 0.57735, -0.57735)));
        lig += vec3(0.6, 0.4, 0.2) * (dp*0.7 + dp*dp*dp*0.3);
        
        dp = max(0.0, dot(nml, vec3(-0.57735, -0.57735, -0.57735)));
        lig += vec3(0.2, 0.4, 0.6) * (dp*0.7 + dp*dp*dp*0.3);

        dp = max(0.0, nml.z);
        lig += vec3(0.1, 0.4, 0.1) * (dp*0.7 + dp*dp*dp*0.3);
        

        //float l = 0.3 + 0.7 * dot(ro + rd * t, vec3(-0.57735));
        //l = max(0.0, l);
        glFragColor = vec4(lig, 1.0);
    } else { 
        vec3 aur = vec3(0.4, 0.5, 0.4) / (close + 1.0);
        aur += vec3(0.5, 0.3, 0.4);    
        glFragColor = vec4(aur, 1.0);
    }
}
