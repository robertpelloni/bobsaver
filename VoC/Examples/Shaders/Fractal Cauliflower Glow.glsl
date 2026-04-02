#version 420

// original https://www.shadertoy.com/view/WlfXW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rotate(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float g=0.0;

float deLineBox(vec3 p, vec3 s, float r, float t)
{    
    for (int i=0;i<6;i++){
        p = abs(p)-s;
        mat2 m = rotate(sin(t*0.8+0.3*sin(t))*2.0+0.8);
        p.xy*=m;
        p.yz*=m;
        s*=0.5;
    }
    p = abs(p)-s;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;        
     p.z = max(0.0,p.z);
    return length(p)-r;
 }

float map(vec3 p)
{
    float de = deLineBox(p,vec3(4.5),0.01,time);
    g +=0.1/(0.3+de*de*10.); // Distance glow by balkhan
    return deLineBox(p,vec3(4.5),0.06,time+0.3);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 ro = vec3(0.0, 0.0, 25.0+sin(time*0.8+sin(time*0.5)*0.8)*5.0);
    ro.xz*=rotate(time*0.3);
    ro.xy*=rotate(time*0.5);
    vec3 w = normalize(-ro);
    vec3 u = normalize(cross(w,vec3(0,1,0)));
     vec3 rd = mat3(u,cross(u,w),w)*normalize(vec3(uv, 3));
    vec3 col = vec3(0.05);
    float t = 0.0, d;
     for(int i = 0; i < 64; i++)
      {
        t += d = min(map(ro + rd * t),1.0);
        if(d < 0.001) break;
      }
    col += vec3(0,0.7,0.3)*g*0.25;
    col = clamp(col,0.0,1.0);
    glFragColor = vec4(col,1);
}
