#version 420

// original https://www.shadertoy.com/view/slfyDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
float box(vec3 p,vec3 b){
    vec3 q = abs(p)-b;
    return length(max(q,vec3(0.)))+min(0.,max(q.x,max(q.y,q.z)));;
}
float diam(vec3 p,float s){
   p = abs(p);
   return (p.x+p.y+p.z-s)*inversesqrt(3.);
}
float mandel(vec2 uv){
    uv = vec2(log(length(uv)),atan(uv.x,uv.y));
    uv*=2.;
    uv = asin(sin(uv)*.9)/2.;
    vec2 z=uv;
    vec2 c = vec2(0.451410,-.1222) ;
    float i,lim = 200.;
    for(i=0.;i<lim;i++){
        z = vec2(z.x*z.x-z.y*z.y,2.*z.x*z.y)+c;
        if(dot(z,z)>4.) break;
        
    
    }
    return i/lim;

}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5* resolution.xy)/resolution.y;
    uv*=4.;
    vec3 col = vec3(.1);//vec3(1.)*mandel(uv);
    
    vec3 p,d=normalize(vec3(uv,1.));
    
    for(float i=0.,g=0.,e,t;i++<99.;){
      
       p = d*g;
      
       p.xy *= rot(time*.1);
       vec2 id = floor(p.xy);
        
        p.y +=mod(id.x,2.)==0. ? time:-time;
        id = floor(p.xy);
        
        p.z = asin(sin(p.z+time));
       p.xy =fract(p.xy)-.5;
       
       p.xy *=rot(-time*.2+id.y+id.x);
       
       float m = 1.-mandel(.1*sin(id+time)+min(abs(p.zx),min(abs(p.yx),abs(p.xy))))*1.44;
       
       float h = box(p,vec3(.25,.25,.1))*.8;
       g+=e=max(.01,abs(h));
       col += vec3(1.-(sin(id.y)*.5+.5),.5,cos(id.x*10.)*.5+.5)*smoothstep(m*.9,.3,.65)/exp(.9*i*i*e);
    
    };col=sqrt(col)*col;
    
    glFragColor = vec4(col,1.0);
}
