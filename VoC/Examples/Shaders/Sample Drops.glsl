#version 420

// original https://www.shadertoy.com/view/4tcyDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on Metaballs by @patriciogv

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;
    
    vec2 st = uv;
    vec3 color = vec3(.0);

    // Scale
    st *= 15.;

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float m_dist = 1.;  // minimun distance
    for (int j= -1; j <= 1; j++ ) {
        for (int i= -1; i <= 1; i++ ) {
            // Neighbor place in the grid
            vec2 neighbor = vec2(float(i),float(j));

            // Random position from current + neighbor place in the grid
            vec2 offset = random2(i_st + neighbor);

            // Animate the offset
            offset = 0.5 + 0.5*sin(time + 6.2831*offset);

            // Position of the cell
            vec2 pos = neighbor + offset - f_st;

            // Cell distance
            float dist = length(pos);

            //m_dist = min(m_dist, dist);

            // Metaball it!
            m_dist = min(m_dist, m_dist*dist);
        }
    }

    // Draw cells
    color = vec3(smoothstep(0.160, 0.132, m_dist));
    //color = vec3(m_dist);

    glFragColor = vec4(color,1.0);
}
