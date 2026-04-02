#version 420

// original https://www.shadertoy.com/view/3dlXRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define root2 1.41421
#define root22 root2/2.0

#define M_SIDE_NUM 6.0
#define M_RADIUS 0.1
#define MAX_BOUNCE_NUM 2
#define ROTATE_SPEED 6.0
#define CAM_SPEED 0.2
#define DISTORT_POINTER 1.12
#define COLOR_RANGE 0.1
#define SATURATION 0.4

//#define MODE0

const float angleUnit = 2.0*PI/M_SIDE_NUM;

vec2 cam(vec2 uv)
{
    float d = length(uv);
    float a = atan(uv.y,uv.x) + CAM_SPEED * time;
    return vec2(d*cos(a),d*sin(a));
}

vec2 rotate(vec2 uv)
{
    float d = length(uv);
    float a = atan(uv.y,uv.x);
    a/=angleUnit;
#ifdef MODE0
    a = fract(a);
#else
    a = fract(a+0.5)-0.5;
#endif
    a*=angleUnit;
    return vec2(d*cos(a),d*sin(a));
}
vec2 bounce(vec2 uv)
{
    float f = 0.0;
    for(int i = 0;i<MAX_BOUNCE_NUM;i++){
        float a = atan(uv.y,uv.x);
        float d = length(uv);
        a/=angleUnit;
        f += floor(a+0.5);
        a = fract(a+0.5)-0.5;
        a*=angleUnit;
        float x = d*cos(a);
        float y = d*sin(a);
        if(x<M_RADIUS)
        {
            a +=f*angleUnit;
            return vec2(d*cos(a),d*sin(a));
        }
        x = 2.0*M_RADIUS-x;
        uv = vec2(x,y);
    }
    return uv;
}
vec2 distort(vec2 uv){
    float factor = pow(2.2,DISTORT_POINTER);
    float d = length(uv);
    d = pow(d,DISTORT_POINTER)/d * factor;
    return uv*d;
}

vec3 mask(vec2 uv){
    float d = length(uv);
    return 1.2*vec3(1.0-d*d);
}
vec3 render(vec2 uv)
{
    if(uv.x>M_RADIUS)uv*=M_RADIUS/length(uv);
    float ts = time*ROTATE_SPEED;
    vec3 cosOffset = 0.2*cos(ts)+2.75+vec3(0,1,2) + 0.3*angleUnit;
    vec3 style = vec3(0.9,0.70,0.76);
    float edge = uv.x<M_RADIUS?max(pow(1.0-uv.x/M_RADIUS,0.1),0.0):1.0;
    float flow = max(0.5+0.5*cos(uv.y/M_RADIUS*PI+ts ),0.0);
    float edgeFactor = 0.5-0.5*cos(ts);
    float flowFactor = 0.0+0.1*cos(ts/3.0-0.5*PI);
    float shadow = edgeFactor*edge+flowFactor*flow+1.0-edgeFactor-flowFactor;
    vec3 col =cos(cosOffset+(uv.xyx*COLOR_RANGE/M_RADIUS+COLOR_RANGE)*20.0);
    col = 1.0-SATURATION*0.5+SATURATION*0.5*col;
    return style*shadow*col;
}
void main(void)
{
    // aspect ratio
    float invar = resolution.y / resolution.x;
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    vec3 col = mask(uv);
    uv.y *= invar;
    
    uv = cam(uv);
    uv = distort(uv);
    uv = bounce(uv);
    uv = rotate(uv);
    
    col *= render(uv);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
