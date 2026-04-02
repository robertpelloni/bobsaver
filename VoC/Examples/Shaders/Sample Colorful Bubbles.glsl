#version 420

// original https://www.shadertoy.com/view/td2czd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float dist(in vec3 p){
    return length(p-round(p))-0.2;
}

vec3 getNormal(in vec3 p){
    return normalize(p-round(p));
}

vec3 rot(in vec3 v, in vec3 n, in float th){
    return v*cos(th)+cross(n,v)*sin(th)+n*dot(n,v)*(1.-cos(th));
}

void getColor(out vec4 glFragColor, in vec3 cen, in vec3 rd){
    vec3 u=vec3(1,0,0);    
    float t=0.;
    for(int i=0;i<200;i++){
        vec3 pos = cen + t * rd;
        float d = dist(pos);
        if(abs(d)<0.05){
            float wt=2.0*smoothstep(0.05, 0., abs(d))*pow(0.992, float(i));
            vec3 nor = getNormal(pos);
            u = rot(u, nor, wt);
        }
        t += 0.05;
    }
    glFragColor = vec4(u*0.5+0.5, 1);
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 cam = vec3(0.5, 0.25, -time*2.0);
    vec3 fwd;
    //if(mouse*resolution.xy.z>0.5){
    //    vec2 muv = (2.0 * mouse*resolution.xy.xy - resolution.xy) / resolution.y;
    //    fwd = normalize(vec3(muv, -2));
    //}else{
        fwd = normalize(vec3(sin(time*0.2),sin(time*0.3),-2)); //fwd=normalize(fwd);
    //}
    vec3 up = vec3(0,1,0);up=normalize(up-dot(fwd,up)*fwd);
    vec3 right = cross(fwd, up);
    
    vec3 rd = normalize(fwd + 0.3 * (uv.x * right + uv.y * up));
    
    getColor(glFragColor, cam, rd);
}
