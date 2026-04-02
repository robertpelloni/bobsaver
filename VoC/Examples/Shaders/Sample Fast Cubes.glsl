#version 420

// original https://www.shadertoy.com/view/XsScWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor = vec4(0.0);
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 pos = vec3(1.0,0.0,time);
    
    vec3 dir = normalize(vec3(uv,1.0));
    vec3 signdir = sign(dir);
    float dist = 0.0;
    vec3 normal;
    float hitcount = 0.0; //how many times the ray has reflected
    float number = 1.0;   //divides by 2 everytime the ray hits
    float number2 = 0.0;
    for (int i = 0; i < 18; i++) {
        vec3 pos2 = mod(pos+1.0,2.0)-1.0;
        vec3 num  = 0.5-pos2*signdir;
        num *= step(abs(pos2),vec3(0.5));
        num /= dir*signdir;
        float len  = max(max(num.x,num.y),num.z);
        
        if (len < 0.001) {
            hitcount++;
            number /= 3.0;
            number2 += number;
            glFragColor += vec4((sin(pos*3.0+dist+time)*0.5+0.5)/(dist+1.0)*2.0+normal*0.2,1.0)*number;
            if (hitcount == 3.0) break;
            
            dir = reflect(dir,normal);
            signdir = sign(dir);
            pos += dir*0.1;
        }
        
        normal = vec3(equal(vec3(len),num));
        
        pos += dir*len;
        dist += len;
    }
    
    glFragColor /= number2;
    glFragColor *= 2./(2. + dist*dist*.001);
    //glFragColor = vec4(dot(normal,vec3(0.5,0.25,1.0)));
    //glFragColor = vec4((sin(pos*3.0+dist+time)*0.5+0.5)/(dist+1.0)*2.0+normal*0.2,1.0);
    //glFragColor.xyz = normal;
}
