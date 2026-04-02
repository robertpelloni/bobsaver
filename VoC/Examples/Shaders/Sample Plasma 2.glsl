#version 420

// original https://www.shadertoy.com/view/tsSBzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.141579

mat2 rot(float deg) {
    deg /= 180./3.141579; // convert to radians;
    float s=sin(deg), c=cos(deg);
    return mat2(c, -s, s, c);
}

vec3 colormap(float v) {
   float r = (.5+.5*sin(pi * v));
   float g = ( .5 + .5 * sin(pi * v + 2.0 * pi / 3.0));
   float b = ( .5 + .5 * sin(pi * v + 4.0 * pi / 3.0));
   return vec3(r,g,b);
}

float calc (vec2 cv, vec2 uv, float t,float cost3,float sint5,float sint2) {
     float v = 0.0;
    float x = uv.x;
    float y = uv.y;
    float cx = cv.x;
    float cy = cv.y;
    float v0 = sin((x * 10.0) + t);
    float v1 = sin(10.0 * ( x * sint2 + y * cost3));
    float v2 = sin(sqrt(100.0*((cx*cx)+(cy*cy)))+1.0+t);
    v = ((v0 + v1 + v2) + cos(v2 + y + t)) / 2.0;
    return v;
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 ov = uv;
    uv.x += sin((time/1.)/5.0);                    // x movement
    uv.y += cos((time/1.)/3.0);                    // y movement
    uv *= .5 * (2.+(1.*sin(2.*pi*.04*time)/10.));  // zoom
    uv *= rot(22.5+(180.*sin(2.*pi*.01*time)));    // rotation
    float t = time;
    float tt=t / 1.0;
    float cost3 = cos(tt/3.0);
    float sint5 = sin(tt/5.0);
    float sint2 = sin(tt/2.0);
    float v = calc(uv,ov,tt,cost3,sint5,sint2);
    vec3 hole = colormap(v);
   
    glFragColor = vec4(hole,1.0);
    
}
