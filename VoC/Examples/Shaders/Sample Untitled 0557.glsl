#version 420

// original https://www.shadertoy.com/view/wdSyzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 transform(vec3 p, float modFac, float rotX, float rotZ){
    //twisty!!
    //rotX = rotX*p.y+time*0.6+p.x;
    //rotZ = rotZ+cos(time*1.25)+p.z;
    //not so twisty
    rotX = rotX + mod(time+0.2*p.z,radians(360.0));
    rotZ = rotZ + mod(0.25*time+0.1*p.x,radians(360.0));
    //translation
    p = p + vec3(0.4,p.z,-2);
    //modulo 8
    p = mod(p+(0.5*vec3(modFac,modFac,modFac)),vec3(modFac,modFac,modFac))-(0.5*vec3(modFac,modFac,modFac));
    //x axis rot
    p = vec3(p.x, p.y*cos(rotX) - p.z*sin(rotX), p.y*sin(rotX) + p.z*cos(rotX));
    //z axis rot
    p = vec3(p.x*cos(rotZ) - p.y*sin(rotZ), p.x*sin(rotZ) + p.y*cos(rotZ), p.z);
    return p;
}

float torus(vec3 p, vec2 t){
    p = transform(p,5.0,1.1,0.65);
    return length(vec2(length(vec2(p.x,p.z))-t.x,p.y)) - t.y;
}

vec3 raymarch(vec2 uv, vec3 cam, vec2 args){
    vec3 dir = normalize(vec3(2.0*uv.x-1.0,2.0*uv.y-1.0,1.0));;
    float totalDis = 0.0;
    vec3 p;
    for(int i=0;i<100;i++){
        vec3 p = cam + totalDis*dir;
        totalDis = totalDis + torus(p,args)*0.5;
    }
    return mix(vec3(0.8,0.0,0.0),vec3(0.05,0.05,0.05),smoothstep(10.0,50.0,totalDis));
}

vec3 calNormal(vec3 p, float smoothVal, vec2 args){
    return normalize(vec3(
        torus(p+vec3(smoothVal,0,0),args)-torus(p+vec3(-smoothVal,0,0),args),
        torus(p+vec3(0,smoothVal,0),args)-torus(p+vec3(0,-smoothVal,0),args),
        torus(p+vec3(0,0,smoothVal),args)-torus(p+vec3(0,0,-smoothVal),args)));
}

vec3 raymarch_withLight(vec2 uv, vec3 cam, vec3 lightDir, vec3 lightCol, vec3 matCol, vec2 args){
    vec3 dir = normalize(vec3(2.0*uv.x-1.0,2.0*uv.y-1.0,1.0));;
    float totalDis = 0.0;
    vec3 p;
    for(int i=0;i<100;i++){
        p = cam + totalDis*dir;
        totalDis = totalDis + torus(p,args)*0.5;
    }
    matCol.x = 0.5+0.5*sin(p.z+p.y);
    matCol.y = 0.5+0.5*sin(0.25*p.x);
    matCol.z = 0.5+0.5*sin(0.5*p.x*p.y+2.0);
    vec3 normal = calNormal(p,0.0001,args);
    float diffuse = dot(lightDir,normal);
    vec3 diffuseLit = diffuse*lightCol*matCol;
    return mix(diffuseLit,vec3(0.05,0.05,0.05),smoothstep(10.0,80.0,totalDis));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    //vec3 col = raymarch(uv,vec3(0,0.2,-2),vec2(0.8,0.3));
    vec3 col = raymarch_withLight(uv,vec3(2.0+cos(time*0.5+10.0)*1.5,sin(time*1.5)*3.0,time*5.0),
                                  normalize(vec3(-0.2, -0.3, -0.5)),vec3(1.0, 0.6, 0.2),
                                  vec3(1.0,1.0,1.0),vec2(0.75,0.25));
    glFragColor = vec4(col.xyz, 1.0);
}
