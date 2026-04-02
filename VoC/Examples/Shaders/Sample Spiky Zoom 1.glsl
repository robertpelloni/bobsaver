#version 420

// original https://www.shadertoy.com/view/lsVcRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rnd(float a, float i, float arms){
    //const float arms=20.;
    float i1=mod(floor(a*arms),arms)+mod(i*12.672,2236.77621);
    float i2=mod(floor(a*arms+1.),arms)+mod(i*12.672,2236.77621);

    float i11=mod(cos(i1*mod(i1,3.)*.00632)*356.9,1.);
    float i22=mod(cos(i2*mod(i2,3.)*.00632)*356.9,1.);
    float span=mod(a*arms,1.);
    return i22*span+i11*(1.-span);
}

vec3 col(float i){
    if(cos(i*i)<-.98){
        return (1.+cos(acos(-1.)*vec3(mod(cos(i*.045621)*2341.,1.),mod(cos(i*.085601)*2311.,1.),mod(cos(i*.049691)*2141.,1.))))*.5;
    }
    else{
        float phase=mod(floor(i/20.),3.);
        float mixx=mod(i,20.)/20.;
        vec3 c1;
        vec3 c2;
        if(phase<.5){
            c1=vec3(0.,0.,0.);
            c2=vec3(1.,0.6,0.);
        }
        else if(phase<1.5){
            c1=vec3(1.,0.6,0.);
            c2=vec3(0.,0.3,1.);
        }
        else{
            c1=vec3(0.,0.3,1.);
            c2=vec3(0.,0.,0.);
        }
        return c1*(1.-mixx)+c2*mixx;
    }
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.)/resolution.yy;
    
    // Output to screen
    glFragColor = vec4(0.0,0.0,0.0,1.0);
    
    float angle=atan(uv.y,uv.x)/acos(-1.)/2.;
    
    float layer=floor(time/2.);
    float zoom=mod(time/2.,1.);
    float pixelsize=1./resolution.y;
    float stepsclose=floor(log(length(uv))/log(1.2));
    float aa;
    for(aa=1.;aa<14.;aa++){
        float a=aa+stepsclose;
        float zooma=pow(1.2,a+zoom);
        vec2 uvzoom=uv/zooma;
        float bend=.6-length(uvzoom);
        float pixelsize2=pixelsize/length(uv)*.05;
        float angle2=mod(angle+bend*bend*bend*bend*.4*sin((a-layer)*.3+time),1.);
        float b;
        float cover=0.;
        for(b=-2.;b<=2.;b++){
            float h=rnd(mod(angle2+b*pixelsize2,1.),a-layer,floor(60.*(1.2+sin(0.0774*(a-layer)))))*.5+.1;
            if(h<length(uvzoom)){
                cover+=0.2;
                //glFragColor = vec4(vec3(a+zoom)*.02+.2,1.0);
            }
        }
        glFragColor = vec4(col(a-layer),1.0)*cover+glFragColor*(1.-cover);
    }

}
