#version 420

#define GS (20.0)
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec2 magnify(vec2 v,vec2 c,float r)
{
    vec2 n = v-c;
    float l = length(v-c);
    return c + n * (smoothstep(-0.5,1.0,l/r));
}

vec2 hash21(float p)
{
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

void main( void ) {

    vec2 v = gl_FragCoord.xy;

    for (float i=0.0;i<=1.01;i+=0.02)
    {
        vec2 pe = (vec2(3.0) + 10.0*hash21(i*520.4+120020.4))*vec2(resolution.x/resolution.y,1.0);
        v = magnify(v,vec2(abs(0.5*pe.x-mod(time,pe.x))*2.0/pe.x,abs(0.5*pe.y-mod(time,pe.y))*2.0/pe.y)*resolution,resolution.y*(0.10 + 0.0*0.3*i));
    }
    vec2 pd = floor(v/GS)*GS;
    
    vec3 cp = texture2D(backbuffer,v/resolution).rgb;  
    vec3 color = hash32(pd) ;
    color *= 3.0*length(v-gl_FragCoord.xy)/resolution.y;
    color += cp - vec3(1.0,1.0,1.0)*0.01;
  
    glFragColor = vec4(color, 1.0 );

}
