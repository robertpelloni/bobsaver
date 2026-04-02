#version 420

// original https://www.shadertoy.com/view/flGyRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec4 o = vec4(0.,0.,0.,1.);
    vec3 c, d = vec3(1.,0.,0.), r = vec3(resolution.xy,1.0);
    vec2 q, v = (gl_FragCoord.xy-0.5*r.xy)/r.y;
    float e, a, p, n, i, T=time*8.;
    for(i=floor(T)+16.;--i>floor(T) ;){
        p = i-T;
        q = (v+vec2(cos(T/20.)*p,sin(T/20.)*p)/70.)*p;
        n = length(q);
        for(int j=0;j++<3;){
            q = log(abs(mat2(cos(i),sin(i),-sin(i),cos(i))*q));
            q += tan(q.yx)/99.;}
        a = (2.*(pow(0.5+0.5*sin(q),vec2(3.,3.))*smoothstep(0.5,0.9,n))).x*(0.4-(p/40.));
        c = vec3(0.5+0.5*cos(i),0.4+0.4*sin(i),0.2+0.2*sin(i));
        e = mix(e,1.,a);
        d = mix(d,c,a);}
    o += vec4(e*d,1.);
	glFragColor = o;
}
