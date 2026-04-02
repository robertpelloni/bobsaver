#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdf(vec3 p) {
    p = fract(p+.5)-.5;
    return length(p)-.2;
}

vec3 normal(vec3 p) {
    vec2 d = vec2(0.0001,0.);
    return normalize(vec3(
        sdf(p+d.xyy)-sdf(p),
        sdf(p+d.yxy)-sdf(p),
        sdf(p+d.yyx)-sdf(p)
    ));
}

mat2 rotate(float r) {
    return mat2(cos(r),-sin(r),sin(r),cos(r));
}

void main( void ) {

    vec2 position = 2.*( gl_FragCoord.xy / resolution.xy )-vec2(1.);
    position.x *= resolution.x/resolution.y;

    float color = 0.0;
    
    vec3 cPos = vec3(0.,0.,-3.)-vec3(time);
    //cPos.xz = rotate(time)*cPos.xz;
    vec3 cDir = normalize(vec3(time)-cPos);
    vec3 cUp = vec3(0.,1.,0.);
    cUp = normalize(cUp - dot(cUp, cDir)*cDir);
    vec3 cRight = cross(cDir, cUp);
    //vec3 cUp = normalize(cross(cRight, cDir));
    float sDepth = 1.;
    vec3 rDir = normalize(cRight*position.x+cUp*position.y+cDir*sDepth);
    float d, rLen = 1.;

    for(int i=0;i<64;i++){
        d = sdf(cPos+rDir*rLen);
        rLen += d;
    }
    
    vec3 normal = normal(cPos+rDir*rLen);
    vec3 ld = vec3(1.,1.,1.);
    
    if(sdf(cPos+rDir*rLen)<0.001)color = 1.*pow(.5*dot(ld,normal)+.5,2.);
    
    //if(length(position.xy)<1.) color = 1.;
    glFragColor = vec4(vec3(color), 1.0 );

}
