#version 420

// original https://www.shadertoy.com/view/3djczG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(in vec3 pos){return 0.8+0.2*cos(pos.z*9.);}

mat2 rot(in float t){return mat2(cos(t),-sin(t),sin(t),cos(t));}

float lat(in vec3 p){return length(p-round(p));}
float dist(in vec3 p){
    vec3 q=p;
    p.xy *= rot(0.1);
    p += 0.5;
    q -= 3.4;
    q.xy *= rot(2.1);
    q.yz *= rot(1.1);
    q.zx *= rot(1.3);
    return (lat(p)-lat(q*1.2)/1.2)*0.5;
}

vec3 getNormal(in vec3 pos){
    float eps=0.001;
    vec2 s = vec2(eps, -eps);
    return normalize(dist(pos+s.xxx)*s.xxx
                    +dist(pos+s.xyy)*s.xyy
                    +dist(pos+s.yxy)*s.yxy
                    +dist(pos+s.yyx)*s.yyx);
}

float getAO(in vec3 pos, in vec3 nor){
    float ao=1.0;
    float wt=1.0;
    for(int i=1;i<=5;i++){
        float t=float(i)*0.01;
        float d=dist(pos+t*nor);
        ao -= (t-d)*wt;
        wt*=0.5;
    }
    return clamp(ao, 0.0, 1.0);
}

void getColor(out vec4 glFragColor, in vec3 cen, in vec3 rd){
    glFragColor = vec4(vec3(0), 1.0);
    float t=0.01;
    for(int i=0;i<100;i++){
        vec3 pos = cen + t * rd;
        float d = dist(pos);
        if(d<1e-3){
            vec3 nor = getNormal(pos);
            float occ = getAO(pos, nor);
            glFragColor = vec4(vec3(1.5,0.15,0.0)*noise(pos)*(dot(nor, -rd)*0.8+0.2)*occ, 1);
            glFragColor *= (1.0-0.01*float(i));
            //glFragColor = vec4(v02c3(occ), 1);
            //glFragColor = vec4(vec3(1.0-float(i)/64.0), 1);
            
            break;
        }
        t += d;
        if(t>=1e2){
            break;
        }
    }
    
    glFragColor = pow(glFragColor, vec4(0.45));
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 cam = vec3(0,0,-time);
    vec3 fwd = normalize(vec3(sin(time*0.2),sin(time*0.3),-5));
    vec3 up = vec3(0,1,0);
    vec3 right = cross(fwd, up);
    
    vec3 rd = normalize(fwd + 0.3 * (uv.x * right + uv.y * up));
    
    getColor(glFragColor, cam, rd);
}
