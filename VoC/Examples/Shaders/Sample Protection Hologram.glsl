#version 420

// original https://www.shadertoy.com/view/MdBSWV

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// "Protection hologram" by Alexander Alekseev aka TDM - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// math
float saturate(float x) { return clamp(x,0.0,1.0); }
float mul(vec2 x) { return x.x*x.y; }

mat3 fromEuler(vec3 ang) {
    vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
    m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
    m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
    return m;
}
bool ray_vs_quad(vec3 o, vec3 d, vec2 size, out vec3 p) {
    p = o - d * o.z / d.z;
    return bool(mul(step(abs(p.xy),size)));
}

// color
float textureHologram(vec2 t, vec3 e) {
    float r = length(t);
    t.x += e.x * 0.2;
    
    float l3 = smoothstep(0.5,0.52,r);
    float l0 = smoothstep(0.98,0.97,r) * l3;
    float l1 = saturate(sin(t.y*40.0)*8.0) * saturate(sin((t.y-t.x)*10.0)*8.0+6.0);
    float l2 = saturate(sin(t.y*160.0)*8.0) * saturate(sin((t.y+t.x)*40.0)*8.0+6.0);
    float l4 = smoothstep(0.42,0.4,r) * smoothstep(0.39,0.399,r);
    float l5 = smoothstep(1.0,0.99,r) * smoothstep(0.97,0.98,r);
    
    float sum = 0.0;
    sum += (1.0-l3) * 0.5;
    sum += l1 * l0;
    sum += l2 * l0 * (1.0 - l1) * 0.2;
    sum += l4 * 0.5;
    sum += l5;
    return sum;
}

// from iq's https://www.shadertoy.com/view/MsS3Wc
vec3 hue(in float h) {
    return clamp(abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);    
}

vec3 hologram(vec2 p, float sum) {
    float mask = (cos(p.y)*0.5+0.5) * (0.2+sum*0.8);
    return mix(vec3(0.6),hue(p.y*0.15),mask);
}

vec3 getObjectColor(vec3 p, vec3 n, vec3 e) {
    float sum = textureHologram(p.xy,e);
    
    // vec
    vec2 d = p.xy + (sum * 2.0 - 1.0);
    d.y += dot(e,n) * 5.5;
        
    // get holo color
    float bright = saturate(0.6 + sum * 0.4);
    vec3 color = hologram(d,sum) * bright;
    color *= pow(max(dot(e,-n),0.0),0.6);
            
    // reflection
    vec3 refl = reflect(e,n) + sum * 0.1; 
    //vec3 color_refl = textureCube(iChannel0,refl).xyz;
    vec3 color_refl = vec3(0.0,0.0,0.0);
    color = mix(color,color_refl,(1.0 - sum) * 0.2);    
        
    // lighting
    n.xz += (sum * 2.0 - 1.0) * 0.15;
    color += pow(max(dot(e,-normalize(n)),0.0), 20.0) * 0.6;
        
    return color;    
}

// main
void main(void) {
    vec2 iuv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    vec2 uv = iuv;
    uv.x *= resolution.x / resolution.y;    
    //vec2 mouse = iMouse.xy / iResolution.xy * 4.0 - 2.0;
    vec2 mouse = vec2(0.0,0.0);
        
    // ray
    vec3 ang = vec3(0.0,sin(time)*0.75,cos(time*1.5)*0.75);
    //if(iMouse.z > 0.0) ang = vec3(0.0,-mouse.y,mouse.x);
    mat3 rot = fromEuler(ang);
    
    vec3 ori = vec3(0.0,0.0,5.0);
    vec3 dir = normalize(vec3(uv.xy,-3.0));    
    ori = ori * rot;
    dir = dir * rot;
             
    // color
    vec3 p;
    vec3 color = vec3(0.0);
    if(ray_vs_quad(ori,dir,vec2(1.0),p)) color = getObjectColor(p,vec3(0.,0.,1.),dir);
               
    glFragColor = vec4(color,1.0);
}
