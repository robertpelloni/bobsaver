#version 420

#define GS (20.0)
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define ms mouse*resolution

vec2 rotate(float angle,vec2 center,vec2 v)
{
    float ca = cos(angle);
    float sa = sin(angle);
    return mat2(ca,sa,-sa,ca)*(v-center)+center;
}

mat3 rotMat(float angle,vec2 center)
{
    float ca = cos(angle);
    float sa = sin(angle);
    mat3 m = mat3(vec3(ca,-sa,0.0),vec3(+sa,ca,0.0),vec3(center.x*(1.0-ca)-sa*center.y,center.y*(1.0-ca)+center.x*sa,1.0));
    
    return m;
}

mat3 rangeMat(mat3 m,mat3 mi,float c)
{
    return mat3(vec3(mix(m[0],mi[0],c)),vec3(mix(m[1],mi[1],c)),vec3(mix(m[2],mi[2],c)));
}

vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

void main( void ) {

    vec2 c = gl_FragCoord.xy;
    
    c = vec2(rangeMat(rotMat(time/20.0,ms),rotMat(-time/20.0,ms),0.005*length(c-resolution/2.0))*vec3(c,1.0));
    
    //c = rotate(time/16.0,resolution/2.0,c)*rotate(time/10.0,mouse*resolution.xy,c)/resolution.xy;
    
    vec2 pd = floor(c/GS)*GS;
    
    
vec3 color = hash32(pd);

    
    glFragColor = vec4(color, 1.0 );

}
