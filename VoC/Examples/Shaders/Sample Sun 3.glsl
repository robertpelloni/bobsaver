#version 420

// original https://neort.io/art/bp9903c3p9fcqlgn9j3g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

float h12(vec2 p){
    return fract(sin(dot(vec2(23.5423,75.35452),p))*62534.6432);
}

float n12(vec2 p){
    vec2 f = fract(p);
    vec2 i = floor(p);
    f *= f*(3.-2.*f);
    return mix(
        mix(h12(i),h12(i+vec2(1.,0.)),f.x),
        mix(h12(i+vec2(0.,1.)),h12(i+vec2(1.,1.)),f.x),
        f.y
    );
}

float h13(vec3 p){
    return fract(sin(dot(vec3(23.5423,75.3545,54.5236),p))*62534.6432);
}

float n13(vec3 p){
    vec3 f = fract(p);
    vec3 i = floor(p);
    f *= f*(3.-2.*f);
    return mix(
        mix(
            mix(h13(i+vec3(0.,0.,0.)),h13(i+vec3(1.,0.,0.)),f.x),
            mix(h13(i+vec3(0.,1.,0.)),h13(i+vec3(1.,1.,0.)),f.x),
            f.y
        ),        
        mix(
            mix(h13(i+vec3(0.,0.,1.)),h13(i+vec3(1.,0.,1.)),f.x),
            mix(h13(i+vec3(0.,1.,1.)),h13(i+vec3(1.,1.,1.)),f.x),
            f.y
        ),
        f.z
    );
}

mat2 rot(float a){
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float f13(vec3 p){
    float n = 0.;
    float a = 1.;
    float kt = time*.04;
    for(int i=0;i<9;i++){
        p += vec3(0.543,0.6543,0.562)*kt;
        n += .5*n13(p*a)/a;
        a*=2.;
        p.xy*=rot(2.541+kt);
        p.xz*=rot(4.642+kt);
    }
    return n;
}

float map(vec3 p){
    return length(p)>1.5?length(p) - 1.2:length(p) - 1.-.2*f13(10.*normalize(p));
}

vec3 normal(vec3 p){
    vec2 d = vec2(0.,.001);
    return normalize(
        vec3(
            map(p+d.yxx) - map(p-d.yxx),
            map(p+d.xyx) - map(p-d.xyx),
            map(p+d.xxy) - map(p-d.xxy)
        )
    );
}

void main(void){
    vec2 p = (2.*gl_FragCoord.xy - resolution.xy)/min(resolution.x,resolution.y);
    vec3 color = vec3(0.);
    
    color += mix(vec3(1.,0.4,0.),vec3(1.,1.,0.),n12(100.*normalize(p)+vec2(time)))*smoothstep(1.,0.,1.2*length(p)-1.);
    
    float kt = time*.1;
    vec3 ro = vec3(2.*cos(kt),0.,2.*sin(kt));
    vec3 ta = vec3(0.,0.,0.);
    
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww,vec3(0.,1.,0.)));
    vec3 vv = normalize(cross(uu,ww));
    float sd = 1.;
    
    vec3 rd = normalize(p.x*uu+p.y*vv+sd*ww);
    vec3 rp = ro;
    float d;
    
    for(int i=0;i<64;i++){
        d = map(rp);
        rp += d*rd*.6;
        if(d<.001)break;
    }
    
    vec3 ld = normalize(vec3(0.,1.,0.));
    
    if(map(rp)<.01)color = mix(vec3(1.,0.,0.),vec3(1.,1.,0.),5.*(length(rp)-1.));//*pow(.5*dot(normal(rp),ld)+.5,2.);
    
    glFragColor = vec4(color,1.);
}
