#version 420

// original https://www.shadertoy.com/view/3slcDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// sphere radius 2.0, camera distance 4.0
// camera distance from screen 2.0

void main(void)
{
    vec2 pixel = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y*2.0;
    float time = time + 26.0;
    float squareSum = dot(pixel, pixel);
    float d = (8. - sqrt(16. - squareSum*20.)) / (squareSum + 4.);
    float isSphere = step(0.0, d);
    vec3 worldPosition = vec3(d * pixel.xy, d*2. - 4.);
    
    float sum = 0.;
      for(float i = 0.; i < 22.; i++){
        float angle1 = 2. * cos(i + 0.2 + time*0.11) + 3. * sin(i * 5.7 + 5.);
        float angle2 = sin(i*3.5 + 3. + time*0.4) + 2. * sin(i * 1.4 + 1.);
        vec3 direction = vec3(cos(angle1)*sin(angle2), cos(angle2), sin(angle1)+cos(angle2*1.5));
        vec3 distance = normalize(worldPosition) - normalize(direction);
        sum += 1.0 / dot(distance, distance);
      }    
    
    float outer = smoothstep(7.5, 6.0, abs(sum - 39.0));
    float inner = smoothstep(16.0, 10.0, abs(sum - 105.));
    float strong = outer + inner;
    float fadeout = 1.-smoothstep(-0.5, -1.6, worldPosition.z);  
    float smoothing = smoothstep(-0.75, -1.0, worldPosition.z);
    float color = min(isSphere, (fadeout+max(strong, 0.13))*smoothing);    
    glFragColor = vec4(1.,1.-color*0.5,1.-color, 1.0);
}
