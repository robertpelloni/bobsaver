#version 420

// original https://www.shadertoy.com/view/XlBXWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 xyRot(float n, in vec2 xy)
    {
        return vec2(xy.x*cos(n)-xy.y*sin(n),
                    xy.x*sin(n)+xy.y*cos(n));
    }

float r(vec2 xy)
    {
        vec2 tmp1 = xyRot(time*.02,xy);
        float tmp2 = 70.+10.*(sin(time*.1));
        return sqrt(pow(sin(tmp1.x*tmp2),2.) +
                    pow(sin(tmp1.y*tmp2),2.));
    }

float a(float m, float n, float x, float y)
    {
        return (x+sin(time*m))*(y+cos(time*n))*sin(time*.1+x*y+m+n);
    }

float s(float n, float r)
    {
        return abs(1.-abs(n-r));
    }

void main(void)
{
   vec2 xy = gl_FragCoord.xy / resolution.xy - vec2(0.5,0.5);
   xy.x *= resolution.x/resolution.y;
   float r_ = r(xy);
   glFragColor.r = s(s(a(xy.x*.2+time*.005,xy.y*.21,xy.x,xy.y),r_),xy.x);
   glFragColor.g = s(s(a(xy.x*.23,xy.y*.25+time*.005,xy.x,xy.y),r_),xy.y);
   glFragColor.b = s(s(a(xy.x*.27,xy.y*.29,xy.x,xy.y),r_),(xy.x+xy.y)*.5);
}
