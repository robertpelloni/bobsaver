#version 420

// original https://www.shadertoy.com/view/3dSXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(spin) mat2(cos(spin),sin(spin),-sin(spin),cos(spin))
#define pi acos(-1.0)
#define FAR 200.0
#define STEPS 500

float map(float c) {
    
    return (sin(c+5.0)-1.0)*4.0;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;

    vec3 ro = vec3(0,0,-20.1);
    vec3 rd = normalize(vec3(uv,1));

    if (length(mouse*resolution.xy.xy) > 40.0) {
        rd.yz *= rot(mouse.y*resolution.y/resolution.y*3.14-3.14*0.5);
        rd.xz *= rot(mouse.x*resolution.x/resolution.x*3.14*2.0-3.14);
        ro.yz *= rot(mouse.y*resolution.y/resolution.y*3.14-3.14*0.5);
        ro.xz *= rot(mouse.x*resolution.x/resolution.x*3.14*2.0-3.14);
    } else {
        rd.yz *= rot(-0.5);
        ro.yz *= rot(-0.5);
        
    }

    float r = 1.0;

    float e = 1.0/dot(rd.xz,rd.xz);

    float a = dot(-ro.xz,rd.xz)*e;
    vec2 p = ro.xz+rd.xz*a;
    float b = dot(p,p);

    float offset = time;
    float freq = (0.03*time+1.0);
    float cell = floor(log(max(length(ro.xz),0.2))*freq-offset)+offset;
    float dir = -1.0;
    
    float h = map(cell);
    ro.y = max(ro.y,h+0.1);

    vec3 n = vec3(0);
    float d = 0.0;
    for (int i = 0; i < STEPS; i++) {
        
        float h = map(cell);
        
        if ( ro.y+rd.y*d < h) {
            n = vec3(-normalize(ro.xz+rd.xz*d)*dir,0).xzy;
            break;
        }
        
        float pln = 10000.0;
        if (rd.y < 0.0) pln = -(ro.y-h)/rd.y;
        
        float cell2 = max(exp((cell+dir*0.5+0.5)/freq),0.0);
        
        float l = 0.0;
        
        if (max(b,0.2*0.2) <= cell2*cell2 || dir == 1.0) {
            float c = sqrt((cell2*cell2-b)*e);
            if (c+a > 0.0) {
                d = a+c*dir;
                
                cell += dir;
            } else {
                dir = 1.0;
            }
        } else {
            dir = 1.0;
        }
        
        
        if (pln < d) {
            d = pln;
            n = vec3(0,1,0);
            cell -= dir;
            break;
        }
        
        if ( d > FAR ) break;
        

    }

    /*if (b <= r*r) {
        float c = sqrt((r*r-b)*e);
        float len = a-c;
        if (len > 0.0 && len < l) {
            n = vec3((ro.xz+rd.xz*len)/r,0).xzy;
            l = len;
        }
    }*/

    vec3 col;
    vec3 background = 0.2 + 0.1*cos(time+uv.xyx+vec3(0,2,4));

    if (d < FAR) {
        vec3 p = ro+rd*d;
        
        cell -= offset;

        col = sin(cell*vec3(5.3,0.3,6.7)+vec3(1.4,3.2,0.3))*0.5+0.5;
        
        float diff = max(0.1,dot(n,normalize(vec3(1))));
        
        col *= diff;
        
        col = mix(col,background,d/FAR);
        //col = fract(p);
    } else {
        col = background;
    }

    glFragColor = vec4(sqrt(col),1.0);
}
