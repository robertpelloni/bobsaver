#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec2 F(float a, float s, float v){
    float r=1.0;
    vec2 q=vec2(0.0);
    for(int j=0;j<13;j++){
        q+=vec2(cos(a),sin(a))*r;
        a*=s;r*=v;
    }
    return q;
}

void main() {
    vec2 p=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 col=texture2D(backbuffer,gl_FragCoord.xy/resolution.xy).rgb;
    p*=2.5;
    float s=-2.0,r=0.65;
    vec3 clr=vec3(1.0,0.6,0.3);
    mat2 rm=mat2(cos(0.32),sin(0.32),-sin(0.32),cos(0.32));
    float t=time,d=100.0,dm=d,et=t+1.0;
    for(int i=0;i<9;i++)if(t>5.0){t-=5.0;s-=1.0;r-=0.1;clr=clr.yzx;clr.xy=clr.xy*rm;}
    for(int i=0;i<100;i++){
        t+=d=0.06*length(p-F(t,s,r));
        if(t>et)break;
        dm=min(dm,d);
    }
    d=smoothstep(0.0,0.001,dm);
    col=mix(clr,col*d,d);
    glFragColor = vec4(col,1.0);
}
