#version 420

// original https://www.shadertoy.com/view/WdjcWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926535897932384626433832795

// Parameters
float winding = 4.0;
float numSpirals = 3.0;

float u_f = 2.5; // scaling

float speed = 3.0;

// convert from cartisian to polar.
// returns [r, theta] in x+iy = r e^i * theta
vec2 polarz(in vec2 c) {
  return vec2(length(c), atan(c.y, c.x));
}

// convert from polar to cartisian.
vec2 cart(in vec2 c) {
  return vec2(c.x * cos(c.y), c.x * sin(c.y));
}

vec2 powz(in vec2 c1, in vec2 c2) {
  vec2 polarC = polarz(c1);

  // (r * e ^ i theta) ^ (x + i y) = r ^ x * r ^ i y * e ^ i x theta * e ^ - y theta
  // r ^ x * e ^ - y theta * e ^ i (x theta + log (r) y)
  // |--------- r -------| * e ^ i |------- theta -----|

  float r = pow(polarC.x, c2.x) * exp(-polarC.y * c2.y);
  float theta = c2.x * polarC.y + log(polarC.x) * c2.y;

  return cart(vec2(r, theta));
}

vec3 grid2(in vec2 uv) {

  return (vec3(
               0.2 * (uv.y * 2.0 - 1.0) + 0.5,
               0.2 * (uv.x * 2.0 - 1.0) + 0.3,
               0.2 * length(uv - 0.5) + 0.2));
}

vec2 conformal(in vec2 uv, float winding, float numSpirals) {
  float P = log(u_f) / M_PI / 2.0;
  vec2 alpha = vec2(winding / 4.0, numSpirals * P);
  return powz(uv, alpha);
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 c = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.x;
    vec2 e = conformal(c, winding, numSpirals);
    
    float t = time / speed;
    e /= exp(log(u_f) * fract(t / log(u_f)));
    while (abs(e.x) > 1.0 || abs(e.y) > 1.0) {
      e /= u_f;
    }
    while (abs(e.x) < 1.0 / u_f && abs(e.y) < 1.0 / u_f) {
      e *= u_f;
    }
    
    glFragColor = vec4(grid2(e + 1.0 / 2.0), 1.0);
}
