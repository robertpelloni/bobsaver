#version 420

// original https://www.shadertoy.com/view/3ssSWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float AA=2.;
vec3 fractal(vec2 crd){
    vec2 c = crd/resolution.xy;
    c=2.*c-1.;
    c.x*=resolution.x/resolution.y;
    c/=35.;
       vec2 ms= 2.*mouse*resolution.xy.xy/resolution.xy-1.;
    c+=ms;
       vec2 z = vec2(0);
    z=c;
    float i;
    float m=0.;
    for(i=0.;i<20.;i++){
        z=abs(z)/dot(z,z)+vec2(-.9,-.3);
        m=max(m,length(z));
    }
    for(i=0.;i<64.;i++){
        vec2 tz=vec2(-.9,-.3)+vec2(z.x*z.x-z.y*z.y,2.*z.x*z.y);
        z=tz;
        if(length(z)>2.){
            break;
        }
    }
    float ic=5.*i/64.;
    float it=clamp(m/(20.+15.*sin(time)),0.,8.);
    vec3 col=vec3(cos(it+1.-ic),cos(it+2.-ic),cos(it+3.-ic));
    return col;
}

void main(void) {
    vec3 col;
    for(float i=0.;i<AA;i++){
        for(float j=0.;j<AA;j++){
            col+=fractal(gl_FragCoord.xy+(vec2(i,j)/AA));
        }
    }
    col/=AA*AA;
    glFragColor = vec4(col,1.0);
}
