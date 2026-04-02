#version 420

// original https://www.shadertoy.com/view/llSyzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

#define dot2(p) dot(p,p)

float torus(vec3 p, vec2 r) {//creates 4 toruses
    return length(vec2(abs(abs(length(p.xy)-r.x)-0.1),abs(p.z)-0.1))-r.y;
}

vec3 pos;
float map(vec3 p) {
    
    vec3 p2 = mod(p,2.0)-1.0;
    vec3 floorpos = floor(p*0.5);
    float len = 1e10;
    
    //the truchet flipping
    vec3 orientation = floor(hash33(floorpos)+0.5)*2.0-1.0;
    //orientation.yz = vec2(1.0);
    
    //actually flipping the truchet
    vec3 p3 = p2*orientation;
    
    //positions relative to truchet centers
    mat3 truchet = mat3(
        vec3(+p3.yz+vec2(-1.0,-1.0),p3.x),
        vec3(+p3.zx+vec2( 1.0, 1.0),p3.y),
        vec3(+p3.yx+vec2( 1.0,-1.0),p3.z)
    );
    
    //finding distance to truchet
    len = min(min(
        torus(truchet[0],vec2(1.0,0.02)),
        torus(truchet[1],vec2(1.0,0.02))),
        torus(truchet[2],vec2(1.0,0.02)));
    
    return len;
}

//normal calculation
vec3 findnormal(vec3 p, float len) {
    const vec2 eps = vec2(0.01,0.0);
    
    return normalize(vec3(
        len-map(p-eps.xyy),
        len-map(p-eps.yxy),
        len-map(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 floorpos = vec3(0.0,0.0,0.0);
    pos = vec3(1.0,1.0,0.0);
    vec3 dir = vec3(0.0,0.0,1.0);
    float time = time*0.4;
    for (float i = 0.0; i <= floor(time); i++) {
        
        pos += dir;
        
        vec3 orientation = floor(hash33(floorpos)+0.5)*2.0-1.0; //the truchet flipping
        //orientation.xyz = vec3(1.0);
        dir *= orientation;
        if (dir.x == -1.0) {
            dir = vec3(0.0,-1.0,0.0);
            dir.y *= orientation.y;
        } else
        if (dir.y == -1.0) {
            dir = vec3(0.0,0.0,1.0);
            dir.z *= orientation.z;
        } else
        if (dir.z == -1.0) {
            dir = vec3(0.0,1.0,0.0);
            dir.y *= orientation.y;
        } else
        if (dir.x == 1.0) {
            dir = vec3(0.0,0.0,-1.0);
            dir.z *= orientation.z;
        } else
        if (dir.y == 1.0) {
            dir = vec3(1.0,0.0,0.0);
            dir.x *= orientation.x;
        } else
        if (dir.z == 1.0) {
            dir = vec3(-1.0,0.0,0.0);
            dir.x *= orientation.x;
        }
        
        floorpos += dir;
        pos += dir;
    }

    vec3 orientation = floor(hash33(floorpos)+0.5)*2.0-1.0; //the truchet flipping
    //orientation.xyz = vec3(1.0);
    vec3 dir2 = dir;
    dir *= orientation;
    if (dir.z == 1.0) {
        dir = vec3(-1.0,0.0,0.0);
        dir.x *= orientation.x;
    } else if (dir.x == -1.0) {
        dir = vec3(0.0,-1.0,0.0);
        dir.y *= orientation.y;
    } else if (dir.y == -1.0) {
        dir = vec3(0.0,0.0,1.0);
        dir.z *= orientation.z;
    } else if (dir.z == -1.0) {
        dir = vec3(0.0,1.0,0.0);
        dir.y *= orientation.y;
    } else if (dir.y == 1.0) {
        dir = vec3(1.0,0.0,0.0);
        dir.x *= orientation.x;
    } else if (dir.x == 1.0) {
        dir = vec3(0.0,0.0,-1.0);
        dir.z *= orientation.z;
    }
    
    //animation
    pos += dir2*(sin(fract(time)*3.14*0.5));
    pos += dir*(1.0-cos(fract(time)*3.14*0.5));
    
    //normal pointing towards where the camera moves, would be nice if the camera was looking in that direction
    vec3 forward = dir2*cos(fract(time)*3.14*0.5)+dir*sin(fract(time)*3.14*0.5);
    
    
    mat3 rotation = mat3(
        vec3(0.0),
        vec3(0.0),
        vec3(0.0));
    rotation[2] = forward;
    rotation[1] = normalize(cross(forward,vec3(1)));
    rotation[0] = cross(rotation[1],forward);
        
    vec3 ro = pos;
    vec3 rd = normalize(vec3(uv,1.0));
    
    rd = normalize(uv.x*rotation[0]+uv.y*rotation[1]+rotation[2]);
    
    bool hit = false;
    float len;
    float dist = 0.0;
    for (int i = 0; i < 50; i++) {
        len = map(ro);
        if (len < 0.01 || dist > 10.0) {
            hit = len < 0.01;
            break;
        }
        ro += rd*len;
        dist += len;
    }
    if (hit) {
        
        glFragColor = vec4(findnormal(ro,len)*0.5+0.5,1.0);
        glFragColor /= (dist*dist*0.05+1.0);
        //if (all(equal(floor(ro*0.5),floorpos))) glFragColor = 1.0-glFragColor;
    }
}
