#version 420

// original https://www.shadertoy.com/view/WdcBzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(in vec2 _st, in float _radius){
    vec2 dist = _st-vec2(0.5);
    return smoothstep(_radius-(_radius*0.01),
                      _radius+(_radius*0.01),
                      dot(dist,dist)*1.0);
}

vec2 computeOffset(vec2 _st, float scale) {
    float rate = time;
    float dir = step(1., mod(time, 2.));
    float xt = dir * rate;
    float odd = step(1., mod(_st.y,2.0));
    float xoffset = floor(odd) * scale * xt;
    xoffset += floor(1. - odd) * -1. * scale * xt;
    
    float yt = (1. - dir) * rate;
    float yodd = step(1., mod(_st.x,2.0));
    float yoffset = floor(yodd) * scale * yt;
    yoffset += floor(1. - yodd) *  -1. * scale * yt;
    
    return _st + vec2(xoffset, yoffset);
}

vec2 brickTile(vec2 _st, float _zoom){
    _st *= _zoom;
    _st = computeOffset(_st, 1.);
    return fract(_st);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 st = gl_FragCoord.xy/resolution.x;
    vec3 color = vec3(0.0);

    // Apply the brick tiling
    st = brickTile(st,20.);

    vec3 bg = mix(vec3(1.000,0.845,0.883), vec3(0.5,0.645,0.883), abs(sin(time)));
    float circ1 = circle(st,0.200);
    color = mix(vec3(0.733,0.737,0.885), bg, circ1);
    for(int i = 0; i < 6; i++) {
      float arc = 1. / 6. * float(i);
      float odd = -1. * step(0.5, floor(mod(float(i), 2.)));
      float r = 2. * 3.14 * arc;
      vec2 st2 = 0.260 * vec2(cos(time + r), sin(time + r));
      st2 = st2 + st;     
      float circ2 = circle(st2,0.020);
      vec3 circol = mix(vec3(0.8, 0.5, 0.4), vec3(0.51,0.395,0.721), abs(odd * sin(time)));
      color = mix(circol, color, circ2);
    }
    
    float circ3 = circle(st, 0.030);
    color = mix(vec3(0.985,0.761,0.354), color, circ3);

    // Output to screen
    glFragColor = vec4(color,1.0);
}
