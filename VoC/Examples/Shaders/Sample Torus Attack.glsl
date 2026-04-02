#version 420

// original https://www.shadertoy.com/view/3tl3Wr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float reptorus(vec3 p, vec2 t) {
    
      float tr = 25.0;
      float htr = tr * 0.5;
      float px = mod(p.x + htr, tr) - htr;
      float py = mod(p.y + htr, tr) - htr;
      float pz = mod(p.z + htr, tr) - htr;
    
      p = vec3(px, py, pz);       
      
      
        vec2 q = vec2(length(p.xz)-t.x,p.y);
        return length(q)-t.y;
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float trace(vec3 p) {
    float d = 99999.0;
    
    
    float s1 = reptorus(vec3(p) * mat3(rotationMatrix(vec3(1.0, sin(time), 0.0), time + p.z * 0.001)), vec2(3.0, 1.0));
    if(s1 < d) d = s1;
    

    return d;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = ( 2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;

    vec3 ro = vec3(0.0 + sin(time) * 10.0, 0.0, -15.0);
    vec3 rd = normalize(vec3(uv, 2.0)); 
    
   
    vec3 lightDir = vec3(1.0, -1.0, 1.0);
    
    
    vec3 p = ro;
    float d = 0.0;
    for(int i = 0; i < 100; i++) {
        p += rd * d;
        d = trace(p);
       
        if(d < 0.001) {
            
            float epsilon = 0.001;
            
            float px = trace(p + vec3(+epsilon, 0.0, 0.0));
            float nx = trace(p + vec3(-epsilon, 0.0, 0.0));
            
            float py = trace(p + vec3(0.0, +epsilon, 0.0));
            float ny = trace(p + vec3(0.0, -epsilon, 0.0));
            
            float pz = trace(p + vec3(0.0, 0.0, +epsilon));
            float nz = trace(p + vec3(0.0, 0.0, -epsilon));
            
            vec3 n = normalize(vec3(px - nx, py - ny, pz - nz));
            
                               
            float diffuse = max(  dot(n, -lightDir)  , 0.0);
            vec3 surfaceColor = vec3(1.0);                   
                       
            
            glFragColor = vec4(surfaceColor * diffuse, 1.0);
            return;
        }
    }
    
    // Output to screen
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
}
