#version 420

// original https://www.shadertoy.com/view/3dsSDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define eyes
#define showpoints
//#define singleview

const float eyeDist=10.;

vec2 project(vec3 point,vec3 focus){
    return point.xy-point.z*(point.xy-focus.xy)/(point.z-focus.z)-focus.xy;
}
float point(vec3 p,vec3 focus,vec2 uv){
    vec2 w=project(p,focus);
    return 0.5/dot(uv-w,uv-w);
}
float line(vec3 p_,vec3 p2_,vec3 focus,vec2 uv){
    vec2 p=project(p_,focus);
    vec2 p2=project(p2_,focus);
    vec2 n=uv-p;
    vec2 w=p2-p;
    return smoothstep(0.25,0.,length(n-w*clamp(dot(n,w)/dot(w,w),0.,1.)));
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y*50.;
    vec4 o=vec4(0);
    
    vec3 eye[2];
    eye[0]=vec3(eyeDist/2.,0,-30);
    eye[1]=vec3(-eyeDist/2.,0,-30);
    
    vec3 points[8];
    points[0]=vec3(10,10,5);
    points[1]=vec3(10,-10,5);
    points[2]=vec3(-10,10,5);
    points[3]=vec3(-10,-10,5);
    points[4]=vec3(10,10,25);
    points[5]=vec3(10,-10,25);
    points[6]=vec3(-10,10,25);
    points[7]=vec3(-10,-10,25);
    
    vec3 center=vec3(0,0,15);
    vec3 move=vec3(0,0,0);
    for(int i=0;i<8;i++){
        points[i]-=center;
        points[i].xy*=mat2(cos(time),-sin(time),sin(time),cos(time));
        points[i].xz*=mat2(cos(time*2.),-sin(time*2.),sin(time*2.),cos(time*2.));
        points[i].yz*=mat2(cos(time*3.),-sin(time*3.),sin(time*3.),cos(time*3.));
        points[i]+=center+move;
    }
    #ifdef singleview
    eye[0]=(eye[0]+eye[1])/2.;
    o+=line(points[0],points[1],eye[0],uv);
       o+=line(points[0],points[2],eye[0],uv);
    o+=line(points[0],points[4],eye[0],uv);
       o+=line(points[3],points[1],eye[0],uv);
       o+=line(points[3],points[7],eye[0],uv);
       o+=line(points[3],points[2],eye[0],uv);
       o+=line(points[6],points[2],eye[0],uv);
       o+=line(points[6],points[7],eye[0],uv);
       o+=line(points[6],points[4],eye[0],uv);
       o+=line(points[5],points[7],eye[0],uv);
       o+=line(points[5],points[4],eye[0],uv);
       o+=line(points[5],points[1],eye[0],uv);
    #ifdef showpoints
    for(int u=0;u<8;u++){
        o+=point(points[u],eye[0],uv);
        
    }
    #endif
    #else
    vec2 uv_;
    for(int i=0;i<2;i++){
        #ifdef eyes
        uv_=vec2(uv.x-(float(i)-0.5)*30.,uv.y);
        o+=line(points[0],points[1],eye[i],uv_);
        o+=line(points[0],points[2],eye[i],uv_);
        o+=line(points[0],points[4],eye[i],uv_);
        o+=line(points[3],points[1],eye[i],uv_);
        o+=line(points[3],points[7],eye[i],uv_);
        o+=line(points[3],points[2],eye[i],uv_);
        o+=line(points[6],points[2],eye[i],uv_);
        o+=line(points[6],points[7],eye[i],uv_);
        o+=line(points[6],points[4],eye[i],uv_);
        o+=line(points[5],points[7],eye[i],uv_);
        o+=line(points[5],points[4],eye[i],uv_);
        o+=line(points[5],points[1],eye[i],uv_);
        #else
        o[2*i]+=line(points[0],points[1],eye[i],uv);
        o[2*i]+=line(points[0],points[2],eye[i],uv);
        o[2*i]+=line(points[0],points[4],eye[i],uv);
        o[2*i]+=line(points[3],points[1],eye[i],uv);
        o[2*i]+=line(points[3],points[7],eye[i],uv);
        o[2*i]+=line(points[3],points[2],eye[i],uv);
        o[2*i]+=line(points[6],points[2],eye[i],uv);
        o[2*i]+=line(points[6],points[7],eye[i],uv);
        o[2*i]+=line(points[6],points[4],eye[i],uv);
        o[2*i]+=line(points[5],points[7],eye[i],uv);
        o[2*i]+=line(points[5],points[4],eye[i],uv);
        o[2*i]+=line(points[5],points[1],eye[i],uv);
        #endif
    }
       #ifdef showpoints
    for(int i=0;i<2;i++){
        for(int u=0;u<8;u++){
            #ifdef eyes
            uv_=vec2(uv.x-(float(i)-0.5)*30.,uv.y);
            o+=point(points[u],eye[i],uv_);
            #else
            o[2*i]+=point(points[u],eye[i],uv);
            #endif
        }
    }
    #endif
    #endif

    glFragColor = o;
}
