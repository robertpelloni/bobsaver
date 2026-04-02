#version 420

// original https://www.shadertoy.com/view/WslGWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time (time + 100.0)

mat2 rotate(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));    
}

float hash(vec3 p)
{
    p  = fract(p * vec3(.16532, .17369, .15787));
    p += dot(p.xyz, p.yzx + 19.19);
    return fract(p.x * p.y * p.z);
}

float sdRoundBox(vec3 p, vec3 b, float r)
{
  vec3 d = abs(p) - b;
  return length(max(d, 0.0)) - r + min(max(d.x, max(d.y, d.z)), 0.0); 
}

float map(vec3 p)
{   
    p.xy *= rotate(sin(time * 0.2) * 0.3);
    p.z -= time * 2.8;
    vec3 ip  = floor(p / 3.0);
    p  = mod(p, 3.0) - 1.5;
    float rnd  = hash(ip) * 2.0 - 1.0;
    if (rnd < 0.4) return 0.5;
    p.xy *= rotate(time * 1.5 * rnd);
    p.yz *= rotate(time * 1.3 * rnd);
    float a = atan(p.y, p.x);
    p.xy += -0.05 * smoothstep(0.2, 0.0, abs(p.z)) * vec2(cos(a), sin(a));
    a = atan(p.z, p.y);
    p.yz += -0.05 * smoothstep(0.2, 0.2, abs(p.x)) * vec2(cos(a), sin(a));
    a = atan(p.x, p.z);
    p.zx += 0.05 * smoothstep(0.2, 0.1, abs(p.y)) * vec2(cos(a), sin(a));
    float size =hash(ip + vec3(123.123)) * 0.3 + 0.3;  
    return sdRoundBox(p,vec3(size), 0.1);
}

vec3 calcNormal(vec3 p )
{
    vec2 e = vec2(1, -1) * 0.001;
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

vec3 doColor(vec3 p)
{
    return vec3(1.0, 0.3, 0.1);
}

void main(void)
{
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 bg=vec3(1);
    vec3 ro = vec3(0, 0, 5);
    vec3 rd = normalize(vec3(p, -1.8));
    for (int j = 0; j < 5; j++)
    {
        float z = 0.0, d, i, ITR=60.0;
         for( i = 0.0; i < ITR; i++)
          {
            z += d = map(ro + rd * z);
            if(d < 0.001 || z > 30.0) break;
          }
        if(d < 0.001)
          {
              vec3 p = ro + rd * z;
             vec3 nor = calcNormal(p);
            vec3 li = normalize(vec3(1));
            vec3 col = doColor(p);
            col *= pow(1.0 - i / ITR, 2.0); 
                col *= clamp(dot(nor, li), 0.3, 1.0);
            col *= max(0.5 + 0.5 * nor.y, 0.0);
            col += pow(clamp(dot(reflect(normalize(p - ro), nor), li), 0.0, 1.0), 30.0);
            col *= exp(-z * z * 0.0001);
            col = pow(col,vec3(0.8));
            col = min(vec3(1), col * 3.0);
            bg += col;
        }
        ro.z -= 0.07;
    }
    bg = clamp(bg / 5.0, 0.0, 1.0);
    glFragColor = vec4(pow(bg,vec3(1.8))-0.1, 1.0);
}
