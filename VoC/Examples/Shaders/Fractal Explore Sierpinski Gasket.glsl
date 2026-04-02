#version 420

// original https://www.shadertoy.com/view/ttcBWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = acos(-1.);
mat2 rot(float r){
    vec2 s = vec2(cos(r),sin(r));
    return mat2(s.x,s.y,-s.y,s.x);
}
float cube(vec3 p,vec3 s){
    vec3 q = abs(p);
    vec3 m = max(s-q,0.);
    return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}

vec4 tetcol(vec3 p,vec3 offset,float scale,vec3 col){
    vec4 z = vec4(p,1.);
    for(int i = 0;i<12;i++){
        if(z.x+z.y<0.0)z.xy = -z.yx,col.z+=1.;
        if(z.x+z.z<0.0)z.xz = -z.zx,col.y+=1.;
        if(z.z+z.y<0.0)z.zy = -z.yz,col.x+=1.;
        
        z *= scale;
      //  z.xyz = clamp(z.xyz,-1.,1.);
        z.xyz += offset*(1.0-scale);
    }
    
    return vec4(col,(cube(z.xyz,vec3(1.5)))/z.w);
}
vec4 dist(vec3 p,float t){
    float s = 1.;
    p = abs(p)-4.*s;
    p = abs(p)-2.*s;
    p = abs(p)-1.*s;

    vec4 sd = tetcol(p,vec3(1),1.8,vec3(0.));
    float d= sd.w;
    vec3 col = 1.-0.1*sd.xyz;
    col *= exp(-2.5*d)*2.6;
    return vec4(col,d);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = (uv-0.5)*2.;
    p.y *= resolution.y/resolution.x;

    float rsa =1.2;
    float time = time+17.5;
    float rkt = time*0.3;
    vec3 ro = vec3(rsa*cos(rkt)-0.05,2.2*sin(time*0.2)+0.025,rsa*sin(rkt));
    vec3 ta = vec3(0);
    vec3 cdir = normalize(ta-ro);
    vec3 side = cross(cdir,vec3(0,1,0));
    vec3 up = cross(side,cdir);
    vec3 rd = normalize(p.x*side+p.y*up+0.5*cdir);
    rd.xz *= rot(time*0.13+1.);
    float d,t= 0.;
    vec3 ac = vec3(0.);
    vec3 ac2 = vec3(0.);
    float frag = 0.;
    float ep = 0.0005;
    for(int i = 0;i<66;i++){
        vec4 rsd = dist(ro+rd*t,t);
        d = rsd.w;
        t += d;
        ac += rsd.xyz;
        if(d<ep) break;
    }

    vec3 col = vec3(0);
    
    col  =0.04*ac;
        glFragColor = vec4(col, 1.0 );

}
