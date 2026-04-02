#version 420

// original https://www.shadertoy.com/view/XtyXW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float MakeCircle(vec2 uv, vec2 pos, float rad, float edgeblur)
 {
     float dist = length(uv-pos); // lenght from center
     
     // using smoothstep to make circles and nice edges
     float c = smoothstep(rad,rad-edgeblur, dist); 
     
     return c;
 }

float mickey (vec2 uv, vec2 pos)
 {
     float mask = MakeCircle(uv, vec2(pos.x, pos.y), .15, 0.01);   // Face
     mask += MakeCircle(uv, vec2(.12 + pos.x, .15 + pos.y), .075, .01);  // Ears
     mask += MakeCircle(uv, vec2(-.12 + pos.x,.15 + pos.y), .075, .01);  // Ears
     
     float mouth = .0;
     mouth += MakeCircle(uv, vec2(pos.x, pos.y), .1, .01);
     mouth -= MakeCircle(uv, vec2(pos.x, 0.03 + pos.y), .1, .01);
     mouth -= MakeCircle(uv, vec2(-.095 + pos.x, -.005 + pos.y), .04, .01);
     mouth -= MakeCircle(uv, vec2(.095 + pos.x, -.005 + pos.y), .04, .01);
     mask -= mouth;
     
     float eyes = .0;
     eyes += MakeCircle(uv, vec2(-.08 + pos.x, .05 + pos.y), .04, .01);
     eyes += MakeCircle(uv, vec2(.08 + pos.x, .05 + pos.y), .04, .01);
     mask -= eyes;
     
     return mask;
 }

float mickeyGrid(vec2 uv, vec2 pos)
 {
     // I think this could be done with a XOR loop...
     float mask =0.0;
     mask += mickey(uv, vec2(pos.x, pos.y));
     mask += mickey(uv, vec2(pos.x, 0.5 + pos.y));
     mask += mickey(uv, vec2(pos.x, 1.0 + pos.y));
     mask += mickey(uv, vec2(pos.x, -0.5 + pos.y));
     mask += mickey(uv, vec2(pos.x, -1.0 + pos.y));
     mask += mickey(uv, vec2(pos.x + 0.5, pos.y));
     mask += mickey(uv, vec2(pos.x + 1.0, pos.y));
     mask += mickey(uv, vec2(pos.x + -0.5, pos.y));
     mask += mickey(uv, vec2(pos.x + -1.0, pos.y));
     mask += mickey(uv, vec2(pos.x + 0.5, pos.y + 0.5));
     mask += mickey(uv, vec2(pos.x + 1.0, pos.y + 0.5));
     mask += mickey(uv, vec2(pos.x + 0.5, pos.y + 1.0));
     mask += mickey(uv, vec2(pos.x + 1.0, pos.y + 1.0));
     mask += mickey(uv, vec2(pos.x + 0.5, pos.y + -0.5));
     mask += mickey(uv, vec2(pos.x + 0.5, pos.y + -1.0));
     mask += mickey(uv, vec2(pos.x + -0.5, pos.y + 0.5));
     mask += mickey(uv, vec2(pos.x + -1.0, pos.y + 0.5));
     mask += mickey(uv, vec2(pos.x + -1.0, pos.y + -0.5));
     mask += mickey(uv, vec2(pos.x + -0.5, pos.y + -1.0));
     mask += mickey(uv, vec2(pos.x + -0.5, pos.y + -0.5));
     mask += mickey(uv, vec2(pos.x + -1.0, pos.y + -1.0));
     
     return mask;
 }

float funkyColorCircles(vec2 uv, float rings, float ringThickness, float speed)
 {
     vec2 r = uv * rings; // ++ == more rings
     
     float v1 = sin(r.x + time) * 2.0;   // Color fade Grid x
     float v2 = cos(r.y + time);    // Color fade Grid y
     float v3 = sin(r.x + r.y + time);  // Color fade Grid xy mod
     
     // makes reducing circles (over time)
     float v4 = tan(sqrt(r.x * r.x + r.y * r.y) + time * speed) * ringThickness; 
     
     return v1 + v2 + v3 + v4; 
 }

void main(void)
 {
  vec2 uv = gl_FragCoord.xy / resolution.xy; // Screen Coords
     
     uv -= 0.5; // Pos Middle of screen
     uv.x *= resolution.x/resolution.y; // fix X Stretch

    float rot = radians(time * 35.0); // Rotation Speed (using time)
     float move = sin(time) * 0.4; // Simple move back and forth on sin wave (using time)
     
     uv = mat2(cos(rot), -sin(rot), sin(rot), cos(rot)) * uv; // uv rotation

    // Background Color fade mix on sin wave (using time)
     vec3 color = mix(vec3(1., 1., 1.), vec3(0., 1., 1.), uv.y ) * sin(time);

    color += funkyColorCircles(uv, 12.0,  0.25, 4.0) * move; // Added move just because...
     
     color +=  vec3(1., 1., 1.) * mickeyGrid(uv, vec2(move,move)); // Add Mickey Color Mask
     
     glFragColor = vec4(color, 1.0); // output to screen
 }
