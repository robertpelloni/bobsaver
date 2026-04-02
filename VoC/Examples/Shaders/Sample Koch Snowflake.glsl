#version 420

// original https://www.shadertoy.com/view/Wss3zX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592654

vec2 ToPolar(vec2 rectPos)
{
    vec2 pos = -rectPos;
    float r = length(pos)*2.0;
    float a = atan(pos.y,pos.x) + PI;
    return vec2(r,a);
}

vec2 Rotate(vec2 pos, float angle)
{
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle))*pos;
}

// ====================== Choose a Shape ===========================
float Circle(vec2 center, vec2 pos, float radius)
{
    vec2 dir = pos - center;
    return step(dot(dir,dir),pow(radius,2.0));
}

float Triangle(vec2 center, vec2 pos, float radius)
{
    vec2 dir = pos - center;
    return step(-radius,dir.y)*
        step(dir.y, sqrt(3.0)*dir.x+2.0*radius)*
        step(dir.y, -sqrt(3.0)*dir.x+2.0*radius);
}

float Hexagram(vec2 center, vec2 pos, float radius)
{
    float t1 = Triangle(center, pos, radius);
    
    pos = center + Rotate(pos-center,PI);
    
    float t2 = Triangle(center, pos, radius);
    return max(t1,t2);
}

float DrawShape(vec2 center, vec2 pos, float radius)
{
    float shapeRatio = sin(time*0.7)*0.5+0.5;
    return
        //Triangle(center, pos, radius);
        shapeRatio*Circle(center, pos, radius) + 
        (1.0-shapeRatio)*Hexagram(center, pos, radius);
}
// =================================================================

float Koch(vec2 pos, int n)
{
    float radius = 100.0;
    vec2 center = vec2(0.0);
    
    float c = DrawShape(center,pos,radius);
    
    for(int i = 0;i<n;i++)
    {
        vec2 localPos = pos - center;
        float polarAngle = atan(-localPos.y,-localPos.x) + PI;
        float index = floor(polarAngle/(PI/3.0))+0.5;
        center += (radius*4.0/3.0)*vec2(cos(index*PI/3.0),sin(index*PI/3.0));
        radius /= 3.0;
        c += DrawShape(center,pos,radius);
    }
    return c;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pos = (uv - vec2(0.5))*800.0;
    pos.x *= resolution.x/resolution.y;
    
    float t = time;
    // rotate & scale
    pos = Rotate(pos,time*0.4)*(1.0+0.2*sin(t));
    // alpha
       float c = Koch(pos, 4)*(sin(time)*0.2+0.35);
    
    // color it
    vec3 col = 
        vec3(0.1,0.15,0.2)*pow(1.5-length(uv-vec2(0.5)),2.0) + 
        vec3(0.4,0.8,0.88)*c;
    
    glFragColor = vec4(col,1.0);
}
