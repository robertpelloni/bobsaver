#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XdXBWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415972

vec3 textureColor(vec2 uv)
{
    float period = 0.4;
    uv = mod(uv, vec2(period));
    
    float x = uv.x - period*0.5;
    float y = uv.y - period*0.5;
    
    float pixelSizeX = 2.0/resolution.x;
    float pixelSizeY = 2.0/resolution.y;
    
    float tx = smoothstep(0.0, 1.0, 0.5+x/pixelSizeX);
    float ty = smoothstep(0.0, 1.0, 0.5+y/pixelSizeY);
    float t = tx+ty-2.0*tx*ty;
        
    return vec3(t);
}

vec2 vertexRestPos(int i)
{
    vec2 pos =  2.0*(vec2(float(i!=0 && i != 3), float(i/2 != 0))-vec2(0.5));
    
    return pos;
}

vec2 vertexPos(int i, float t)
{
    float dispRad = 0.3;
    float dispFreq = float(i+1)*0.25;
    //float dispFreq = pow(2.0, float(i+1))*0.1;
    if(i%2==0)
        dispFreq *= -1.0;
    vec2 disp = vec2(cos(2.0*M_PI*t*dispFreq), sin(2.0*M_PI*t*dispFreq))*dispRad;
    
    vec2 pos =  vertexRestPos(i);
    
    //if(i == 0 && mouse*resolution.xy.z>0.0)
    //if(i == 0)
    //    return 3.0*(mouse*resolution.xy.xy / resolution.y - 0.5*vec2(resolution.x / resolution.y, 1.0));
    
    return pos+disp;
}

vec4 vertexColor(in vec2 p)
{
    vec4 color = vec4(1.0, 0.0, 0.0, 0.0);
    float radius = 0.05;
    for(int i=0; i<4; ++i)
    {
        if(length(vertexPos(i, time) - p) < radius)
        {
            color.a = 1.0;
            return color;
        }
    }
    return color;
}

vec2 PointSegProj(vec2 p, vec2 p0, vec2 p1)
{
    vec2 d = p1 - p0;
    return mix(p0, p1, clamp(dot(p - p0, d) / dot(d, d), 0.0, 1.0));
}

float PointSegDistance2(vec2 p, vec2 p0, vec2 p1)
{
    vec2 proj = PointSegProj(p, p0, p1);
    return dot(proj-p, proj-p);
}

vec4 segmentColor(in vec2 p)
{
    vec4 color = vec4(0.0, 1.0, 0.0, 0.0);
    float radius = 0.02;
    radius = radius*radius;
    for(int i=0; i<4; ++i)
    {
        if(PointSegDistance2(p, vertexPos(i, time), vertexPos((i+1)%4, time)) < radius)
        {
            color.a = 1.0;
            return color;
        }
    }
    return color;
}

float weight(vec2 p, int i)
{
    vec2 p0 = vertexRestPos((i+3)%4);
    vec2 p1 = vertexRestPos(i);
    vec2 p2 = vertexRestPos((i+1)%4);
    
    vec2 d0 = p - p0; d0 = d0/length(d0);
    vec2 d1 = p - p1; d1 = d1/length(d1);
    vec2 d2 = p - p2; d2 = d2/length(d2);
    
    float epsilon = 0.000001;
    float alpha0 = acos(epsilon/2.0 + (1.0-epsilon) * dot(d0, d1));
    float alpha1 = acos(epsilon/2.0 + (1.0-epsilon) * dot(d2, d1));
    
    return (tan(alpha0*0.5) + tan(alpha1*0.5))/length(p-p1);
}

vec2 wrappDisp(vec2 p)
{
    vec2 d0 = vertexPos(0, time) - vertexRestPos(0);
    vec2 d1 = vertexPos(1, time) - vertexRestPos(1);
    vec2 d2 = vertexPos(2, time) - vertexRestPos(2);
    vec2 d3 = vertexPos(3, time) - vertexRestPos(3);
    
    float w0 = weight(p, 0);
    float w1 = weight(p, 1);
    float w2 = weight(p, 2);
    float w3 = weight(p, 3);
    
    return (d0*w0 + d1*w1 + d2*w2 + d3*w3) / (w0+w1+w2+w3);
}

vec2 inversePos(vec2 p)
{
    vec2 orig = p;
    for(int i=0; i<10; ++i)
    {
        vec2 newPos = orig + wrappDisp(orig);
        orig = orig + (p-newPos);
    }
    
    return orig;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y;
    uv = uv - 0.5*vec2(resolution.x / resolution.y, 1.0);
    
    float zoom = 3.0;
    uv = uv*zoom;
    
    vec3 color = textureColor(uv);
    
    //vec2 uvWrap = uv - wrappDisp(uv);
    vec2 uvWrap = inversePos(uv);
    
    color = textureColor(uvWrap);
    
    vec4 segCol = segmentColor(uv);
    color = mix(color, segCol.rgb, segCol.a);
    
    vec4 vertCol = vertexColor(uv);
    color = mix(color, vertCol.rgb, vertCol.a);
        

        
    glFragColor = vec4(color,1.0);
}
