#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const float ZOOM = 5.0;
const float POINT_RADIUS = 0.4;
const float EDGE_SHARPNESS = 250.0;
const float SPIN = 5.0;
const float PI = 3.1415;

void main( void ) {
    // apect-correct x:[-0.5,0.5],y:[-0.5,0.5]
  vec2 uv = (gl_FragCoord.xy / resolution.xy) - vec2(0.5,0.5);
    float aspect = max(resolution.x,resolution.y)/min(resolution.x,resolution.y);
    if (resolution.x > resolution.y) {
        uv.x *= aspect;
    } else {
        uv.y *= aspect;
    }
    uv *= ZOOM+sin(PI*time)*0.5;
    uv = fract(uv+vec2(0.5,0.5)) - vec2(0.5,0.5);
    // heart
    uv.y -= 0.5*abs(uv.x);
    uv.y *= 1.2;
    uv.y += 0.1;
    // shade the heart
    float dist = EDGE_SHARPNESS*(length(uv)-POINT_RADIUS);
    float c = 1.0-clamp(dist, 0.0, 1.0);
    // animate the heart
    c *= abs(sin(dist/6.0 - 5.0*time + SPIN*atan(uv.y,uv.x)))*2.0 - 0.5;
    // render it
  glFragColor = vec4(c/2.0,0.0,0.0,1.0);
}
