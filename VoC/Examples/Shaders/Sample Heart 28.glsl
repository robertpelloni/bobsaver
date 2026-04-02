#version 420

// original https://www.shadertoy.com/view/3sdfWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/(min(resolution.x,resolution.y));

    vec3 bcol = vec3(1.,0.8,0.8)*(1.-0.38*length(uv.xy));
    
    
   float tt = mod(time,2.)/2.;  //u_time 为周期性输入的时间
    float ss = pow(tt,.2)*0.5 + 0.5;
    ss = 1.0 + ss*0.5*sin(tt*6.2831*3.0)*exp(-tt*4.0);//控制幅度的函数
    uv *= vec2(0.5,1.5) + ss*vec2(0.5,-0.5);
    
    
    //向下偏移0.25个单位
    uv.y-=0.25;
    
    float PI = 3.14159;
    float a = abs(atan(uv.x,uv.y) / PI);
    float p = length(uv);
    
    //心的颜色，向外扩展颜色稍微变浅
    vec3 hcol=vec3(1.,0.35*p,0.35*p);
    
    float d = (13.0*a - 22.0*a*a + 10.0*a*a*a)/(6.0-5.0*a);
    
    //这里直接用a-p也行，不过心形比较壮
    //vec3 rescol=mix(bcol,hcol,max(0.,a-p));
    vec3 rescol=mix(bcol,hcol,smoothstep(-0.03,0.03,d-p));
    // Output to screen
    glFragColor = vec4(rescol,1.0);
}
