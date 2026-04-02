#version 420

// original https://www.shadertoy.com/view/Nd3GDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by hyunamy - 2021.08
// License Creative Commons Attribution-NonCommercial-Share Hyunamy 3.0 Unported License.

const float PI = 3.141592;

vec3 RED = vec3(206., 17., 39.) / 255.;
vec3 BLUE = vec3(0., 62., 135.) / 255.;

const float PadX = .39;
const float PadY = .26;

const float LW = .3;
const float CenterScale = .625;
const float WingScale = .43;

mat2 rotationMatrix(float angle)
{
    angle *= PI / 180.0;
    float s = sin(angle), c=cos(angle);
    return mat2( c, -s, s, c );
}

float Band(float t, float start, float end, float blur)
{
    float step1 = smoothstep(start-blur, start+blur, t);
    float step2 = smoothstep(end+blur, end-blur, t);
    return step1 * step2;
}

float Rect(vec2 uv, float l, float r, float b, float t, float blur) 
{
    float band1 = Band(uv.x, l, r, blur);
    float band2 = Band(uv.y, b, t, blur);    
    
    return band1 * band2;
}

vec4 LeftTop(vec2 uv, float angle, float scale)  
{
    vec4 col = vec4(0);
    
    uv *= rotationMatrix(angle) / scale;
    
    col += Rect(uv, -LW, LW, .1, .2, .005);   
    col += Rect(uv, -LW, LW, -.05, .05, .005);   
    col += Rect(uv, -LW, LW, -.2, -.1, .005);   
    col.rgb *= 0.;
    
    return col;
}

vec4 RightTop(vec2 uv, float angle, float scale)
{
    vec4 col = vec4(0);   
    
    uv *= rotationMatrix(angle) / scale;
    
    float w = .45;
    float l = LW - LW * w;
    float r = LW - LW * w;
    
    col += Rect(uv, -LW * w - l, LW * w - l, .1, .2, .005);   
    col += Rect(uv, -LW * w + r, LW * w + r, .1, .2, .005);   
    col += Rect(uv, -LW, LW, -.05, .05, .005);    
    col += Rect(uv, -LW * w - l, LW * w - l, -.2, -.1, .005);   
    col += Rect(uv, -LW * w + r, LW * w + r, -.2, -.1, .005);   
    
    col.rgb *= 0.;
    return col;
}

vec4 LeftBottom(vec2 uv, float angle, float scale)
{
    vec4 col = vec4(0);   
    
    uv *= rotationMatrix(angle) / scale;
    
    float w = .45;
    float l = LW - LW * w;
    float r = LW - LW * w;
    
    col += Rect(uv, -LW, LW, .1, .2, .005);   
    col += Rect(uv, -LW * w - l, LW * w - l, -.05, .05, .005);   
    col += Rect(uv, -LW * w + r, LW * w + r, -.05, .05, .005);
    col += Rect(uv, -LW, LW, -.2, -.1, .005); 
    
    col.rgb *= 0.;
    return col;
}

vec4 RightBottom(vec2 uv, float angle, float scale)
{
    vec4 col = vec4(0);   
    
    uv *= rotationMatrix(angle) / scale;
    
    float w = .45;
    float l = LW - LW * w;
    float r = LW - LW * w;
     
    col += Rect(uv, -LW * w - l, LW * w - l, .1, .2, .005);   
    col += Rect(uv, -LW * w + r, LW * w + r, .1, .2, .005);   
    col += Rect(uv, -LW * w - l, LW * w - l, -.05, .05, .005);   
    col += Rect(uv, -LW * w + r, LW * w + r, -.05, .05, .005);
    col += Rect(uv, -LW * w - l, LW * w - l, -.2, -.1, .005);   
    col += Rect(uv, -LW * w + r, LW * w + r, -.2, -.1, .005);     
    
    col.rgb *= 0.;
    return col;
}

vec4 CenterBody(vec2 uv, float scale)
{
    vec2 rotatedUV = uv * rotationMatrix(30.) / scale;
    
    float body = smoothstep(0.01, 0., rotatedUV.y);    
    vec4 col = vec4(mix(RED, BLUE, body), 1.);

    float d = length(rotatedUV);
    col.a = smoothstep(0.4, 0.39, d);    
    
    float sd = length(rotatedUV - vec2(-0.2, 0.0));
    float sc = smoothstep(0.205, 0.195, sd);
    col.rgb = mix(col.rgb, RED, sc);
    
    sd = length(rotatedUV - vec2(0.2, 0.0));
    sc = smoothstep(0.205, 0.195, sd);
    col.rgb = mix(col.rgb, BLUE, sc);
    
    return col;
}

vec4 Flag(vec2 uv)
{
    vec4 col = vec4(0); 
    
    vec4 body = CenterBody(uv, CenterScale);    
    col = mix(col, body, body.a);
    
    vec4 lt = LeftTop(uv - vec2(-PadX,PadY), -50., WingScale);
    col = mix(col, lt, lt.a);
    
    vec4 rt = RightTop(uv - vec2(PadX,PadY), 50., WingScale);
    col = mix(col, rt, rt.a);
    
    vec4 lb = LeftBottom(uv - vec2(-PadX,-PadY), 50., WingScale);
    col = mix(col, lb, lb.a);
    
    vec4 rb = RightBottom(uv - vec2(PadX,-PadY), -50., WingScale);
    col = mix(col, rb, rb.a);
    
    return col;
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    float t = uv.x * 5. - time * 1.4 + uv.y * 3.5;
    uv.y += sin(t)*.035;
    
    vec4 col = vec4(1);    
    
    vec4 flag = Flag(uv);
    col = mix(col, flag, flag.a);
    float shadow = .95 + cos(t) *.156;    
    col *= shadow;
    col *= smoothstep(0.5, 0.495, abs(uv.y)); 
    
    glFragColor = col;
}
