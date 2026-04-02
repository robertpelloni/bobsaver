#version 420

// original https://www.shadertoy.com/view/Wl3BD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(float value,float min1,float max1,float min2,float max2){
    return min2+(value-min1)*(max2-min2)/(max1-min1);
}

vec2 createGrid(in vec2 st,in vec2 grid,out vec2 indices){
    
    st*=grid;
    indices=floor(st);
    st=fract(st);
    
    return st;
}

float drawRectangle(vec2 st,vec2 pos,vec2 size){
    
    float result=1.;
    vec2 border=(1.-size)/2.200;
    st=st-pos+vec2(.5);
    result=step(border.x,st.x);
    result*=step(border.x,1.-st.x);
    result*=step(border.y,st.y);
    result*=step(border.y,1.-st.y);
    
    return result;
}

#define drawCircle(st,pos,size) smoothstep(0.,15./resolution.y,size - length(pos-st) )

void main(void)
{
    vec2 st=gl_FragCoord.xy/resolution.xy;
    st.x*=resolution.x/resolution.y;
    
    vec2 st0=st;
    vec2 indices;
    st=createGrid(st,vec2(10.,10.),indices);
    
    float delay=.45;
    float circSize=map(cos(time*delay*2.),-1.,1.,0.71,0.5);
    vec2 size=vec2(.25,.25);
    vec2 pos=vec2(.5,.5);
    
    vec3 white=vec3(1.);
    vec3 black=vec3(0.);
    vec3 canvas=vec3(0.);
    
    float animation0to1=map(cos(time*delay),-1.,1.,0.01,0.99);
    float animation1to0=map(cos(time*delay),-1.,1.,.99,0.01);
    float rect=drawRectangle(st,vec2(.5),vec2(1.));
    
    float circleTLTR=drawCircle(st,vec2(animation0to1,1.),circSize);
    float circleBRTL=drawCircle(st,vec2(animation1to0,0.),circSize);
    float circleLTTB=drawCircle(st,vec2(0.,animation1to0),circSize);
    float circleRBTT=drawCircle(st,vec2(1.,animation0to1),circSize);
    
    if((mod(indices.x,2.)==0.&&mod(indices.y,2.)==1.)||(mod(indices.x,2.)==1.&&mod(indices.y,2.)==0.)){
        
        canvas=mix(canvas,white,rect);
        canvas=mix(canvas,black,circleTLTR);
        canvas=mix(canvas,black,circleBRTL);
        
    }else{
        
        canvas=mix(canvas,black,rect);
        canvas=mix(canvas,white,circleRBTT);
        canvas=mix(canvas,white,circleLTTB);
        
    }
    
    glFragColor=vec4(canvas,1.);

}
