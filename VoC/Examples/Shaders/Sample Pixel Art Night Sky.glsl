#version 420

// original https://www.shadertoy.com/view/fsjXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 p)
{
    p=fract(p*vec2(123.456,789.01));
    p+=dot(p,p+45.67);
    return fract(p.x*p.y);
}
float star(vec2 uv,float brightness)
{
    float color=0.0;
    float star=length(uv);
    float diffraction=abs(uv.x*uv.y);
    //diffraction *= abs((uv.x + 0.001953125) * (uv.y + 0.001953125));
    star=brightness/star;
    diffraction=pow(brightness,2.0)/diffraction;
    diffraction=min(star,diffraction);
    diffraction*=sqrt(star);
    color+=star*sqrt(brightness)*8.0;
    color+=diffraction*8.0;
    return color;
}
void main(void)
{
    vec2 UV=gl_FragCoord.xy/resolution.yy;
    vec3 color=vec3(0.0);
    float dist=1.0;
    float brightness=.01;
    vec2 uv=(floor(UV*256.)/256.)-.51019;
    uv*=128.;
    uv+=floor((time)*64.)/3072.0;
    vec2 gv=fract(uv)-.5;
    vec2 id;
    float displacement;
    for(float y=-dist;y<=dist;y++)
    {
        for(float x=-dist;x<=dist;x++)
        {
            id=floor(uv);
            displacement=hash21(id+vec2(x,y));
            //color+=vec3(star(gv-vec2(x,y)-vec2(displacement,fract(displacement*16.))+.5,(hash21(id+vec2(x,y))/128.)));
            //color=min(color,.4);
        }
    }
    uv/=2.;
    gv=fract(uv)-.5;
    for(float y=-dist;y<=dist;y++)
    {
        for(float x=-dist;x<=dist;x++)
        {
            id=floor(uv);
            displacement=hash21(id+vec2(x,y));
            color+=vec3(star(gv-vec2(x,y)-vec2(displacement,fract(displacement*16.))+.5,(hash21(id+vec2(x,y))/128.)));
        }
    }
    uv/=8.;
    gv=fract(uv)-.5;
    for(float y=-dist;y<=dist;y++)
    {
        for(float x=-dist;x<=dist;x++)
        {
            id=floor(uv);
            displacement=hash21(id+vec2(x,y));
            color+=vec3(star(gv-vec2(x,y)-vec2(displacement,fract(displacement*16.))+.5,(hash21(id+vec2(x,y))/256.)));
        }
    }
    uv/=6.;
    gv=fract(uv)-.5;
    for(float y=-dist;y<=dist;y++)
    {
        for(float x=-dist;x<=dist;x++)
        {
            id=floor(uv);
            displacement=hash21(id+vec2(x,y));
            color+=vec3(star(gv-vec2(x,y)-vec2(displacement,fract(displacement*16.))+.5,(hash21(id+vec2(x,y))/256.)));
        }
    }
    color*=vec3(.5,.7,1.);
    //color = floor(0.01 + color * 16.0) / 16.0;
    glFragColor=vec4(color,1.);
}
