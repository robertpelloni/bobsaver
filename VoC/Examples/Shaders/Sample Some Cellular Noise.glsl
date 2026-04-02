#version 420

// original https://www.shadertoy.com/view/wtdBWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return fract(abs(sin(st)*43758.5453123));
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.y;
    st.y -= time*0.1;
    
    const float scale = 10.;
    st *= scale;

    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    
    vec2 m_dist = vec2(100.0);

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x),float(y));
            vec2 point = random2(i_st + neighbor);
            point = 0.5+0.5*sin(time + 6.2831*point);
            vec2 diff = neighbor + point - f_st; 
            float dist = length(diff);
            
            if ( dist < m_dist.x || dist < m_dist.y) {
                if (m_dist.x > m_dist.y) m_dist.x = dist;
                else m_dist.y = dist;
            }
        }
    }
    
    float min_dist = min(m_dist.x, m_dist.y);
    float max_dist = max(m_dist.x, m_dist.y);
    
    float col1 = float(max_dist-min_dist);
    float col2 = float(min_dist*max_dist);
    float col3 = float(cos(max_dist)-sin(min_dist));
    float col4 = float(17.-st.x-min_dist*15.0);
    float col5 = float(st.x-(min_dist/max_dist)*15.0);
    float col6 = float((0.5+0.5*sin((cos(max_dist)-sin(min_dist))*20.0)));
    
    float m1 = mix(col1, col2, .5+.2*sin(time*0.7));
    float m2 = mix(col3, col4, .5+.2*sin(time*1.3));
    float m3 = mix(col5, col6, .5+.2*sin(time*1.9));
    float m4 = mix(col4, m2, m3);
     
    vec3 col7 = vec3(m4,m3,m2);
    vec3 col8 = vec3(m2,m4,m1);
    vec3 col9 = vec3(m1,m2,m3);
    
    vec3 col10 = mix(col7, col8, col7);
    vec3 col = col10;
    glFragColor = vec4(col,1.0);
}
