#version 420

// original https://www.shadertoy.com/view/XdKcDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot90(a) vec2(-(a.y),a.x)
#define rot(spin) mat2(cos(spin),sin(spin),-sin(spin),cos(spin))
#define dot2(p) dot(p,p)

/**
//experiments
float map(vec3 p) {
    p = abs(fract(p)-0.5);
    
    
    vec3 p2 = max(p,p.yzx);
    return mix(length(p)-0.1,min(min(p2.x,p2.y),p2.z)-0.1,sin(time)*0.5+0.5);
}
/**/

/**/
//cubic truchets
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)
//hash function by Dave_Hoskins https://www.shadertoy.com/view/4djSRW
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float torus(vec3 p, vec2 r) {//creates 4 toruses
    return length(vec2(abs(abs(length(p.xy)-r.x)-0.02),abs(p.z)-0.02))-r.y;
}

float map(vec3 p) {
    p += time*0.1;
    vec3 p2 = mod(p,2.0)-1.0;
    vec3 floorpos = floor(p*0.5);
    float len = 1e10;
    
    //the truchet flipping
    vec3 flipping = floor(hash33(floorpos)+0.5)*2.0-1.0;
    
    //actually flipping the truchet
    vec3 p3 = p2*flipping;
    
    //positions relative to truchet centers
    mat3 truchet = mat3(
        vec3(+p3.yz+vec2(-1.0, 1.0),p3.x),
        vec3(+p3.zx+vec2(-1.0, 1.0),p3.y),
        vec3(+p3.yx+vec2( 1.0,-1.0),p3.z)
    );
    
    //finding distance to truchet
    len = min(min(
        torus(truchet[0],vec2(1.0,0.01)),
        torus(truchet[1],vec2(1.0,0.01))),
        torus(truchet[2],vec2(1.0,0.01)));
    
    return len;
}
/**/

/**
//grid
/*float grid(vec3 p) {
    p += sin(time);
    p = 0.5-abs(fract(p+0.5)-0.5);
    p = min(p,p.yzx);
    return max(max(p.x,p.y),p.z);
}

float box(vec3 p, vec3 s) {
    
    return length(max(abs(p)-s,0.0));
}

float map(vec3 p) {
    //p = mod(p,2.0)-1.0;
    
    return grid(p)-0.1;
}
/**/

/**
//menger sponge
float map(vec3 p)
{
    p = mod(p,6.0)-3.0;
    float len = 0.0;
    for (float i = 1.0; i > 0.02; i/=3.0) {
        vec3 p2 = abs(mod(p/i,3.0)-1.5);
        
        p2 = max(p2,p2.yzx);
        len = max(len,(min(min(p2.x,p2.y),p2.z)-1.0)*i);
    }
    vec3 p2 = abs(p);
    
    return max(len,max(max(p2.x,p2.y),p2.z)-1.5);
}
/**/

//normal calculation
vec3 findnormal(vec3 p, float len) {
    const vec2 eps = vec2(0.01,0.0);
    
    return normalize(vec3(
        len-map(p-eps.xyy),
        len-map(p-eps.yxy),
        len-map(p-eps.yyx)));
}

vec4 shade(vec3 ro, vec3 rd, float len) {
    vec4 glFragColor = vec4(1);
    vec3 normal = findnormal(ro, len);
    
    float ambient = 0.1;

    vec3 color = vec3(0.8,0.4,0.1);
    //color = fract(ro);
    vec3 light = normalize(vec3(cos(time*0.2),-1,sin(time*0.2)));
    float diffusion = dot(-light,normal)*2.0;

    float lighting = clamp(diffusion,ambient,1.0);

    glFragColor.xyz = min(color*lighting,1.0);
    return sqrt(glFragColor);
}

void main(void)
{
    
    vec2 uv =  (gl_FragCoord.xy*2.0-resolution.xy  ) / resolution.y;
    vec4 muv = vec4(0.0);//(abs(mouse*resolution.xy) *2.0-resolution.xyxy) / resolution.y;
    
    vec3 pos = vec3(sin(time*0.1),cos(time*0.23),sin(time*0.43))*2.5;
    vec3 dir = normalize(vec3(uv,1.0));
    
    dir.zy *= rot(-muv.y*3.14*0.5);
    dir.xz *= rot(muv.x*3.14);
    
    vec3 point1 = pos;
    vec3 point2 = pos+dir;
    
    vec3 pos3 = point1*0.5;
    vec3 pos4 = point2*0.5;
    
    mat3 rotmat = mat3(normalize(pos3),normalize(cross(pos3,pos4)),vec3(0));
    rotmat[2] = normalize(cross(rotmat[0],rotmat[1]));
    
    vec2 pos1 = vec2(dot(rotmat[0],point1),dot(rotmat[2],point1))*0.5;
    vec2 pos2 = vec2(dot(rotmat[0],point2),dot(rotmat[2],point2))*0.5;
    vec2 dir1 = rot90(normalize(pos1));
    vec2 dir2 = rot90(normalize(pos2));
    
    float len2 = (dot(pos2-pos1, rot90(dir1))/dot(rot90(dir2),dir1));
    
    vec2 point3 = pos2+dir2*len2;
    float rayrad = length(point3);
    
    vec2 ro = vec2(dot(rotmat[0],point1),dot(rotmat[2],point1));
    
    float flip = sign(dot(rot90((point3-ro)),pos1-pos2));
    float dist = 0.0;
    float len;
    for (int i = 0; i < 1000; i++) {
        
        len = map(ro.x*rotmat[0]+ro.y*rotmat[2]);
        
        if (len < 0.001 || dist > 20.0) break;
        dist += len;
        
        mat2 rot = mat2(normalize(point3-ro),vec2(0));
        
        rot[1] = rot90(rot[0]);
        rot[1] *= flip;
        
        vec2 xy = vec2(len*len*0.5/rayrad,0);
        xy.y = sqrt(len*len-xy.x*xy.x);
        xy *= transpose(rot);
        
        ro += xy;
    }
    if (dist > 20.0) {
        glFragColor = vec4(sin(dir*10.0*rotmat+dir*6.0+time)*0.15+0.15,1);
        return;
    }
    pos = ro.x*rotmat[0]+ro.y*rotmat[2];
    glFragColor = shade(pos,dir,len);
    
    //glFragColor += vec4(1,1,0,1)*dot(iuv,iuv)/100.0;
}
