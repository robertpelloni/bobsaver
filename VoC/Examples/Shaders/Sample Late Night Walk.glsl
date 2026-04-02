#version 420

// original https://neort.io/art/bpmaj6k3p9fbkbq83ttg

// Original "Starfield" by BigWIngs https://www.shadertoy.com/view/tlyGW3

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

float rand(vec2 st){
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
}
//https://light11.hatenadiary.com/entry/2020/01/17/001035
float mypow(float src, float x){
    return src - (src - src * src) * (-x);
}
vec2 rotate(vec2 st, float angle)
{
    mat2 mat = mat2(cos(angle), -sin(angle),
                    sin(angle),  cos(angle));
    return mat*st;
}

float star(vec2 uv, float flare){
    float d = length(uv);
    float m = 0.05/d;
    m += m*flare;
    m *= smoothstep(0.85, 0.2, d);
    return m;
}
float starLayer(vec2 uv, float grid){
    vec2 gv = fract(uv*grid)-0.5;
    vec2 id = floor(uv*grid);

    float col = 0.0;
    for(int y=-1; y<=1; y++){
        for(int x=-1; x<=1; x++){
            vec2 offset = vec2(x, y);
            float n = rand(id+offset);
            float size = fract(n*345.32);
            float stars = star(gv-offset-vec2(n, fract(n*34.0))+0.5, smoothstep(0.9, 1.0, size)*6.0);
            
            stars *= sin(time*2.0 + n*13.256)*0.5+0.5;

            col += stars*size;
        }
    }
    return col;
}
float shootstar(vec2 uv, float grid, vec2 uvorig){
    vec2 gv = fract(uv*grid)-0.5;
    vec2 id = floor(uv*grid);

    float n = rand(id);
    float size = fract(n*345.32);
    vec2 uvs = gv-vec2(n, fract(n*34.0))+0.5;
    uvs = rotate(uvs, -uvorig.x);

    float flare = smoothstep(0.9, 1.0, size)*6.0;

    float d = length(vec2(uvs.x, uvs.y-(1.0/uvorig.x/2.0+(mypow(uvorig.y, 8.0)/4.))*(uvs.x/8.0)*48.0));
    float m = smoothstep(0.07, 0.06, d);
    float tail = flare>5.0 ? m + m*flare : 0.0;
    
    return tail*size;
}

float sdBox(vec3 p, vec3 b, vec3 c){
    vec3 q = abs(p-c) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdBoxinf(vec2 p){
    vec2 q = abs(p);
    float da = max(q.x+0.5,q.y);
    return da - 1.0;
}

float map(vec3 p){
    vec3 q1=p;
    q1.xz=mod(q1.xz,1.0)-0.5;

    float ft = fract(mod(time, 5.0)*0.05);
    float rtime = rand(vec2(floor(ft*floor(p.xz))));
    
    float height = abs(rand(floor(p.xz)+rtime));
    float id = floor(mypow(abs(p.x*0.1), -1.0));
    vec3 size = vec3(0.45,height+id,0.45);

    float sd1 = sdBox(q1, size, vec3(0.0));

    float sd2 = sdBoxinf(p.xy);
    
    return min(sd1,sd2);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 camPos = vec3(0.0,1.5,1.0-time);
    vec3 camDir = normalize(vec3(0.0, 0.0, -1.0));
    //camDir.x = mouse.x*2.0-1.0;
    vec3 camUp  = normalize(vec3(0.0, 1.0, 0.0));
    vec3 camSide = cross(camDir, camUp);
    float fov = 1.8;

    vec3 dir = normalize(camSide*uv.x + camUp*uv.y + camDir*fov);        
    vec3 ray = camPos;
    int march = 0;
    float d = 0.0;
    float rLen = 0.0;

    float total_d = 0.0;
    const int MAX_MARCH = 128;
    const float MAX_DIST = 100.0;
    for(int i=0; i<MAX_MARCH; ++i) {
        d = map(ray);
        march = i;
        total_d += d;
        if(d<0.001) {
            break;
        }
        if(total_d>MAX_DIST) {
            total_d = MAX_DIST;
            march = MAX_MARCH-1;
            break;
        }
    
        rLen += min(min(min((step(0.0,dir.x)-fract(ray.x))/dir.x,
                            (step(0.0,dir.y)-fract(ray.y))/dir.y)+0.01,
                        (step(0.0,dir.z)-fract(ray.z))/dir.z)+0.01, d);

        ray = camPos + dir * rLen;
    }
    
    float fog = min(1.0, (1.0 / float(MAX_MARCH)) * float(march));
    vec3  fog2 = vec3(1.0, 1.0, 1.0) * total_d * 0.01;

    vec3 raycol = vec3(0.1, 0.1, 0.2)*fog + fog2*0.5;
    //glFragColor = vec4(vec3(raycol), 1.0);
    
    vec3 starscol = vec3(0.0);
    float grid = 1.0;
    //uv.x += mouse.x*4.0-2.0;

    for(float i=0.0; i<=1.0; i+=0.25){
        float depth = fract(i+time*0.02);
        float scale = mix(20.0, 0.5, depth);
        float fade = depth*smoothstep(1.0, 0.9, depth);
        starscol += vec3(starLayer(uv*scale+i*432.0, grid)*fade);

        fade = depth*smoothstep(0.85, 0.6, depth);
        starscol += vec3(shootstar(uv*scale+i*321.0, grid, uv)*fade);
    }

    starscol *= abs(uv.y*0.5) * vec3(0.5, 0.5, 1.0);
    //glFragColor = vec4(starscol, 1.0);

    vec3 col = mix(raycol, starscol, clamp(fog2*1.25, 0.0, 1.0));
    
    glFragColor = vec4(col*fog, 1.0);
}
