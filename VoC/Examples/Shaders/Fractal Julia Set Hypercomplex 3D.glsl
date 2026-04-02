#version 420

// original https://www.shadertoy.com/view/tdc3W7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 multiply(vec3 a,vec3 b){
    float r1 = sqrt(a.x*a.x+a.y*a.y);
    float r2 = sqrt(b.x*b.x+b.y*b.y);
    if(r1==0.){
        if(r2==0.)
            return vec3(-a.z*b.z,0.,0.);
        else
            return vec3(-a.z*b.z*b.x/r2,-a.z*b.z*b.y/r2,a.z*r2);
    }
    else{
        if(r2==0.)
            return vec3(-a.z*b.z*a.x/r1,-a.z*b.z*a.y/r1,b.z*r1);
        else{
            float gamma = 1.-a.z*b.z/(r1*r2);
            return vec3((a.x*b.x-a.y*b.y)*gamma,(a.x*b.y+b.x*a.y)*gamma,a.z*r2+b.z*r1);
        }
    }
}
mat3 roty = mat3(
    vec3(1., 0., 0.),
    vec3(0.,cos(3.14/2.), sin(3.14/2.)),
    vec3(0.,-sin(3.14/2.), cos(3.14/2.))
);

void main(void)
{   
    mat3 rot = mat3(
        vec3(1., 0., 0.),
        vec3(0.,cos(time), sin(time)),
        vec3(0.,-sin(time), cos(time))
    );
    mat3 rotx = mat3(
        vec3(cos(time), sin(time),0.),
        vec3(-sin(time), cos(time),0.),
        vec3(0., 0., 1.)
    );
    vec2 uv = (-1.0 + 2.0*gl_FragCoord.xy / resolution.xy) * 
        vec2(resolution.x/resolution.y, 1.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    vec3 color = vec3(0.);
    vec3 ro = vec3(0.0,0.0,2);
    
    // modify ///
    vec3 c = vec3(-0.7,0.0,0.);
    
    for(int i = 0; i<100; i++){
        vec3 point = rot*rotx*roty*(rd*(float(i)/100.*2.)-ro); 
    bool flag = false;
        for(int j = 0;j<30;j++){
           point = multiply(point,point)+c;
            float mq = dot(point,point);
            if( mq > 4.){
                flag = true;
                break;
            }
        }
        if(!flag){          
            color += vec3(2.*float(i)/8000., float(i)/8000.,0.0);
        }
    }
    glFragColor = vec4(color, 1.);
}
