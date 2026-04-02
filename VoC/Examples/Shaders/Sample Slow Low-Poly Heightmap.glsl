#version 420

// original https://www.shadertoy.com/view/4lByzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)

//hash function by Dave_Hoskins https://www.shadertoy.com/view/4djSRW
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

//another hash function by Dave_Hoskins https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
    p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float cosmix(float b, float a, float x) {
    return a+(b-a)*(cos(x*3.14)+1.0)/2.0;
}

float noise3d(vec3 pos) {
    vec3 flo = vec3(floor(pos.x),floor(pos.y),floor(pos.z));
    float x0y0z0 = hash13(vec3(flo.x,    flo.y,    flo.z    ));
    float x1y0z0 = hash13(vec3(flo.x+1.0,flo.y,    flo.z    ));
    float x0y1z0 = hash13(vec3(flo.x,    flo.y+1.0,flo.z    ));
    float x1y1z0 = hash13(vec3(flo.x+1.0,flo.y+1.0,flo.z    ));
    float x0y0z1 = hash13(vec3(flo.x,    flo.y,    flo.z+1.0));
    float x1y0z1 = hash13(vec3(flo.x+1.0,flo.y,    flo.z+1.0));
    float x0y1z1 = hash13(vec3(flo.x,    flo.y+1.0,flo.z+1.0));
    float x1y1z1 = hash13(vec3(flo.x+1.0,flo.y+1.0,flo.z+1.0));
    float a =  cosmix(x0y0z0,x1y0z0, pos.x-flo.x);
    float b =  cosmix(x0y1z0,x1y1z0, pos.x-flo.x);
    float a1 = cosmix(a,b,pos.y-flo.y);
    float a2 = cosmix(x0y0z1,x1y0z1, pos.x-flo.x);
    float b2 = cosmix(x0y1z1,x1y1z1, pos.x-flo.x);
    float b1 = cosmix(a2,b2,pos.y-flo.y);
    return     cosmix(a1,b1,pos.z-flo.z);
}

vec3 noise(vec2 p) {
    return mix(hash33(vec3(p,floor(time))),hash33(vec3(p,ceil(time))),fract(time));
}

float ground(vec2 p) {
    //return 0.0;
    //return sin(length(p)*3.0+time);
    return dot(noise(p),vec3(1))*3.0;
    //return dot(sin(p+time),vec2(1));
    //return noise3d(vec3(p*0.2,time))*5.0;
}

//ray-plane intersection, is negative if the ray starting point is in the plane and returns a high number if ray is not pointing in plane direction
float plane(vec3 p, vec3 d, vec3 plane) {
    return dot(p,plane)/max(-dot(d,plane),0.00001);
}

//shades the terrain, coloring according to normal, not the best shading
vec4 shade(vec3 p, vec3 d, vec3 objnorm, float depth, vec4 background) {
    vec3 sun = normalize(vec3(-1));
    vec3 reflectnorm = reflect(d,objnorm);
    vec3 color = objnorm*0.5+0.5;
    vec4 glFragColor = vec4(color*max(0.4,0.8*dot(objnorm,-sun)),1.0);
    glFragColor = mix(background,glFragColor,clamp(3.0-depth*0.1,0.0,1.0));
    return clamp(glFragColor,0.0,1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    //ray orientation(camera position) and ray direcion(camera direction)
    vec3 ro = vec3(-0.25,7.5,-time);
    vec3 rd = vec3(uv+0.001,-1.0);
    
    //current voxel
    vec2 cell = floor(ro.xz);
    //the inverse of ray direction
    vec3 invrd= abs(1.0/rd);
    //the position of the ray relative to the voxel
    vec2 cello= (ro.xz-cell);
    
    vec2 lens = abs(step(vec2(0),rd.xz)-cello)*invrd.xz;
    //distance from camera to hit position for fog
    float dist = 0.0;
    vec3 normal = vec3(0);
    for (int i = 0; i < 50; i++) {
        vec2 mask = vec2(lessThanEqual(lens,lens.yx));
        float len = dot(lens,mask)/dot(mask,vec2(1));
        
        const vec2 a = vec2(1,0);
        
        //calculating height of the terrain at all four of the voxels edges
        vec4 heights = vec4(
            ground(cell+a.yy),
            ground(cell+a.xy),
            ground(cell+a.yx),
            ground(cell+a.xx));
        
        //the normal of the 2 planes used to find the intersection
        vec3 dir = -normalize(cross(vec3(1,heights.y,0)-vec3(0,heights.x,0),vec3(0,heights.z,1)-vec3(0,heights.x,0)));
        vec3 dir2 = normalize(cross(-vec3(1,heights.y,0)+vec3(1,heights.w,1),-vec3(0,heights.z,1)+vec3(1,heights.w,1)));
        
        //vec3 dir = normalize(noise(cell)+vec3(-0.5,0.1,-0.5));
        
        //ray-plane intersection
        float len3 = plane(vec3( ro.x-cell.x ,ro.y-heights.x, ro.z-cell.y ),rd,dir);
        float len4 = plane(vec3((ro.x-cell.x)-1.0,ro.y-heights.w,(ro.z-cell.y)-1.0),rd,dir2);//(ro.y-heights.x)*invrd.y;
        
        float len2;
        vec3 dir3;
        float len5;
        
        if (heights.x+heights.w<heights.y+heights.z) {
            len2 = max(len3, len4);
            if (len2 == len3) {
                vec3 p = ro+rd*len2;
                len4 += plane(vec3((p.x-cell.x)-1.0,p.y-heights.w,(p.z-cell.y)-1.0),rd,dir2);
            } else {
                vec3 p = ro+rd*len2;
                len3 += plane(vec3( p.x-cell.x ,p.y-heights.x, p.z-cell.y ),rd,dir);
            }
            len2 = max(len3,len4);
        } else {
            len2 = min(len3,len4);
        }
        if (len2 == len3) {
            dir3 = dir;
        } else {
            dir3 = dir2;
        }
        
        
        //len2 = len4;
        if (len2 < len) {
            if (len2 < 0.0) {normal.xz = -vec2(equal(lens,invrd.xz))*sign(rd.xz);}
            else {normal = dir3;}
            ro += rd*max(len2,0.0);
            
            break;
        }
        
        lens -= len;
        lens = lens*(1.0-mask)+invrd.xz*mask;
        
        dist += len;
        cell += sign(rd.xz)*mask;
        ro += rd*len;
    }
    
    glFragColor = vec4(0.0,0.0,uv.y+0.5,1.0);
    if (normal != vec3(0.0)) {
        glFragColor = shade(ro,rd,normal,dist,glFragColor);
    } else {
        
    }
}
