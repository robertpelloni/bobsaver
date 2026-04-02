#version 420

// original https://www.shadertoy.com/view/wdfXDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 R(in vec3 p, in float x){
    float y=p.y,
    c=cos(x),
    s=sin(x);
    x=p.x;
    return vec3(
        c*x+s*y,
        c*y-s*x,
        p.z
    );
}
//=====================================================

float box(in vec3 p, in vec3 b, in float r) {
    return length(max(abs(p) - b + r, 0.0)) - r;
}

float getDistance(vec3 p,out vec4 q){

    float d=p.z;
    
    q.xyz=(p+=vec3(
        2.*sin(d*.2+time*2.),
        sin(d*.1+time),
        .0
    ));

    q.w=-2.;

    d=-length(q.xy)+4.+.5*sin(atan(q.y,q.x)*6.)*sin(q.z);

    d=min(d,max((d-.01)*clamp(.8,.0,1.)+.01,d-.4));

    // Flow of boxes and spheres
    vec3 r=p;

    r.z+=time*20.;

    for(int i=0;i<3;++i){
        
            float a=floor(r.z/1.5+.5),
        b=a*3.+float(i);

        vec3 s=r-vec3(.4*sin(b),.4*sin(b*13.),1.5*a);
        
        a=.08;
        b=mod(b,2.);
        if(b<.5){
            b=length(s)-a;
        }else{
            b=box(R(s,b),vec3(a),.01);
        };

        if(b<d){
            q.xyz=s;
            q.w=1.;
            d=b;
        }
        
        r.z+=.5;
    };
    return d;
}

vec3 hsv2rgb(in vec3 hsv) {

    return hsv.z *(1.0 + hsv.y * clamp(abs(fract(hsv.x + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));

}

//frag:color,coord
void main(void) {
    vec4 a = glFragColor;
    vec2 b = gl_FragCoord.xy;

    //S,l,j
    float S=sin(time),l,j;

    //c,d,n,g,z,p
    vec3 c,d,n,
    
    g=normalize(
        vec3(
            .2*cos(time),
            .2*S,
            cos(time*.3)
        )
    ),
    
    z=normalize(
        cross(
            R(
                vec3(.0,1.,.0),
                3.14*S*sin(time*.2)
            ),
            g
        )
    ),
    
    p=vec3(.0,.0,time*6.);

    //#
    g=mat3(z,cross(g,z),g)*normalize(vec3((2.*b.xy-resolution.xy)/resolution.y,2.));

    vec4 q;

    l=.0;
    for(int i=0;i<50;++i){
        j=getDistance(p,q);
        if(j<.01||(l+=j)>50.){break;};
        p+=j*g;
    };

    if(l>50.){
        c=vec3(.0);
    }else{

        b=vec2(.01,.0);

        n=normalize(vec3(
            getDistance(p+(d=b.xyy),q)-getDistance(p-d,q),
            getDistance(p+(d=b.yxy),q)-getDistance(p-d,q),        
            getDistance(p+(d=b.yyx),q)-getDistance(p-d,q)
        ));

        d=normalize(vec3(.5,.0,-2.));

        c=pow(
            (
                max(.2,dot(n,d))*
                hsv2rgb(
                    vec3(
                        p.z*.1,
                        .8+.2*sin(q.y*10.)*sin(q.z*10.),
                        .6
                    )
                )+
                pow(max(.0,dot(reflect(g,n),d)),4.)*.2
            )*
            pow(1.-l/50.,3.)*
            max(1.,sin(p.z*.1)),
            vec3(.5)
        );
    };

    a=vec4(c,1.);

    glFragColor = a;
}
