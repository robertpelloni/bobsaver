#version 420

// original https://www.shadertoy.com/view/llj3DR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by vahokif

vec3 FOG_COLOR = vec3(54.0 / 255.0, 159.0 / 255.0, 245.0 / 255.0);

bool map(vec3 pos) {    
    vec2 pos2 = pos.xy;
    
    //pos2.x += pos.z * 20.0;
    float twist = pos.z * tan(time * 0.2) * 0.01 + time * 0.05;
    float s = sin(twist);
    float c = cos(twist);
    
    pos2 = vec2(c * pos2.x + s * pos2.y, c * pos2.y - s * pos2.x);
    
    return length(fract(pos2 * 2.0) - 0.5) < 0.17;
}

void main(void) {

    vec2 position = gl_FragCoord.xy / resolution.xy - 0.5;
    position.x *= resolution.x / resolution.y;
    
    vec3 rayDir = normalize(vec3(position.xy, 4.0));

    bool isHit = false;
    vec3 hit=vec3(0.0);
    vec3 ray = vec3(0.0);
    for (int i = 0; i < 64; i++) {
      ray += rayDir * 2.0;
      if (map(ray)) {
          isHit = true;
          hit = ray;
          break;
      }
    }

    vec3 color;
    if (isHit) {        
        color = FOG_COLOR * hit.z / 128.0;
    } else {
        color = FOG_COLOR;
    }
    glFragColor = vec4(color, 1.0 );

}
