#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdVGzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 qmul(in vec4 p, in vec4 q){
    return vec4(cross(p.xyz, q.xyz)+p.w*q.xyz+p.xyz*q.w, -dot(p.xyz, q.xyz)+p.w*q.w);
}

vec4 qconj(in vec4 p){return vec4(-p.xyz, p.w);}

mat2 rot(in float t){return mat2(cos(t), sin(t), -sin(t), cos(t));}
vec3 trsf(in vec4 q){
    float t=time;
    q.xy *= rot(t*0.34);
    q.zw *= rot(t*0.53);
    q.yz *= rot(t*0.36);
    q.wx *= rot(t*0.13);
    return q.xyz / (3.0 - q.w);
}

vec2 line_seg_dist(in vec3 p, in vec3 q, in vec3 ro, in vec3 rd){
    p-=ro;q-=ro;
    vec3 u=cross(p, rd), v=cross(q-p, rd);
    float t=-dot(u,v)/dot(v,v);
    t=clamp(t, 0.05, 0.95);
    vec3 r=mix(p,q,t);
    float d=length(cross(r, rd));
    float tt=dot(r, rd) / dot(rd, rd);
    return vec2(d, tt);
}

vec3 dist(in vec3 ro, in vec3 rd, in float r0, in float r1, in float r2){
    vec4 v[16];
    v[ 0] = vec4(+1,+1,+1,+1); 
    v[ 1] = vec4(+1,+1,+1,-1); 
    v[ 2] = vec4(+1,+1,-1,+1); 
    v[ 3] = vec4(+1,+1,-1,-1); 
    v[ 4] = vec4(+1,-1,+1,+1); 
    v[ 5] = vec4(+1,-1,+1,-1); 
    v[ 6] = vec4(+1,-1,-1,+1);
    v[ 7] = vec4(+1,-1,-1,-1); 
    v[ 8] = vec4(-1,+1,+1,+1); 
    v[ 9] = vec4(-1,+1,+1,-1); 
    v[10] = vec4(-1,+1,-1,+1); 
    v[11] = vec4(-1,+1,-1,-1); 
    v[12] = vec4(-1,-1,+1,+1); 
    v[13] = vec4(-1,-1,+1,-1); 
    v[14] = vec4(-1,-1,-1,+1);
    v[15] = vec4(-1,-1,-1,-1);
    
    vec3 d_best=vec3(1e3, 1e3, 0); // dist, hit_dist, material
    for(int i=0;i<16;i++){
        for(int j=1;j<16;j*=2){
            for(int t=0;t<3;t++){
                   vec4 q;
                if(t==0){q=vec4(0,0,0,1);}
                if(t==1){q=vec4(0.5, 0.5, 0.5, 0.5);}
                if(t==2){q=vec4(0.5, 0.5, 0.5, -0.5);}
                vec3 v0=trsf(qmul(v[i], q)), v1=trsf(qmul(v[i^j], q));
                vec2 d=line_seg_dist(v0, v1, ro, rd); // dist, normal
                if(t==0 && d.x>=r0)continue;
                if(t==1 && d.x>=r1)continue;
                if(t==2 && d.x>=r2)continue;
                if(d_best.y > d.y){
                    d_best.xy = d.xy;
                    d_best.z = float(t);
                }
            }
        }
    }
    return d_best;
}

vec3 getMaterialColor(in float idx){
    if(idx<0.5){
        return vec3(1,0,0);
    }else if(idx<1.5){
        return vec3(0,1,0);
    }else{
        return vec3(0,0,1);
    }
}

void getColor(out vec4 glFragColor, in vec3 cen, in vec3 rd){
    float t=time*0.2-0.5;
    float u=smoothstep(0.8, 0.9, cos(t));
    float rm=u*0.016;
    float r0=mix(0.003, 0.03, smoothstep(0.8, 0.9, cos(t-1.57)));
    float r1=mix(0.003, 0.03, smoothstep(0.8, 0.9, cos(t-3.14)));
    float r2=mix(0.003, 0.03, smoothstep(0.8, 0.9, cos(t-4.71)));
    r0 = max(r0, rm);
    r1 = max(r1, rm);
    r2 = max(r2, rm);
    vec3 d = dist(cen, rd, r0, r1, r2);
    vec3 col = getMaterialColor(d.z);
    col = mix(col, vec3(1,1,1), u);
    float r;
    if(d.z<0.5)r=r0;
    else if(d.z<1.5)r=r1;
    else r=r2;
    glFragColor = vec4(max(1.0-d.x/r, 0.0)*col, 1);
    glFragColor = pow(glFragColor, vec4(0.45));
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 cen = vec3(0,0,2.5);
    vec3 fwd = normalize(-cen);
    vec3 up = vec3(0,1,0);
    vec3 right = cross(fwd, up);
    
    vec3 rd = normalize(fwd + 0.3 * (uv.x * right + uv.y * up));
    
    getColor(glFragColor, cen, rd);
}
