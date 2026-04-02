#version 420

// original https://www.shadertoy.com/view/ctVXzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by canagrisa https://www.youtube.com/watch?v=3jJ51bj1jTM
// A steel ball gets released on a pixel.
// There a 6 (variable : num) magnets (located at the black dots).
// The pixel gets the colour of the magnet it is closest to after num_steps.
// Over time I let the atraction constant k vary.
// Feel free to experiment with the variables and create your own fractals

int num = 6; // number of magnets
int num_steps  = 1000; // number of timesteps before ending
float k = -1.0;  // force = k/distance ^ power. k Varies over time
float speed = 0.04; // the speed at which k changes
float power = 0.8;
float dt = 0.005;  // timestep
float min_dist = .02;  // closest distance to magnet, to avoid iregularities
float friction = 0.008; // dampening of ball
float radius =  0.15;  // radius of the circle that the magnets are on
float twopi =  6.28318530718;

////////////////////////////////////////////////////////

float magnet_y(int i){
    float alfa = float(i) * twopi / float(num);
    return radius * cos(alfa);
}

/////////////////////////////////////////////////////////

float magnet_x(int i){
      float alfa = float(i) * twopi / float(num);
    return radius * sin(alfa);
}

/////////////////////////////////////////////////////////

vec3 colour(int i){
  return vec3(abs(cos(float(i)*1.234)), abs(cos(float(i)*5.324)), abs(sin(float(i)*7.423)));
}

/////////////////////////////////////////////////////////

int select_final_magnet(vec2 uv) {
  float vx = 0.;
  float vy = 0.;
  for (int i = 0; i < num_steps; i++) {
    float fx = 0.;
    float fy = 0.;
    float dist;
    float force;
    for (int j = 0; j < num; j++) {
      dist = max(length(uv - vec2(magnet_x(j), magnet_y(j))), min_dist); // max(length(uv - vec2(magnet_x(j), magnet_y(j)), min_dist));
      force = k / pow(dist, power);
      fx += force * (uv.x - magnet_x(j)) / dist;
      fy += force * (uv.y - magnet_y(j)) / dist;
    }
    vx += fx * dt;
    vy += fy * dt;
    uv.x += vx * dt;
    uv.y += vy * dt;
    vx -= friction * vx;
    vy -= friction * vy;
  }
  float closest = 1000000.; // just a big number
  int col_code = 0;
  for (int i = 0; i < num; i++) {
    float afstand = length(uv - vec2( magnet_x(i), magnet_y(i)) );
    if (afstand < closest) {
      closest = afstand;
      col_code = i;
    }
  }
  return col_code;
}

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

void main(void)
{
  k = -abs(sin(time * speed));
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;

    vec3 col = colour(select_final_magnet(uv));
    
    for (int i = 0; i < num; i++){
      float len = length(uv-vec2(magnet_x(i), magnet_y(i)));
      if (len < .003) col = vec3(0); //colour(i);    
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
