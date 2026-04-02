#version 420

// original https://www.shadertoy.com/view/4sBGRh

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

void main(void)
{    
    vec2 uv=gl_FragCoord.xy*(1./128.0);
    float res=min(resolution.x,resolution.y);
    float pixel=1.0/res;
    vec2 p = (gl_FragCoord.xy-resolution.xy*0.5) * pixel;    
    
    float ink=0.0,theta=0.0;
    float rr=res;
    float ofs=0.02+0.00051*time*pixel*0.25;
    for (int iter=0;iter<100;++iter) {
        ink+=  max(0.0,1.0-abs(length(p)-0.37)*rr);
        rr/=1.1;
        p*=1.1;
        p.x+=ofs*sin(theta);
        p.y+=ofs*cos(theta);        
        theta+=time*0.1;
    }
    ink=sqrt(ink)*0.5;    
    vec3 col = vec3(0.75*0.9) * smoothstep(1.0,0.0,ink);    
    glFragColor=vec4(pow(col*vec3(0.99,0.98,0.97),vec3(0.5)),1.0);

}
