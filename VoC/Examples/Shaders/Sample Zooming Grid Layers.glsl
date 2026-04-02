#version 420

// original https://www.shadertoy.com/view/4sSyDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define gridsize 0.5

#define draw(dc) c = mix(dc,c,clamp(d/pixelSize, 0., 1.))

//2d box signed distance
float sdBox(vec2 p, vec2 b)
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

void main(void)
{
    float pixelSize = length(1.0/resolution.xy);
    vec2 uv = (gl_FragCoord.xy*2. - resolution.xy)/resolution.x;
    
    //infinite zoom, repeating offset and scaling
    float zoomRepeat = fract(time)*(1.0+1e-4),
        scale = zoomRepeat;
    uv += zoomRepeat*0.5;
    uv *= 1.0-scale*0.5;
    
    
    vec3 c = vec3(1.);//start with white background
    
    //layers of grids, first smallest is fading in
    for (int i = 1; i < 3; i++) {
        float sz = gridsize/pow(2.,float(3-i)),
              sz2 = sz/2.0;
          float d = abs(sdBox(mod(abs(uv),sz)-sz2, vec2(sz2)))-0.004*(1.0-scale*0.75);
        
        vec3 rc = vec3(0.);
        if (i == 1) rc = vec3(1.-zoomRepeat);
        draw(rc);
    }
    
    //output color
    glFragColor = vec4(c, 1.);
}
