#version 420

// original https://www.shadertoy.com/view/tttGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(ang) mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
#define pi 3.14159

float sdCyl(vec3 p, float r, float h)
{
     float d = length(p.xz) - r;
    return max(max(d, p.y - h), -p.y - h); 
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float branch(inout vec3 p, inout float scale)
{
    //p.xz *= rot(time);
    float d = sdCyl(p + vec3(0.0, 1.0, 0.0), 0.1, 1.8);
    p.y += 2.0;
    scale = 1.0;
    for(int i = 0; i < 4; ++i){
          
        float rot = sin(float(i * 10) + time) * 0.01;
        p.xz = abs(p.xz);
        p.y -= 2.8;
        p.yz *= rot(pi * 0.25 + rot * 2.0);
        p.xz *= rot(pi + rot * 4.0);
        p.xy *= rot(pi * 0.2 + rot);
        
        vec3 n = normalize(vec3(1.0 + float(i), 0.0, 1.0 + float(i)));
        p -= 2.0 * max(0.0, dot(p, n)) * n;
        d = smin(d, sdCyl(p, 0.05, 1.8) / scale, 0.1);
        p *= 1.5;
        scale *= 1.5;
    }
     p.xz = abs(p.xz);
     p.y -= 2.8;
     p.yz *= rot(pi * 0.25);
     p.xz *= rot(pi);
     p.xy *= rot(pi * 0.20);
    return d;
}

float matId;
float map(vec3 p)
{
   matId = 0.0;
   vec3 rp = p;
    
   
    float scale;
    float d = branch(rp, scale);
    float d1 = (length(rp + vec3(0.0, 0.2, 0.0)) - 0.6) / scale;
       if(d1 < d) matId = 1.0;
    d = smin(d, d1, 0.2);
    return d;
}

vec3 norm(vec3 p)
{
     vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
  
    vec3 r0 = vec3(0.0, 1.0, -9.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    
    vec2 mouse = 10.0 * (mouse*resolution.xy.xy / resolution.xy);
    r0.xz *= rot(mouse.x);
    rd.xz *= rot(mouse.x);
    float d = 0.0;
    vec3 col = vec3(0.5, 0.7, 1.0);
   
    for(int i = 0;i  < 100; ++i)
    {
        vec3 p = r0 + d * rd;
        float t = map(p);
        d += t;
        
        if(t < 0.001){
            vec3 color = vec3(0.9, 0.01, 0.01);
            if(matId < 0.5)  color = vec3(0.2, 1.0, 0.1);
            vec3 n = norm(p);
            vec3 ld = vec3(0.5, 0.5, -0.5);
            vec3 h = normalize(ld - rd);
             
            float diffuse = max(dot(n, ld), 0.0);
            float specular = max(dot(n, h), 0.0);
            col += (diffuse + specular * 0.25);
            
            col += (n.y * 0.5 + 0.5) * 0.;
            col *= color;
            break;
        }
        if(d > 100.0){
            d = 100.0;
            break;
        }
            
    }
    float fog = exp(-d * 0.01) * 0.18;
    col *= fog * 2.0;
    col = pow(col, vec3(0.4545));
    glFragColor = vec4(col,1.0);
}
