#version 420

// original https://www.shadertoy.com/view/3s2yRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)

float N21 (vec2 p){
    float d = fract(sin(p.x*110.+(8.21-p.y)*331.)*1218.);
    return d;
}

float Noise2D(vec2 uv){
    vec2 st = fract(uv);
    vec2 id = floor(uv);
    st = st*st*(3.0-2.0*st);
    float c=mix(mix(N21(id),N21(id+vec2(1.0,0.0)),st.x),mix(N21(id+vec2(0.0,1.0)),N21(id+vec2(1.0,1.0)),st.x),st.y);
    return c;
}

float fbm (vec2 uv){
    
    float c=0.;
    c+=Noise2D(uv)/2.;
    c+=Noise2D(2.*uv)/4.;
    c+=Noise2D(4.*uv)/8.;
    c+=Noise2D(8.*uv)/16.;
    return c/(1.-1./16.);
}

vec3 fbm3(vec2 uv){
    vec3 color;
    float f1 = fbm(uv);
    color= mix(vec3(0.1,0.0,0.0),vec3(0.9,0.1,0.1),2.5*f1);
    
    float f2 = fbm(2.4*f1+uv+0.15*sin(time)*vec2(7.0,-8.0));
    color= mix(color,vec3(0.6,0.5,0.1),1.5*f2);
    float f3 = fbm(3.5*f2+uv-0.15*cos(1.5*time)*vec2(4.0,3.0));
    color= mix(color,vec3(0.1,0.35,0.45),f3);
    
    color= mix(color,vec3(0.45,0.35,0.25),S(0.7,0.75,f2));
    color= mix(color,vec3(0.2,0.4,0.2),S(0.75,0.8,f2));
    color= mix(color,vec3(0.55,0.55,0.35),S(0.88,0.99,f2));
    color= mix(color,vec3(0.55,0.55,0.35),S(0.88,0.99,f3));
    
    return color;

}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    vec3 c = fbm3(vec2(5.0,5.0)*uv+sin(0.3*time)*0.5);
    vec3 col = c;

    col.r *= .725;
    col.g *= .725;
    glFragColor = vec4(col * 2.5,1.0);
}
