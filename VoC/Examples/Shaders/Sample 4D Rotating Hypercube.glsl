#version 420

// original https://www.shadertoy.com/view/WsXXDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define showpoints
vec2 project(vec3 point,vec3 focus){
    return point.xy-point.z*(point.xy-focus.xy)/(point.z-focus.z)-focus.xy;
}
vec3 project(vec4 point,vec4 focus){
    return point.xyz-point.w*(point.xyz-focus.xyz)/(point.w-focus.w)-focus.xyz;
}
float point(vec4 p,vec4 focus,vec2 uv){
    vec2 w=project(project(p,focus),focus.xyz);
    return 0.03/dot(uv-w,uv-w);
}
float line(vec4 p_,vec4 p2_,vec4 focus,vec2 uv){
    vec2 p=project(project(p_,focus),focus.xyz);
    vec2 p2=project(project(p2_,focus),focus.xyz);
    vec2 n=uv-p;
    vec2 w=p2-p;
    return smoothstep(30./resolution.y,0.0,length(n-w*clamp(dot(n,w)/dot(w,w),0.,1.)));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y*10.;
    vec4 o=vec4(0);
    
    vec4 eye=vec4(0,0,-30,-30);
    
    vec4 points[16];
    points[0]=vec4(10,10,5,5);
    points[1]=vec4(10,-10,5,5);
    points[2]=vec4(-10,10,5,5);
    points[3]=vec4(-10,-10,5,5);
    points[4]=vec4(10,10,5,25);
    points[5]=vec4(10,-10,5,25);
    points[6]=vec4(-10,10,5,25);
    points[7]=vec4(-10,-10,5,25);
    
    points[8]=vec4(10,10,25,5);
    points[9]=vec4(10,-10,25,5);
    points[10]=vec4(-10,10,25,5);
    points[11]=vec4(-10,-10,25,5);
    points[12]=vec4(10,10,25,25);
    points[13]=vec4(10,-10,25,25);
    points[14]=vec4(-10,10,25,25);
    points[15]=vec4(-10,-10,25,25);
    
    vec4 center=vec4(0,0,15,15);
    vec4 move=vec4(0,0,0,0);
    for(int i=0;i<16;i++){
        points[i]-=center;
        points[i].xy*=mat2(cos(time),sin(time),-sin(time),cos(time));
        points[i].xz*=mat2(cos(time),sin(time),-sin(time),cos(time));
        points[i].xw*=mat2(cos(time),sin(time),-sin(time),cos(time));
        points[i].yz*=mat2(cos(time),sin(time),-sin(time),cos(time));
        points[i].yw*=mat2(cos(time),sin(time),-sin(time),cos(time));
        points[i].zw*=mat2(cos(time),sin(time),-sin(time),cos(time));
        
        points[i]+=center+move;
    }
    eye[0]=(eye[0]+eye[1])/2.;
    
    for(int i=0;i<16;i++){
        for(int u=0;u<16;u++){
            if(i<=u)continue;
            if(distance(points[i],points[u])<21.)o+=line(points[u],points[i],eye,uv);
        }
    }
    
    #ifdef showpoints
    for(int u=0;u<16;u++){
        o+=point(points[u],eye,uv);
    }
    #endif

    glFragColor = o;
}
