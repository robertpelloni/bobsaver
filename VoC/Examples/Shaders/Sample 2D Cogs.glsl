#version 420

// original https://www.shadertoy.com/view/wdtGWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define iterX 10
#define iterY 6

mat2 rotate2d(float _angle){//https://thebookofshaders.com/08/
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float rectangle(vec2 uv, vec2 center, vec2 size){
return step(abs(uv.x-center.x), size.x/2.)*step(abs(uv.y-center.y), size.y/2.);
}

float elipse(vec2 uv, vec2 center, vec2 size){
return step(distance(uv/size,center), 0.2);
}

float cog(vec2 uv, float cogRadius, int cogSize, float rotSpeed, float scale,float dill)
{
    float cog;
    uv /= scale;
    uv *= rotate2d((dill+sin(time/4.)*4.)*rotSpeed); // rotation of the cog
    for(int i = 0; i<cogSize; i++)//setting the ends of the cog - number and size
    {
       float toDeg = 3.14159/180.0;
       cog += clamp(rectangle(uv*rotate2d((360.)/float(cogSize)*float(i+1)*toDeg),vec2(0.,0.2), vec2(.06, 0.055)),0.,1.);
    };
    cog += elipse(uv,vec2(0.),vec2(cogRadius*3.))-rectangle(uv,vec2(0.),vec2(cogRadius*0.35));
    return cog;
}

float generateCogsX(vec2 uv, float iniDir, float tOffset)
{
    float cogSet;
    float dir = iniDir;
    float dill = 0.0+tOffset;
    float cogOffset = 0.0825;

    uv.x -= cogOffset*(float(iterX)-1.)/2.;
    for(int i = 0; i<iterX; i++)//setting the ends of the cog - number and size
    {
       uv.x += cogOffset*min(float(i),1.); //offset the cog
       dir *= -1.; //change the direction of rotation
       dill += 180.*(-1.);// offset the roation to match the next cog
       cogSet += cog(uv,0.3,10,dir,0.2,dill);
    };
    return cogSet;
}

float cogsXY(vec2 uv)
{
    float dir = -1.;
    float cogs;
    float cogOffset = 0.0825;
    float tOffset = 0.;
    uv.y -= cogOffset*(float(iterY)-1.)/2.;
    for(int i = 0; i<iterY; i++)//setting the ends of the cog - number and size
    {
        tOffset += 180.;
        dir *= -1.;
        uv.y += cogOffset*min(float(i),1.); //offset the cog
        cogs += generateCogsX(uv, dir, tOffset);
    };
    return cogs;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.0)/resolution.x;

    vec3 col = vec3(0.2,0.4,0.0)*min(cogsXY(uv),1.0);
    col += (1.-min(cogsXY(uv),1.0)) * vec3(1.,.8,.0);
    
    glFragColor = vec4(col,1.0);
}
