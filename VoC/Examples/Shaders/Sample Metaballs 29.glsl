#version 420

// original https://www.shadertoy.com/view/fds3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//圆的等势面
#define PI 3.1415
float metaCircle(vec2 uv,vec2 center,float radius){
    float offsetX = uv.x - center.x;
    float offsetY = uv.y - center.y;
    return sqrt((radius * radius) / (offsetX * offsetX + offsetY * offsetY));
}
float meta(vec2 uv,vec3 c1,vec3 c2){
    float m1 = metaCircle(uv,c1.xy,c1.z);
    float m2 = metaCircle(uv,c2.xy,c2.z);
    return m1 + m2;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2. - 1.;
    uv.y *= resolution.y / resolution.x;

  
    vec2 cA = vec2(.6 * sin(time ),0.);
    vec2 cB = vec2(.6 * sin(time + PI * .5),0.);
    vec2 cC = vec2(.6 * sin(time + PI) ,0.);

    float r1 = .1 + .05 * cos(time);
    float r2 = .1 + .05 * cos(time + PI * .5);
    float r3 = .1 + .05 * cos(time + PI);

    vec3 colorA = vec3(1.,0.,0.);
    vec3 colorB = vec3(0.,1.,0.);
    vec3 colorC = vec3(0.,0.,1.);

    float perA = metaCircle(uv,cA,r1);
    float perB = metaCircle(uv,cB,r2);
    float perC = metaCircle(uv,cC,r3);
    
    float m = perA + perB + perC;
    m = smoothstep(.9,1.,m);

    //计算了一下受到各个球颜色的影响
    //TODO 这个地方有问题，能勉强有效果
    float effect1 = length(uv - cA) > r1 ? perA * 2.5 : 1.;
    float effect2 = length(uv - cB) > r2 ? perB * 2.5 :  1.;
    float effect3 = length(uv - cC) > r3 ? perC * 2.5 :  1.;

    vec3 col = ((colorA * effect1 ) + (colorB * effect2) + (colorC * effect3)) * m;

    glFragColor = vec4(col,1.);
   
}
