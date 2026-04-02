#version 420

// original https://www.shadertoy.com/view/4t3yDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float angle) {
    return mat2(cos(angle), -sin(angle),
                sin(angle), cos(angle)
    );
}

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                    vec2(12.9898, 78.233)))*
                         43758.5453123);
}

float random1 (float f) {
    return random(vec2(f, -0.128));
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk:
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

float noise(float s) {    
    float i = floor(s);
    float f = fract(s);
    float n = mix(random(vec2(i, 0.)), 
                  random(vec2(i+1., 0.)), 
                  smoothstep(0.0, 1., f)); 
   
    return n;
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {

  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);

} 

vec2 map(vec2 value, vec2 inMin, vec2 inMax, vec2 outMin, vec2 outMax) {

  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);

}

vec3 map(vec3 value, vec3 inMin, vec3 inMax, vec3 outMin, vec3 outMax) {

  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);

}

vec4 map(vec4 value, vec4 inMin, vec4 inMax, vec4 outMin, vec4 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

void main(void) {
    vec3 color;

    for(float i=0.; i<2.; i++) {
        vec2 st = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
        st = rotate(i * 1.128) * st;
        

        st *=6.440 * i/0.376;
        st += vec2(-0.170,-0.240);

        // Tile
        vec2 i_st = floor(st);
        vec2 f_st = fract(st);

        float m_dist = 1.; // min distance

        for(int j=-2; j<=2; j++) {
            for(int i=-2; i<=2; i++) {

                // Neighbor place in the grid
                vec2 neighbor = vec2(float(i), float(j));

                // Random position from current + neighbor place in the grid
                vec2 offset = random2(i_st + neighbor);

                // Animate the offset
                offset = 0.5 + 0.5 * sin(time + 6.2831 * offset );

                // Position of the cell
                vec2 pos = neighbor + offset - f_st;

                // Cell distance
                float dist = length(pos);

                // Metaball
                m_dist = smin(m_dist, dist, 1.344);            
            }
        }

        float f = m_dist;
        f *= 5.;
        float steps = 5.0;
        f = ceil(f *steps) / steps;

        float h = map(f, 0., 0.7, 0.628, 0.764);
        h += (st.x + 0.376)/10. * (st.y/10. - 1.280) * 1.264;

        float s = map(f, 0., 1., 0.852, 0.752);
        float v = map(f, 0., 0.696, 0.280, 0.824);

        color += hsv2rgb(vec3(h, s, v));
        //color *=     fwidth(f) * 3.640;

        //color *= 2.896;

        vec2 uv= st;
        f = 0.;
        uv.x *= noise(time - 20.);
        uv.y *= noise(time);
        f = 1.0 - length(uv);

        vec2 uv2 = st;
        uv2 += 0.308;
        float q = map(1.0 - length(uv2), -0.496, 1., -0.552, 1.072);
        q += 3.744;

      //  color *= abs(vec3(f)) * 0.356 ;
        color *= q * .2;
    }
    
    glFragColor = vec4(color, 1.0);
    
}
