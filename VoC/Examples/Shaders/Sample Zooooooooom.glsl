#version 420

// original https://www.shadertoy.com/view/wdj3Wc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento

#define FAR 60.0
#define DISTANCE_BIAS 0.75

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float map(vec3 rp)
{
    vec3 pos = rp - vec3(0.0, 0.0, 0.0);
    vec3 b = vec3(1.9);
    
    pos.x += sin(pos.z + time*0.6)*0.56;
    pos.y += cos(pos.z + time*0.6)*0.56;
    
    pos = mod(pos, b)-0.5*b;
    
    float res = length(pos)-0.5;
    
    return res;
}
vec3 getNormal(vec3 p)
{
    vec2 e = vec2(0.0035, -0.0035); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

vec3 color(vec3 ro, vec3 rd, vec3 norm, float t)
{
    vec3 lp = ro + vec3(0.0, 0.0, -1.0) * 10.; 
    
    vec3 ld = normalize(lp - (ro + rd*t));
    
    vec3 p = (ro + rd * t);
    
    vec3 pb = mod(p, vec3(8))-0.5*vec3(8);
    
    // color stuff
    float diff = max(dot(norm, ld), 0.0);
    
    vec3 oCol = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), pb);
    
    vec3 col;
    
    col = oCol*diff;
    
    return col;
    
}

void main(void)
{
    vec2 uv = 1.1 * vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y; 
   
    vec3 ro = vec3(0.0, 0.0, -3.0); 
    vec3 rd = normalize(vec3(uv,2.0));
    
    rd.xy *= rot(time*0.15);
    ro.z += time*1.4;
    
    
    // march stuff
    float t = 0.0; 
    float d; 
    
    
    // glow stuff
    float minDist = 999.0; 
  
    vec3 glowCol = vec3(0);
    
    float g = 1.0;
    
    vec3 bg = vec3(0.4, 0.4, 0.1);
    
    float fog = 0.0;
    
    float oWidth = 0.2;
    float softness = 0.4;
    
    // march
    for (int i = 0; i < 31; i++)
    {
        d = map(ro + rd*t);
        
        minDist = min(minDist, d); 
        minDist = clamp(minDist, 0.02, d); 
        if(abs(d)<0.003) 
        {
            minDist = abs(d);
            break;  
        }
        if(t>FAR) 
        {
            minDist = min(minDist, d);
            t = FAR;
            break;
        }
        
        t += d * DISTANCE_BIAS;
        
        // Add Glow
        if(d > minDist && abs(d) > 0.15)
        {
            fog = smoothstep(0.41, 0.0, t / FAR);
            
            glowCol += vec3(0.6, 0.0, 0.0) 
                * smoothstep(oWidth,oWidth-softness, minDist) * fog
                   ;
            g++;
        }
    }
    
   
    glowCol /= g;
    
    vec3 col = vec3(0); 
    
    vec3 norm = getNormal(ro + rd * t); 
   
    col = color(ro, rd, norm, t);
    
    col += glowCol*80.0;
    
    // crap reflection
    ro += rd*t;
    
    rd = reflect(rd, norm);
    
    float rt = 0.0;
    d = 0.0;
    for (int i = 0; i < 25; i++)
    {
        d = map(ro + rd * rt);
        
        if(abs(d) < 0.0001)
        {
             break;   
        }
        if(rt > FAR)
        {
             break;   
        }
        
        rt += d;
        
    }
    
    norm = getNormal(ro + rd * rt); 
    
   
    col *= mix(col, color(ro, rd, norm, rt), 0.6);
    col = mix( col, vec3(0.0,0.0,0.9), 1.0 - exp( -0.0003*t*t*t ) );
    col = mix( col, vec3(0), 1.0 - exp( -0.01*rt*rt*rt ) );
    
    col /= 5.0;
    
    
         
    glFragColor = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
 
}
