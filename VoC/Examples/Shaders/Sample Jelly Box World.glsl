#version 420

// original https://www.shadertoy.com/view/Wsjfzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy

float box( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map(vec3 rp){
    vec3 id = floor(rp/7.);
    
    
    
    float altz = mod(id.z, 2.);
    float altx = mod(id.x, 2.);
   
    if(altz == 0.)
         rp.y += time;   
    else
        rp.y -= time;   
    
    if(altx == 0.)
         rp.x += time;   
    else
        rp.x -= time;   
    
    
    rp = mod(rp, vec3(7.))-vec3(7.)*0.5;
    
    
    
    return box(rp, vec3(1.))-.2;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    
    vec3 rd = normalize(vec3(uv, 0.8));
    
    vec3 ro = vec3(0.);
    ro.z+=time*2.;

    vec3 col = vec3(0);
    
    float t = 0., d = 0., td = 0.;   
    
    const float h = 0.1;
    
    vec3 p = vec3(0);
    
    for(int i = 0; i < 100; i++){
        p = ro + rd*t;
        d = abs(map(p));        
        
        d = max(d, 0.003);
        
        if(d < h){
            float ld = h - d;
            float w = (1. - td)*ld;    
            td += w;
            
        }
        col += 0.5 + 0.5*cos(vec3(0.5, 1., 0.1)*(t+ro.z)+vec3(1., 0., 3.) );
        
        t += d*.7;
        if(t > 45.){
            t = 45.;
            break;
        }
        
    }
    
    
    col*=0.012;
    col = pow(col, vec3(5));
    col = 1.-exp(-col*2.);
    
    col *= 1.-abs(uv.y*1.2);
    
    glFragColor = vec4(sqrt(clamp(col, .0, 1.)), 1.);

}

