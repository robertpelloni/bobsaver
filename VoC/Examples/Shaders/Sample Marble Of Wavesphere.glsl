#version 420

// original https://www.shadertoy.com/view/wtXcz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/MdySzR

vec2 pa(in vec2 uv, in float per){
    vec2 result = (cos(uv.x*per)) * normalize(vec2(cos((uv.x)*per), .5));
    return result;
}

vec2 pb(in vec2 uv, in float per){
    vec2 result = (cos(uv.y*per)) * normalize(vec2(1., cos((uv.y)*per)));
    return result;
}
mat2x2 rot(float angle)
{
    float c=cos(angle);
    float s=sin(angle);
    return mat2x2(c,-s,s,c);
}
float sdWaveSphere(vec3 p,float radius,int waves,float waveSize)
{
    //bounding Sphere
    float d=length(p)-radius*2.2;
    if(d>0.)return.2;
    // deformation of radius
    d=waveSize*(radius*radius-(p.y*p.y));
    radius+=d*cos(atan(p.x,p.z)*float(waves));
    return.5*(length(p)-radius);
}
void main(void)
{
    float t = time*.35;
    
    vec2 uv =(gl_FragCoord.xy / resolution.xy);
    uv.x *= resolution.x/resolution.y*.5+.5;
         uv*=rot(-.14*t);// вращение uv   
    vec2 vpert = pa(uv, 5.);//5-15
    uv += vpert * sin(t) *.32;//.3-.9
    
    vec2 hpert = pb(uv, 5.);//5-15
     uv += hpert * sin(t) * .3208;//.3-.9
    
    //vec4 col = texture2D(iChannel0, uv);
    //glFragColor=glFragColor=mix(vec4(sin(uv.x*2.),0.,//градиент
    //cos(uv.y*3.),1.),col,.9);
    glFragColor = mix(6.*vec4(sin(uv.x*12.), mod(uv.x*12., .25),//градиент 
    cos(uv.y*13.), 1.),vec4(sin(t*.5)*3.,sin(t*.5),sin(t*1.5)*
    11.,tan(t*22.15)*1.), .49);
       //float sdWaveSphere(vec3 p,float radius,int waves,float waveSize)
    float wave=sdWaveSphere(uv.xxy,1.518,15,t*.4);
    glFragColor =glFragColor* wave;
}
