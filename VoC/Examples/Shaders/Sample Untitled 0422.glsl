#version 420

#define PI2 6.28318

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 col(float t ,vec3 a, vec3 b,vec3 c,vec3 d){
    return a+b*cos((c*t+d)*PI2);
}

float object(vec3 p){
    return length(mod(p,3.0)-1.5)-.9;
}

vec3 surface(vec3 p){
    float delta=0.001;
    return normalize(vec3(object(vec3(p.x+delta,p.y,p.z))-object(vec3(p.x,p.y,p.z)),
                  object(vec3(p.x,p.y+delta,p.z))-object(vec3(p.x,p.y,p.z)),
                      object(vec3(p.x,p.y,p.z+delta))-object(vec3(p.x,p.y,p.z))));
}
    
void main( void ) {

    vec2 position = ( gl_FragCoord.xy*2.0 -resolution.xy)/min(resolution.x,resolution.y);

    vec3 cV1 =vec3(0.5);
    vec3 cV2 =vec3(0.5);
    vec3 cV3 =vec3(2.0,1.0,1.0);
    vec3 cV4 =vec3(0.5);
    
    vec3 cameraPosi=vec3(cos(time),0.0,sin(time))+vec3(1.5);
    vec3 cameraDire=-normalize(vec3(1.6)-cameraPosi);
    vec3 cameraUp  =vec3(0.0,1.0,0.0);
    vec3 cameraSide=normalize(cross(cameraDire,cameraUp));
    float cameraDepth=1.5;
    
    vec3 rayPosi =cameraPosi;
    vec3 rayDire =normalize(cameraSide*position.x+cameraUp*position.y+cameraDire*cameraDepth);
    vec3 rayStep=vec3(0.0);
    
    for(int i=0;i<128;i++){
        rayStep=rayDire*object(rayPosi);
        rayPosi+=rayStep;
    }
    
    if(length(rayStep)<0.01)
        glFragColor = vec4(col(exp(sin(length(rayPosi-cameraPosi)))/exp(1.0),cV1,cV2,cV3,cV4)*dot(-rayDire,surface(rayPosi)),1.0);
}
