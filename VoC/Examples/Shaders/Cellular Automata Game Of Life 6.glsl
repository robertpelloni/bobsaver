#version 420

//--- Conway's Game of Life ---
// by catzpaw 2016

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void) {
    vec2 uv=gl_FragCoord.xy;
    vec2 buv=gl_FragCoord.xy/resolution.xy;
    float dx=1./resolution.x,dy=1./resolution.y;
    float mx=floor(mouse.x*resolution.x);
    float my=floor(mouse.y*resolution.y);
    float ux=floor(uv.x),uy=floor(uv.y);

    vec3 color=vec3(0);
    float c=0.0,n=0.0,cell;

    n+=texture2D(backbuffer,vec2(buv.x-dx,buv.y-dy)).b;
    n+=texture2D(backbuffer,vec2(buv.x,buv.y-dy)).b;
    n+=texture2D(backbuffer,vec2(buv.x+dx,buv.y-dy)).b;

    n+=texture2D(backbuffer,vec2(buv.x-dx,buv.y)).b;
    cell=texture2D(backbuffer,vec2(buv.x,buv.y)).b;
    n+=texture2D(backbuffer,vec2(buv.x+dx,buv.y)).b;

    n+=texture2D(backbuffer,vec2(buv.x-dx,buv.y+dy)).b;
    n+=texture2D(backbuffer,vec2(buv.x,buv.y+dy)).b;
    n+=texture2D(backbuffer,vec2(buv.x+dx,buv.y+dy)).b;
    
    //B3/S23 standard rule
    if(cell==1.0){
        if(n==2.0)c=1.0;    //survive
        if(n==3.0)c=1.0;    //survive
    //    if(n==7.0)c=1.0;    //B3/S237　proliferation
    }else{
        if(n==3.0)c=1.0;    //birth
    //    if(n==6.0)c=1.0;    //B36/S23 high life
    }
    
    c+=step(abs(ux-mx)+abs(uy-my),1.);    //mouse
    vec4 b=texture2D(backbuffer,buv);    //last state

    color=vec3(b.g,cell,c);    //3bit color
                //r:dead g,y:death b,c,m:birth w:survive

    //color=vec3(c);      //traditional 1bit color
                //black:death white:life
    
    glFragColor =vec4(color,1);
}
