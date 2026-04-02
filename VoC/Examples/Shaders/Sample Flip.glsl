#version 420

// original https://www.shadertoy.com/view/WtGSzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI=acos(-1.);

float h21(vec2 p) {
    p=fract(p*vec2(589.27,916.79));
    p+=dot(p,p+23.51);
    return fract(p.x*p.y);
}

mat2 rmat(float theta) {
    float s=sin(theta),c=cos(theta);
    return mat2(c,-s,s,c);
}

void main(void) {
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t=time;
    
    uv *= 10.+7.*sin(t*.283);
    uv *= rmat(sin(t*.114));
    
    vec2 xy=fract(uv)-.5;
    float r=h21(floor(uv));
    
    float side=sign(xy.x);
    xy.x=abs(xy.x);
    
    float phase=t*.25+r*2.*PI;
    float flip=.01+.49*smoothstep(0.,.1,abs(sin(phase)*.5));
    float fill=1.-step(flip,xy.x);
    
    float dim=0.2+0.8*smoothstep(0.,.5,flip);
    vec3 col=vec3(fill*dim);
    col*=.4+.6*vec3(fract(r*12.3),fract(r*56.9),fract(r*177.2));
    
    const float bev=.06,nbev=.5-bev;
    float edge=step(flip-bev,xy.x*side);
    edge-=step(flip-bev,xy.x*-side);
    edge+=step(nbev,xy.y);
    edge-=(1.-step(-nbev,xy.y));
    col *= (1.+.2*edge);
    
    glFragColor=vec4(col,1);
}
