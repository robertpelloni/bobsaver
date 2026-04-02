#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}
void main() {
    
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st.x *= resolution.x/resolution.y;
    vec2 pz = gl_FragCoord.xy/resolution.xy;
    
    vec3 color = vec3(.0);
    st *= 5.;
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    float m_dist = 1.;
    vec2 m_point;
    
    for(int y=-1; y <= 1; y++){
        for(int x=-1; x <= 1; x++){
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(i_st + neighbor);
            
            point = 0.5 + 0.5*sin(time + 6.2831*point);
            vec2 diff = neighbor + point - f_st;
            float dist = length(diff)*1.9;
            if(dist < m_dist){
                m_dist = dist;
                m_point = point;
            }
        }
    }
     color += vec3(pz.x-mouse.x,pz.y-mouse.y,color.z)*.5;
     color += dot(m_point, vec2(.3,.6));
    color += 1.-step(0.02, m_dist);
    glFragColor = vec4(color, 1.0);
}
