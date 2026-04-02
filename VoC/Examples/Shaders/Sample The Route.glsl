#version 420

// original https://www.shadertoy.com/view/ttByRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sph(in vec3 pos, in float r){
     return length(pos) - r;
}

float cil(in vec2 pos, in float r){
     return length(pos) - r;
}

vec3 light(in vec3 pos){
    vec3 lightSrc = vec3(0.0, 0.0, -7.375);
    return normalize(lightSrc-pos);
}

mat2 rot(in vec3 pos){
    float co = cos(pos.x);
    float si = sin(pos.y);
    
    mat2 r = mat2(co, -si, si, co);
    
     return r;
}

vec3 repeat(vec3 pos, vec3 s){
    float r = 0.5;
    return (fract(pos/s-r)-r)*s;
}

float map(in vec3 pos){
    
    vec3 pos2 = pos;
    float dd = pos2.z - time * 5.;
    pos2.y += sin(dd*.75)*.3;
    pos2.x += sin(dd*.25);
    
    float d = -cil(pos2.xy, 1.5);
    
    vec3 pos3 = repeat(pos2, vec3(2.0));
    
    
    
    
    

    vec3 pos4 = repeat(pos3, vec3(2));
    
    //pos4.x = -sin(time);
    //pos4.z = (sin(time*2.));
    
    // pumping
    float r = sin(time*8.);
    if(r > .95) r = .95;
    else if (r < 0.6) r = 0.6;
    
        
    float rr = sin(time*8.)*.2+.3;
    float cov = cil(pos4.xy, rr);
    
    float scene1 = max(d, -sph(pos3, r));
    float scene2 = min(cov, scene1);
    
    return scene2;
}

vec3 normals(in vec3 pos){
    vec2 e = vec2(0.01, 0.0);
    float d = map(pos);
    vec3 n = d - vec3(
        map(pos - e.xyy),
        map(pos - e.yxy),
        map(pos - e.yyx)
    );
    
    return normalize(n);
}

float march(in vec3 ro, in vec3 rd){
    
    float t;
    for(int i = 0; i < 100; i++){
        vec3 pos = ro + rd*t;
        t += map(pos);
        
        if(t > 20. || t < 0.0) break;
    }
    
     return t;
}

void main(void)
{
    vec2 px = gl_FragCoord.xy/resolution.xy;

       px -= .5;

    px *= resolution.xy / resolution.x;

    vec3 ro = vec3(0., 0., 0.);
    vec3 rd = normalize(vec3(px, -1.0));
    
    ro.z -= time*8.;
    
    vec3 col = vec3(0);
    
    float t = march(ro, rd);
    if(t < 20. && t > 0.0){
        vec3 pos = ro + rd*t;
        col = vec3(dot(normals(pos), light(pos)));
    }

    glFragColor = vec4(col,1.0);
}
