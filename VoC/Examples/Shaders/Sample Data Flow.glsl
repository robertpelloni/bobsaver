#version 420

// original https://www.shadertoy.com/view/msycDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RM_STEPS 256.

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

// hash function from: https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3){
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3){
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec3 hash31(float p){
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

float hash11(float p){
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float beat(float a, float b, float t){
    return smoothstep(0.,a,t)*smoothstep(b,0.,t-a);
}

vec2 path(float z){
    float w = 0.05;
    float r = 4.;
    float s = w*z;
    return r*vec2(
        cos(s)*sin(0.5*s),
        sin(s)*cos(0.7*s)*sin(0.3*s)
    );
}

// x = dist, y = id
vec2 map(vec3 p){
    float d = 1e9;
    
    vec2 tun = p.xy - path(p.z);
    d = 4. - length(tun);
    
    return vec2(d, 0.);
}

float glowAcc = 0.;

// x = dist to itsc, y = i/steps, z = id
vec3 raymarch(vec3 ro, vec3 rd, float maxT){
    float t = 0.;
    
    for(float i = 0.; i < RM_STEPS && t < maxT; ++i){
        vec3 p = ro + rd*t;
        vec2 hit = map(p);
        if(hit.x < 0.03){
            return vec3(t, i/RM_STEPS, hit.y);
        }
        t += hit.x;
        
        float d = hit.x;
        float h = 0.3;
        if(abs(d) < h) glowAcc += (h - abs(d))/30.;
    }
    return vec3(-1.);
}

float pattern(float x){
    //return step(mod(x, 5.), 1.);
    float w = 3.;
    float t = 8.;
    return smoothstep(0.,w,mod(x,t))*step(mod(x,t),w);
}

vec3 normal(vec3 p){
    vec2 h = vec2(0.001, 0.);
    return normalize(vec3(
        map(p + h.xyy).x - map(p - h.xyy).x,
        map(p + h.yxy).x - map(p - h.yxy).x,
        map(p + h.yyx).x - map(p - h.yyx).x
    ));
}

vec3 render(vec3 ro, vec3 rd, inout vec3 hit, float iter){
    hit = raymarch(ro, rd, 100.);
    
    vec3 p = ro + rd*hit.x;
    
    vec3 finalCol = vec3(0.);
    
    // very basic antialiasing
    for(float j = 0.; j < iter; j++){
        vec3 col = vec3(1.);
        
        p += (hash31(j+time)*0.5-0.5)*0.005;

        col *= 1. - hit.y;
        
        vec3 q = p;
        q.xy -= path(q.z);
        float a = atan(q.y,q.x);
        a /= 3.141492*2.;
        float n = 100.;
        float i = floor(a*n);
        vec3 c0 = clamp(hash31(i)+0.5,0.,1.);
        col *= c0;

        float h = hash11(i);
        float o = h*50.;
        float v = (h*0.5+0.5)*5.;
        float pat = pattern(p.z*0.1 + o - time*10.);
        col = mix(vec3(0.02), col, pat);
        
        float bt = mod(time + h*33., 30.);
        col = mix(col, vec3(1.5,0.3,0.4), beat(0.1,0.5,bt));

        float d = abs(a - (i+0.5)/n);
        float w = 0.35/n;
        float lines = step(d,w);
        col = mix(vec3(0.01), col, lines);

        float b = step(1., mod(p.z, 5.));
        col = mix(vec3(0.01), col, b);
        
        finalCol += col;
    }
    
    finalCol /= iter;
    
    return finalCol;
}

float fresnel(vec3 n, vec3 v){
    float n1 = 1.;
    float n2 = 1.5;
    float r0 = (n1-n2)/(n1+n2); r0 *= r0;
    float d = max(0., dot(n, v));
    return r0 + (1.-r0)*pow(1.-d, 5.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;

    vec3 col = vec3(0.);
    
    float cz = time*40.;
    vec3 ro = vec3(path(cz), cz);
    
    float o = 2.;
    vec3 lookAt = vec3(path(cz+o), cz+o);
    
    vec3 forward = normalize(lookAt - ro);
    vec3 right = vec3(forward.z, 0., -forward.x); // 90° rotation
    vec3 up = cross(forward, right);
    
    vec3 rd = normalize(uv.x*right + uv.y*up + forward);
    
    vec3 hit;
    col = render(ro, rd, hit, 10.);
    float t0 = hit.x;
    
    vec3 fogCol = vec3(0.2,0.5,0.6);
    
    vec3 p = ro + rd*hit.x;
    vec3 n = normal(p);
    
    float fres = fresnel(n, -rd);
    
    ro = p + n*0.04;
    vec3 rcol = vec3(0.);
    
    if(hit.x > 0.){
        float Nref = 10.;
        for(float i = 0.; i < Nref; i++){
            vec3 rnd = (hash31(i+time)*0.5-0.5)*0.005;
            rd = reflect(normalize(rd + rnd), n);
            rcol += render(ro, rd, hit, 1.)*0.6;
        }
        col = mix(col, rcol/Nref, fres);
        
        float fog = smoothstep(5.,100.,t0);
        col = mix(col, fogCol, fog);
    } else {
        col = fogCol;
    }
    
    // gamma
    col = pow(col, vec3(1./2.2));

    
    glFragColor = vec4(col,1.0);
}
