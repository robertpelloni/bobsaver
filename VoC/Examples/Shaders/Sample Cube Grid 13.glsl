#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
float pi=3.14159265359;

vec3 cospal(float t,vec3 a,vec3 b,vec3 c,vec3 d){
  return a+b*cos((c*t+d)*pi*2.0);
}

vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

float box(vec3 p,vec3 s){
  return length(max(abs(p)-s,0.0));
}

float distanse(vec3 p){
    return box(mod(p,4.0)-2.0,vec3(1.0));
//    return max(box(mod(p,4.0)-2.0,vec3(1.0)),box(p,vec3(8.0)));
}

vec3 surfase(vec3 p){
  float delta=0.001;
  return normalize(vec3(distanse(vec3(p.x+delta,p.y,p.z))-distanse(vec3(p.x-delta,p.y,p.z)),
                        distanse(vec3(p.x,p.y+delta,p.z))-distanse(vec3(p.x,p.y-delta,p.z)),
                        distanse(vec3(p.x,p.y,p.z+delta))-distanse(vec3(p.x,p.y,p.z-delta))));
}
vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

vec3 cameraMove(float t){
  float len=4.0;
  vec3 td=vec3(mod((t+vec3(0.0,2.0,4.0))*pi/6.0,pi*2.0)-pi);
  vec3 cameraPosi=asin(sin(td))*6.0/pi;

  cameraPosi=len*mix((cameraPosi),sign(cameraPosi),step(1.0,abs(cameraPosi)));
  return cameraPosi;
}

void main( void ) {
    vec2 point=(gl_FragCoord.xy*2.0-resolution)/min(resolution.x,resolution.y);
    vec2 nMouse =vec2(mouse.x * 2.0 - 1.0, -mouse.y * 2.0 + 1.0);
  float delta =0.001;

  vec3 cameraPosi =cameraMove(time);
  vec3 cameraDire =normalize(vec3(0.0)-cameraPosi);
    vec3 cameraUp   =vec3(0.0,1.0,0.0);
    vec3 cameraSide =cross(cameraDire,cameraUp);
    float cameraDepth = 1.0;

    vec3 rayVec =normalize(cameraSide*point.x+cameraUp*point.y+cameraDire*cameraDepth);
    vec3 rayPosi=cameraPosi;
    vec3 rayStep=vec3(0.0);

  vec3 light=cameraPosi;

    for (int i=0;i<64;i++){
        rayStep=rayVec*distanse(rayPosi);
        rayPosi+=rayStep;
        if(abs(length(rayStep))<0.01){
            glFragColor=vec4(cospal(exp(sin(length(rayPosi-cameraPosi))*1.0)/exp(2.0)+0.01,vec3(0.5),vec3(0.5,0.4,0.3),vec3(2.0,1.0,1.0),vec3(0.5)),dot(-rayVec,surfase(rayPosi)));
            break;
        }
    }
}
